package com.ai_univers.smart_point_of_sale.security

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * MethodChannel bridge between Flutter and [DeviceKeyManager].
 *
 * Keystore operations can take several hundred milliseconds (key generation),
 * so they run on a background thread and reply on the main thread.
 */
class DeviceSecurityPlugin(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Logcat traces only for debuggable builds (flutter run / debug APK). */
    private val debugLogs = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    private fun log(message: String) {
        if (debugLogs) Log.d(TAG, message)
    }

    fun register() = channel.setMethodCallHandler(this)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        executor.execute {
            val start = SystemClock.elapsedRealtime()
            val alias = call.argument<String>("alias") ?: DeviceKeyManager.DEFAULT_ALIAS
            try {
                val value = handle(call)
                log("${call.method}($alias) OK en ${SystemClock.elapsedRealtime() - start} ms${summary(call.method, value)}")
                mainHandler.post { result.success(value) }
            } catch (e: NotImplementedError) {
                log("${call.method} : méthode inconnue")
                mainHandler.post { result.notImplemented() }
            } catch (e: Exception) {
                if (debugLogs) Log.e(TAG, "${call.method}($alias) ÉCHEC en ${SystemClock.elapsedRealtime() - start} ms", e)
                mainHandler.post { result.error("DEVICE_KEY_ERROR", "${e.javaClass.simpleName}: ${e.message}", null) }
            }
        }
    }

    private fun handle(call: MethodCall): Any? {
        val alias = call.argument<String>("alias") ?: DeviceKeyManager.DEFAULT_ALIAS
        return when (call.method) {
            "hasKey" -> DeviceKeyManager.hasKey(alias)
            "generateKey" -> DeviceKeyManager.generateKey(alias, call.argument<ByteArray>("challenge")!!)
            "sign" -> DeviceKeyManager.sign(alias, call.argument<ByteArray>("data")!!)
            "verify" -> DeviceKeyManager.verify(
                alias, call.argument<ByteArray>("data")!!, call.argument<String>("signature")!!
            )
            "publicKey" -> DeviceKeyManager.publicKey(alias)
            // Unit cannot cross the MethodChannel: reply with null.
            "deleteKey" -> { DeviceKeyManager.deleteKey(alias); null }
            "describeAttestation" -> AttestationParser.describe(DeviceKeyManager.certificateChain(alias))
            "deviceInfo" -> deviceInfo()
            else -> throw NotImplementedError(call.method)
        }
    }

    /** Short, readable description of a result for Logcat. */
    private fun summary(method: String, value: Any?): String = when (method) {
        "generateKey" -> (value as Map<*, *>).let {
            " → attestée=${it["attested"]}, niveau=${it["securityLevel"]}, " +
                "certificats=${(it["certChain"] as List<*>).size}" +
                (it["attestationError"]?.let { error -> ", erreur attestation=$error" } ?: "")
        }
        "sign" -> " → signature ${(value as String).length} caractères base64"
        "hasKey", "verify" -> " → $value"
        "describeAttestation" -> (value as Map<*, *>).let {
            " → sécurité=${it["attestationSecurityLevel"]}, boot=${it["verifiedBootState"]}, " +
                "verrouillé=${it["deviceLocked"]}, packages=${it["attestedPackages"]}"
        }
        "deviceInfo" -> (value as Map<*, *>).let {
            " → ${it["manufacturer"]} ${it["model"]}, Android ${it["androidVersion"]}, " +
                "certificat APK=${it["signingCertSha256"]}"
        }
        else -> ""
    }

    private fun deviceInfo(): Map<String, Any?> = mapOf(
        "manufacturer" to Build.MANUFACTURER,
        "brand" to Build.BRAND,
        "model" to Build.MODEL,
        "androidVersion" to Build.VERSION.RELEASE,
        "sdkInt" to Build.VERSION.SDK_INT,
        "securityPatch" to Build.VERSION.SECURITY_PATCH,
        "packageName" to context.packageName,
        "signingCertSha256" to signingCertificatesSha256(),
    )

    /** SHA-256 of the certificate(s) that signed the installed APK: the value the backend expects. */
    private fun signingCertificatesSha256(): List<String> {
        val info = context.packageManager.getPackageInfo(
            context.packageName, PackageManager.GET_SIGNING_CERTIFICATES
        )
        val signingInfo = info.signingInfo ?: return emptyList()
        val signers = if (signingInfo.hasMultipleSigners()) signingInfo.apkContentsSigners
        else signingInfo.signingCertificateHistory
        return signers.map { AttestationParser.sha256Hex(it.toByteArray()) }
    }

    companion object {
        const val CHANNEL = "smartpos/device_security"
        private const val TAG = "DeviceSecurity"
    }
}
