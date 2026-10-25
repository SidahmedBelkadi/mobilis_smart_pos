package com.ai_univers.smart_point_of_sale.update

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import com.ai_univers.smart_point_of_sale.security.AttestationParser
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * In-app update: hands the APK downloaded from our server to the Android installer,
 * whatever its version. Only checks that it is our app, signed with our key:
 * Android refuses anything else, and checking first gives a clear message.
 */
class AppUpdaterPlugin(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private var pendingInstall: MethodChannel.Result? = null

    fun register() = channel.setMethodCallHandler(this)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // "Install unknown apps" must be allowed once for our app
            "canInstall" -> result.success(activity.packageManager.canRequestPackageInstalls())
            "openInstallSettings" -> {
                activity.startActivity(
                    Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}"))
                )
                result.success(null)
            }
            "keepScreenOn" -> {
                val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                if (call.argument<Boolean>("on") == true) activity.window.addFlags(flag) else activity.window.clearFlags(flag)
                result.success(null)
            }
            "install" -> install(call.argument<String>("path")!!, result)
            else -> result.notImplemented()
        }
    }

    private fun install(path: String, result: MethodChannel.Result) {
        val file = File(path)
        val problem = checkApk(file)
        if (problem != null) {
            result.error(problem, "Downloaded APK rejected: $problem", null)
            return
        }

        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", file)
        @Suppress("DEPRECATION")
        val intent = Intent(Intent.ACTION_INSTALL_PACKAGE)
            .setDataAndType(uri, APK_MIME)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            .putExtra(Intent.EXTRA_RETURN_RESULT, true)

        pendingInstall?.error("REPLACED", "Another installation was started", null)
        pendingInstall = result
        try {
            activity.startActivityForResult(intent, INSTALL_REQUEST_CODE)
        } catch (e: Exception) {
            pendingInstall = null
            result.error("INSTALL_FAILED", e.message, null)
        }
    }

    /** Called by MainActivity. On success the app is replaced and this is never reached. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != INSTALL_REQUEST_CODE) return false
        val result = pendingInstall ?: return true
        pendingInstall = null
        if (resultCode == Activity.RESULT_OK) result.success("INSTALLED") else result.success("CANCELLED")
        return true
    }

    /** Returns null when the APK can be installed, otherwise the reason. */
    private fun checkApk(file: File): String? {
        if (!file.exists() || file.length() == 0L) return "APK_MISSING"
        val pm = activity.packageManager
        val apk = pm.getPackageArchiveInfo(file.path, PackageManager.GET_SIGNING_CERTIFICATES)
            ?: return "APK_INVALID" // not an APK (truncated download, HTML error page...)
        val installed = pm.getPackageInfo(activity.packageName, PackageManager.GET_SIGNING_CERTIFICATES)

        if (apk.packageName != activity.packageName) return "APK_WRONG_APP"
        if (signers(apk).isEmpty() || signers(apk) != signers(installed)) return "APK_WRONG_SIGNATURE"
        return null
    }

    private fun signers(info: PackageInfo): Set<String> {
        val signingInfo = info.signingInfo ?: return emptySet()
        val certificates = if (signingInfo.hasMultipleSigners()) signingInfo.apkContentsSigners
        else signingInfo.signingCertificateHistory
        return certificates.map { AttestationParser.sha256Hex(it.toByteArray()) }.toSet()
    }

    companion object {
        const val CHANNEL = "smartpos/app_update"
        private const val APK_MIME = "application/vnd.android.package-archive"
        private const val INSTALL_REQUEST_CODE = 7301
    }
}
