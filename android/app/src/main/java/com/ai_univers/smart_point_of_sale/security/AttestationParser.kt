package com.ai_univers.smart_point_of_sale.security

import java.math.BigInteger
import java.security.MessageDigest
import java.security.cert.X509Certificate

/**
 * Minimal reader of the Android Key Attestation extension, for the diagnostic
 * screen only. The backend must run its own full verification (chain to the
 * Google roots, revocation list, challenge...): nothing here is trusted.
 *
 * Reference: https://source.android.com/docs/security/features/keystore/attestation
 */
object AttestationParser {
    private const val KEY_DESCRIPTION_OID = "1.3.6.1.4.1.11129.2.1.17"
    private const val TAG_ROOT_OF_TRUST = 704
    private const val TAG_OS_VERSION = 705
    private const val TAG_OS_PATCH_LEVEL = 706
    private const val TAG_ATTESTATION_APPLICATION_ID = 709

    private val SECURITY_LEVELS = mapOf(0L to "SOFTWARE", 1L to "TEE", 2L to "STRONGBOX")
    private val BOOT_STATES = mapOf(0L to "VERIFIED", 1L to "SELF_SIGNED", 2L to "UNVERIFIED", 3L to "FAILED")

    fun describe(chain: List<X509Certificate>): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>(
            "certificates" to chain.map {
                mapOf(
                    "subject" to it.subjectX500Principal.name,
                    "issuer" to it.issuerX500Principal.name,
                    "notAfter" to it.notAfter.time,
                )
            },
            "rootPublicKeySha256" to chain.lastOrNull()?.let { sha256Hex(it.publicKey.encoded) },
        )
        val extension = chain.firstOrNull()?.getExtensionValue(KEY_DESCRIPTION_OID)
        if (extension == null) {
            result["hasAttestationExtension"] = false
            return result
        }
        result["hasAttestationExtension"] = true
        try {
            result.putAll(parseKeyDescription(extension))
        } catch (e: Exception) {
            result["parseError"] = "${e.javaClass.simpleName}: ${e.message}"
        }
        return result
    }

    private fun parseKeyDescription(extension: ByteArray): Map<String, Any?> {
        // getExtensionValue() returns the extension wrapped in an OCTET STRING.
        val outer = Der(extension)
        val inner = Der(outer.bytesOf(outer.read(0)))
        val fields = inner.children(inner.read(0))

        val out = mutableMapOf<String, Any?>(
            "attestationVersion" to inner.long(fields[0]),
            "attestationSecurityLevel" to SECURITY_LEVELS[inner.long(fields[1])],
            "keymasterVersion" to inner.long(fields[2]),
            "keymasterSecurityLevel" to SECURITY_LEVELS[inner.long(fields[3])],
            "attestationChallengeBase64" to android.util.Base64.encodeToString(
                inner.bytesOf(fields[4]), android.util.Base64.NO_WRAP
            ),
        )

        val softwareEnforced = inner.taggedFields(fields[6])
        val hardwareEnforced = inner.taggedFields(fields[7])

        (hardwareEnforced[TAG_ROOT_OF_TRUST] ?: softwareEnforced[TAG_ROOT_OF_TRUST])?.let { tlv ->
            val rot = inner.children(tlv)
            out["deviceLocked"] = inner.bytesOf(rot[1]).firstOrNull()?.toInt() != 0
            out["verifiedBootState"] = BOOT_STATES[inner.long(rot[2])]
        }
        hardwareEnforced[TAG_OS_VERSION]?.let { out["osVersion"] = inner.long(it) }
        hardwareEnforced[TAG_OS_PATCH_LEVEL]?.let { out["osPatchLevel"] = inner.long(it) }

        (softwareEnforced[TAG_ATTESTATION_APPLICATION_ID] ?: hardwareEnforced[TAG_ATTESTATION_APPLICATION_ID])?.let { tlv ->
            // The application id is itself a DER document inside an OCTET STRING.
            val app = Der(inner.bytesOf(tlv))
            val appFields = app.children(app.read(0))
            out["attestedPackages"] = app.children(appFields[0]).map { pkg ->
                String(app.bytesOf(app.children(pkg)[0]), Charsets.UTF_8)
            }
            out["attestedSigningCertSha256"] = app.children(appFields[1]).map { hex(app.bytesOf(it)) }
        }
        return out
    }

    fun sha256Hex(bytes: ByteArray): String = hex(MessageDigest.getInstance("SHA-256").digest(bytes))

    private fun hex(bytes: ByteArray) = bytes.joinToString("") { "%02x".format(it) }

    /** Tiny DER reader: enough for the attestation structures, nothing more. */
    private class Der(private val bytes: ByteArray) {
        class Tlv(val tag: Int, val start: Int, val length: Int) {
            val end get() = start + length
        }

        fun read(position: Int): Tlv {
            var p = position
            val first = bytes[p++].toInt() and 0xff
            var tag = first and 0x1f
            if (tag == 0x1f) {
                // High tag number form, used by the attestation tags (704, 709...).
                tag = 0
                var b: Int
                do {
                    b = bytes[p++].toInt() and 0xff
                    tag = (tag shl 7) or (b and 0x7f)
                } while (b and 0x80 != 0)
            }
            var length = bytes[p++].toInt() and 0xff
            if (length and 0x80 != 0) {
                val count = length and 0x7f
                length = 0
                repeat(count) { length = (length shl 8) or (bytes[p++].toInt() and 0xff) }
            }
            return Tlv(tag, p, length)
        }

        fun children(parent: Tlv): List<Tlv> {
            val out = mutableListOf<Tlv>()
            var p = parent.start
            while (p < parent.end) {
                val child = read(p)
                out.add(child)
                p = child.end
            }
            return out
        }

        /** AuthorizationList: SEQUENCE of [tag] EXPLICIT values, keyed by tag. */
        fun taggedFields(list: Tlv): Map<Int, Tlv> =
            children(list).associate { it.tag to read(it.start) }

        fun bytesOf(tlv: Tlv): ByteArray = bytes.copyOfRange(tlv.start, tlv.end)

        fun long(tlv: Tlv): Long = BigInteger(bytesOf(tlv)).toLong()
    }
}
