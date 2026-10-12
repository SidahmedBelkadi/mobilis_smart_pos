package com.ai_univers.smart_point_of_sale.security

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.cert.X509Certificate
import java.security.spec.ECGenParameterSpec

/**
 * Device signing key stored in the Android Keystore.
 *
 * The private key never leaves the Keystore: Flutter only ever receives the
 * attestation certificate chain, the public key and signatures.
 */
object DeviceKeyManager {
    const val DEFAULT_ALIAS = "smartpos_device_key"
    private const val KEYSTORE = "AndroidKeyStore"
    private const val SIGNATURE_ALGORITHM = "SHA256withECDSA"

    private fun keyStore(): KeyStore = KeyStore.getInstance(KEYSTORE).apply { load(null) }

    fun hasKey(alias: String): Boolean = keyStore().containsAlias(alias)

    fun deleteKey(alias: String) {
        val ks = keyStore()
        if (ks.containsAlias(alias)) ks.deleteEntry(alias)
    }

    /**
     * Generates an EC P-256 signing key bound to [challenge].
     *
     * If the device refuses key attestation, the key is regenerated without it
     * so the app keeps working; the backend then sees `attested = false`.
     */
    fun generateKey(alias: String, challenge: ByteArray): Map<String, Any?> {
        deleteKey(alias)
        var attestationError: String? = null
        try {
            generate(alias, challenge)
        } catch (e: Exception) {
            attestationError = "${e.javaClass.simpleName}: ${e.message}"
            deleteKey(alias)
            generate(alias, null)
        }

        val chain = certificateChain(alias)
        return mapOf(
            "certChain" to chain.map { Base64.encodeToString(it.encoded, Base64.NO_WRAP) },
            // Without attestation Android returns a single self-signed certificate.
            "attested" to (attestationError == null && chain.size > 1),
            "attestationError" to attestationError,
            "securityLevel" to securityLevel(alias),
        )
    }

    private fun generate(alias: String, challenge: ByteArray?) {
        val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
        // StrongBox is intentionally not requested: signing there is too slow for every request.
        if (challenge != null) spec.setAttestationChallenge(challenge)

        KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, KEYSTORE).apply {
            initialize(spec.build())
            generateKeyPair()
        }
    }

    fun certificateChain(alias: String): List<X509Certificate> =
        keyStore().getCertificateChain(alias)?.map { it as X509Certificate } ?: emptyList()

    /** Public key (SubjectPublicKeyInfo, base64), the value the backend stores. */
    fun publicKey(alias: String): String? =
        keyStore().getCertificate(alias)?.publicKey?.encoded?.let {
            Base64.encodeToString(it, Base64.NO_WRAP)
        }

    /** ECDSA P-256 / SHA-256 signature, DER encoded, base64. */
    fun sign(alias: String, data: ByteArray): String {
        val key = keyStore().getKey(alias, null) as? PrivateKey
            ?: throw IllegalStateException("No device key for alias $alias")
        val signature = Signature.getInstance(SIGNATURE_ALGORITHM).run {
            initSign(key)
            update(data)
            sign()
        }
        return Base64.encodeToString(signature, Base64.NO_WRAP)
    }

    /** Local check with the public key, used by the diagnostic screen only. */
    fun verify(alias: String, data: ByteArray, signatureBase64: String): Boolean {
        val certificate = keyStore().getCertificate(alias) ?: return false
        return Signature.getInstance(SIGNATURE_ALGORITHM).run {
            initVerify(certificate.publicKey)
            update(data)
            verify(Base64.decode(signatureBase64, Base64.NO_WRAP))
        }
    }

    /** Where the private key actually lives: STRONGBOX, TEE, SOFTWARE or UNKNOWN. */
    @Suppress("DEPRECATION")
    fun securityLevel(alias: String): String {
        val key = keyStore().getKey(alias, null) as? PrivateKey ?: return "UNKNOWN"
        val info = KeyFactory.getInstance(key.algorithm, KEYSTORE).getKeySpec(key, KeyInfo::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return when (info.securityLevel) {
                KeyProperties.SECURITY_LEVEL_STRONGBOX -> "STRONGBOX"
                KeyProperties.SECURITY_LEVEL_TRUSTED_ENVIRONMENT -> "TEE"
                KeyProperties.SECURITY_LEVEL_SOFTWARE -> "SOFTWARE"
                else -> "UNKNOWN"
            }
        }
        return if (info.isInsideSecureHardware) "TEE" else "SOFTWARE"
    }
}
