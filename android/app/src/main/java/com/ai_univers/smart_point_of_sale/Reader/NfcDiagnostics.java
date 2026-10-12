package com.ai_univers.smart_point_of_sale.Reader;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.nfc.Tag;
import android.nfc.tech.IsoDep;
import android.nfc.tech.NfcA;
import android.nfc.tech.NfcB;
import android.os.SystemClock;
import android.util.Base64;
import android.util.Log;

import org.bouncycastle.asn1.ASN1EncodableVector;
import org.bouncycastle.asn1.ASN1Integer;
import org.bouncycastle.asn1.ASN1OctetString;
import org.bouncycastle.asn1.DERSequence;
import org.bouncycastle.asn1.x509.AuthorityKeyIdentifier;
import org.bouncycastle.asn1.x509.SubjectKeyIdentifier;
import org.bouncycastle.jce.provider.BouncyCastleProvider;
import net.sf.scuba.tlv.TLVInputStream;

import org.jmrtd.BACKey;
import org.jmrtd.PACEKeySpec;
import org.jmrtd.PassportService;
import org.jmrtd.lds.ActiveAuthenticationInfo;
import org.jmrtd.lds.CardAccessFile;
import org.jmrtd.lds.ChipAuthenticationInfo;
import org.jmrtd.lds.ChipAuthenticationPublicKeyInfo;
import org.jmrtd.lds.PACEInfo;
import org.jmrtd.lds.SODFile;
import org.jmrtd.lds.SecurityInfo;
import org.jmrtd.lds.icao.COMFile;
import org.jmrtd.lds.icao.DG14File;
import org.jmrtd.protocol.AAResult;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.Signature;
import java.security.cert.X509Certificate;
import java.security.interfaces.ECPublicKey;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

/**
 * Debug-only inspection of identity document chips (Algerian CNIBE / passport).
 * Logs which data groups and security protocols a document supports, so we can
 * decide which checks (Passive / Active / Chip Authentication, PACE) to enforce.
 *
 * Never logs personal data: only structure, algorithms, certificates of the
 * issuing state and pass/fail results. Filter with: adb logcat -s NFC_DIAG
 */
public class NfcDiagnostics {

    private static final String TAG = "NFC_DIAG";
    private static final BouncyCastleProvider BC = new BouncyCastleProvider();

    private final boolean enabled;
    private final String documentType;
    private final long startTime = SystemClock.elapsedRealtime();
    private long stepTime = startTime;

    public NfcDiagnostics(Context context, String documentType) {
        this.enabled = (context.getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0;
        this.documentType = documentType;
    }

    public boolean isEnabled() {
        return enabled;
    }

    // ---------------------------------------------------------------- tag / transport

    public void logTag(IsoDep isoDep) {
        if (!enabled) return;
        try {
            log("==================== NFC DIAGNOSTIC START (documentType=" + documentType + ") ====================");
            Tag tag = isoDep.getTag();
            log("[TAG] techs=" + Arrays.toString(tag.getTechList()));
            byte[] uid = tag.getId();
            // Length + first byte only: 0x08 = random UID (ISO 14443), expected for eMRTD chips
            log("[TAG] uidLength=" + uid.length + " uidFirstByte=" + (uid.length > 0 ? hex(new byte[]{uid[0]}) : "-"));
            log("[TAG] historicalBytes=" + hex(isoDep.getHistoricalBytes()) + " hiLayerResponse=" + hex(isoDep.getHiLayerResponse()));
            log("[TAG] extendedLengthApdu=" + isoDep.isExtendedLengthApduSupported() + " maxTransceive=" + isoDep.getMaxTransceiveLength() + " timeoutMs=" + isoDep.getTimeout());
            NfcA nfcA = NfcA.get(tag);
            if (nfcA != null) {
                log("[TAG] NfcA atqa=" + hex(nfcA.getAtqa()) + " sak=" + String.format("%02X", nfcA.getSak()));
            }
            NfcB nfcB = NfcB.get(tag);
            if (nfcB != null) {
                log("[TAG] NfcB appData=" + hex(nfcB.getApplicationData()) + " protocolInfo=" + hex(nfcB.getProtocolInfo()));
            }
        } catch (Throwable t) {
            logError("[TAG]", t);
        }
    }

    // ---------------------------------------------------------------- PACE

    /**
     * Reads EF.CardAccess (must run after open() and before sendSelectApplet())
     * and tries PACE with the MRZ key. Returns true when PACE succeeded, in which
     * case the caller must select the applet with secure messaging and skip BAC.
     */
    public boolean probeCardAccessAndPace(PassportService service, BACKey bacKey) {
        if (!enabled) return false;
        PACEInfo paceInfo = null;
        try {
            CardAccessFile cardAccess = new CardAccessFile(service.getInputStream(PassportService.EF_CARD_ACCESS));
            Collection<SecurityInfo> infos = cardAccess.getSecurityInfos();
            log("[CARD_ACCESS] present, " + infos.size() + " SecurityInfo(s)");
            for (SecurityInfo info : infos) {
                log("[CARD_ACCESS]   " + describeSecurityInfo(info));
                if (info instanceof PACEInfo && paceInfo == null) {
                    paceInfo = (PACEInfo) info;
                }
            }
        } catch (Throwable t) {
            log("[CARD_ACCESS] absent or unreadable -> PACE not supported (" + t.getClass().getSimpleName() + ": " + t.getMessage() + ")");
        }
        step("CardAccess");

        if (paceInfo == null) {
            log("[PACE] skipped (no PACEInfo), BAC will be used");
            return false;
        }
        try {
            PACEKeySpec paceKey = PACEKeySpec.createMRZKey(bacKey);
            service.doPACE(paceKey, paceInfo.getObjectIdentifier(),
                    PACEInfo.toParameterSpec(paceInfo.getParameterId()), paceInfo.getParameterId());
            log("[PACE] SUCCESS oid=" + paceInfo.getObjectIdentifier() + " paramId=" + paceInfo.getParameterId());
            step("PACE");
            return true;
        } catch (Throwable t) {
            logError("[PACE] FAILED, falling back to BAC", t);
            step("PACE failed");
            return false;
        }
    }

    public void logAccessControl(boolean paceUsed) {
        if (!enabled) return;
        log("[ACCESS] protocol=" + (paceUsed ? "PACE" : "BAC"));
        step(paceUsed ? "select applet" : "BAC");
    }

    // ---------------------------------------------------------------- after the data groups are read

    /**
     * Runs after DG1/DG11/DG12 were read. Inspects EF.COM, EF.SOD (hashes, signature,
     * Document Signer certificate), DG14, DG15, then tries Active and Chip Authentication.
     * Chip Authentication replaces the secure messaging session, so this must be the
     * last thing done before close().
     */
    public void inspectSecurity(PassportService service, Map<Integer, byte[]> readDataGroups) {
        if (!enabled) return;
        try {
            inspectCom(service);
            SODFile sod = inspectSod(service, readDataGroups);
            DG14File dg14 = readDg14(service, sod);
            PublicKey aaKey = readDg15(service, sod);
            tryActiveAuthentication(service, dg14, aaKey);
            tryChipAuthentication(service, dg14);
        } catch (Throwable t) {
            logError("[DIAG] unexpected error", t);
        } finally {
            log("[TIMING] total=" + (SystemClock.elapsedRealtime() - startTime) + "ms");
            log("==================== NFC DIAGNOSTIC END ====================");
        }
    }

    private void inspectCom(PassportService service) {
        try {
            COMFile com = new COMFile(service.getInputStream(PassportService.EF_COM));
            StringBuilder tags = new StringBuilder();
            for (int tag : com.getTagList()) {
                tags.append(String.format("%02X ", tag));
            }
            log("[EF.COM] ldsVersion=" + com.getLDSVersion() + " unicodeVersion=" + com.getUnicodeVersion()
                    + " tags=" + tags.toString().trim() + "  (61=DG1 75=DG2 63=DG3 67=DG7 6B=DG11 6C=DG12 6E=DG14 6F=DG15)");
        } catch (Throwable t) {
            log("[EF.COM] absent or unreadable (" + t.getClass().getSimpleName() + ": " + t.getMessage() + ")");
        }
        step("EF.COM");
    }

    private SODFile inspectSod(PassportService service, Map<Integer, byte[]> readDataGroups) {
        SODFile sod;
        try {
            sod = new SODFile(service.getInputStream(PassportService.EF_SOD));
        } catch (Throwable t) {
            logError("[EF.SOD] NOT READABLE -> Passive Authentication impossible", t);
            step("EF.SOD");
            return null;
        }
        step("EF.SOD read");

        try {
            Map<Integer, byte[]> hashes = sod.getDataGroupHashes();
            log("[EF.SOD] ldsVersion=" + sod.getLDSVersion() + " digestAlg=" + sod.getDigestAlgorithm()
                    + " signerInfoDigestAlg=" + sod.getSignerInfoDigestAlgorithm()
                    + " signatureAlg=" + sod.getDigestEncryptionAlgorithm());
            log("[EF.SOD] data groups listed (hashed) = DG" + new TreeSet<>(hashes.keySet()).toString().replace(", ", ", DG"));

            // 1. Hash of every data group we read vs the hash stored in EF.SOD
            MessageDigest digest = MessageDigest.getInstance(sod.getDigestAlgorithm(), BC);
            for (Map.Entry<Integer, byte[]> dg : readDataGroups.entrySet()) {
                byte[] expected = hashes.get(dg.getKey());
                if (expected == null) {
                    log("[PA] DG" + dg.getKey() + " hash: NOT LISTED in EF.SOD");
                    continue;
                }
                boolean match = Arrays.equals(expected, digest.digest(dg.getValue()));
                log("[PA] DG" + dg.getKey() + " hash: " + (match ? "MATCH" : "MISMATCH !!!"));
            }
        } catch (Throwable t) {
            logError("[PA] hash check error", t);
        }

        // 2. Document Signer certificate
        X509Certificate ds = null;
        try {
            List<X509Certificate> certs = sod.getDocSigningCertificates();
            log("[DS] certificates embedded in EF.SOD: " + (certs == null ? 0 : certs.size()));
            ds = sod.getDocSigningCertificate();
        } catch (Throwable t) {
            logError("[DS] cannot extract certificate", t);
        }
        try {
            log("[DS] signer identifier: issuer=" + sod.getIssuerX500Principal() + " serial=" + hexOrNull(sod.getSerialNumber())
                    + " ski=" + hex(sod.getSubjectKeyIdentifier()));
        } catch (Throwable t) {
            logError("[DS] signer identifier", t);
        }
        if (ds != null) {
            logCertificate("[DS]", ds);
        } else {
            log("[DS] NO certificate in EF.SOD -> allowlist must use issuer+serial / SKI instead");
        }

        // 3. EF.SOD signature, verified with the embedded DS certificate
        if (ds != null) {
            try {
                boolean valid = verifySodSignature(sod, ds);
                log("[PA] EF.SOD signature with embedded DS certificate: " + (valid ? "VALID" : "INVALID !!!"));
            } catch (Throwable t) {
                logError("[PA] EF.SOD signature verification error", t);
            }
        }
        step("EF.SOD checks");
        return sod;
    }

    private boolean verifySodSignature(SODFile sod, X509Certificate ds) throws Exception {
        // getEContent() returns the DER signed attributes and checks their messageDigest against the content
        byte[] signedBytes = sod.getEContent();
        String algorithm = sod.getDigestEncryptionAlgorithm();
        Signature signature;
        if (algorithm.toUpperCase().contains("PSS")) {
            signature = Signature.getInstance("RSASSA-PSS", BC);
            signature.setParameter(sod.getDigestEncryptionAlgorithmParams());
        } else {
            if (!algorithm.toUpperCase().contains("WITH")) {
                algorithm = sod.getSignerInfoDigestAlgorithm().replace("-", "") + "with" + algorithm;
            }
            signature = Signature.getInstance(algorithm, BC);
        }
        log("[PA] verifying with " + signature.getAlgorithm());
        signature.initVerify(ds.getPublicKey());
        signature.update(signedBytes);
        return signature.verify(sod.getEncryptedDigest());
    }

    private DG14File readDg14(PassportService service, SODFile sod) {
        if (sod != null && !sod.getDataGroupHashes().containsKey(14)) {
            log("[DG14] not listed in EF.SOD -> no Chip Authentication");
            return null;
        }
        try {
            byte[] bytes = readAll(service.getInputStream(PassportService.EF_DG14));
            // Some chips encode INTEGERs with leading zeros, which BouncyCastle rejects by default
            System.setProperty("org.bouncycastle.asn1.allow_unsafe_integer", "true");
            DG14File dg14 = new DG14File(new ByteArrayInputStream(bytes));
            log("[DG14] present, " + dg14.getSecurityInfos().size() + " SecurityInfo(s)" + hashCheck(sod, 14, bytes));
            for (SecurityInfo info : dg14.getSecurityInfos()) {
                log("[DG14]   " + describeSecurityInfo(info));
            }
            step("DG14");
            return dg14;
        } catch (Throwable t) {
            log("[DG14] absent or unreadable (" + t.getClass().getSimpleName() + ": " + t.getMessage() + ")");
            step("DG14");
            return null;
        }
    }

    /** Returns the AA public key. Parsed with BouncyCastle: Android's provider rejects some curves (e.g. brainpool). */
    private PublicKey readDg15(PassportService service, SODFile sod) {
        if (sod != null && !sod.getDataGroupHashes().containsKey(15)) {
            log("[DG15] not listed in EF.SOD -> no Active Authentication");
            return null;
        }
        try {
            byte[] bytes = readAll(service.getInputStream(PassportService.EF_DG15));
            TLVInputStream tlv = new TLVInputStream(new ByteArrayInputStream(bytes));
            tlv.readTag();
            tlv.readLength();
            X509EncodedKeySpec spec = new X509EncodedKeySpec(tlv.readValue());
            PublicKey key = null;
            for (String algorithm : new String[]{"RSA", "EC"}) {
                try {
                    key = KeyFactory.getInstance(algorithm, BC).generatePublic(spec);
                    break;
                } catch (Exception ignored) {
                    // try the next key type
                }
            }
            log("[DG15] present, AA public key: " + describeKey(key) + describeCurve(key) + hashCheck(sod, 15, bytes));
            step("DG15");
            return key;
        } catch (Throwable t) {
            log("[DG15] absent or unreadable (" + t.getClass().getSimpleName() + ": " + t.getMessage() + ")");
            step("DG15");
            return null;
        }
    }

    private String describeCurve(PublicKey key) {
        if (key instanceof org.bouncycastle.jce.interfaces.ECPublicKey) {
            org.bouncycastle.jce.spec.ECParameterSpec params = ((org.bouncycastle.jce.interfaces.ECPublicKey) key).getParameters();
            if (params instanceof org.bouncycastle.jce.spec.ECNamedCurveParameterSpec) {
                return " curve=" + ((org.bouncycastle.jce.spec.ECNamedCurveParameterSpec) params).getName();
            }
            return " curve=explicit parameters";
        }
        return "";
    }

    // ---------------------------------------------------------------- Active Authentication

    private void tryActiveAuthentication(PassportService service, DG14File dg14, PublicKey key) {
        if (key == null) {
            log("[AA] skipped (no usable DG15 key)");
            return;
        }
        try {
            byte[] challenge = new byte[8];
            new SecureRandom().nextBytes(challenge);

            String signatureAlgorithm = null;
            if (dg14 != null) {
                for (ActiveAuthenticationInfo info : dg14.getActiveAuthenticationInfos()) {
                    signatureAlgorithm = ActiveAuthenticationInfo.lookupMnemonicByOID(info.getSignatureAlgorithmOID());
                }
            }
            if (signatureAlgorithm == null) {
                signatureAlgorithm = key instanceof ECPublicKey ? "SHA256withECDSA" : "SHA1WithRSA/ISO9796-2";
            }
            AAResult result = service.doAA(key, "SHA-1", signatureAlgorithm, challenge);
            byte[] response = result.getResponse();
            log("[AA] chip answered INTERNAL AUTHENTICATE, response=" + response.length + " bytes, algorithm=" + signatureAlgorithm);

            boolean valid;
            if (key instanceof ECPublicKey) {
                valid = verifyEcdsaPlain(key, signatureAlgorithm, challenge, response);
                if (!valid) {
                    // DG14 may be missing or unparsable: find which digest the chip used
                    for (String candidate : new String[]{"SHA1withECDSA", "SHA224withECDSA", "SHA256withECDSA", "SHA384withECDSA", "SHA512withECDSA"}) {
                        if (verifyEcdsaPlain(key, candidate, challenge, response)) {
                            log("[AA] signature verifies with " + candidate);
                            valid = true;
                            break;
                        }
                    }
                }
            } else {
                valid = verifyRsaIso9796(key, challenge, response);
            }
            log("[AA] signature over random challenge: " + (valid ? "VALID -> chip holds the DG15 private key" : "INVALID !!!"));
        } catch (Throwable t) {
            logError("[AA] FAILED", t);
        }
        step("AA");
    }

    /** ECDSA AA responses are plain r||s; convert to DER before verifying. */
    private boolean verifyEcdsaPlain(PublicKey key, String algorithm, byte[] challenge, byte[] response) throws Exception {
        int half = response.length / 2;
        ASN1EncodableVector vector = new ASN1EncodableVector();
        vector.add(new ASN1Integer(new BigInteger(1, Arrays.copyOfRange(response, 0, half))));
        vector.add(new ASN1Integer(new BigInteger(1, Arrays.copyOfRange(response, half, response.length))));
        Signature signature = Signature.getInstance(algorithm.replace("withPLAIN-ECDSA", "withECDSA"), BC);
        signature.initVerify(key);
        signature.update(challenge);
        return signature.verify(new DERSequence(vector).getEncoded());
    }

    /** RSA AA uses ISO/IEC 9796-2 scheme 1 with partial message recovery. */
    private boolean verifyRsaIso9796(PublicKey key, byte[] challenge, byte[] response) throws Exception {
        RSAPublicKey rsa = (RSAPublicKey) key;
        BigInteger n = rsa.getModulus();
        BigInteger m = new BigInteger(1, response).modPow(rsa.getPublicExponent(), n);
        if ((m.intValue() & 0x0F) != 0x0C) {
            m = n.subtract(m);
        }
        int k = (n.bitLength() + 7) / 8;
        byte[] block = toFixedLength(m, k);

        int trailerLength;
        String digestAlgorithm;
        if ((block[k - 1] & 0xFF) == 0xBC) {
            trailerLength = 1;
            digestAlgorithm = "SHA-1";
        } else {
            trailerLength = 2;
            switch (block[k - 2] & 0xFF) {
                case 0x33: digestAlgorithm = "SHA-1"; break;
                case 0x34: digestAlgorithm = "SHA-256"; break;
                case 0x35: digestAlgorithm = "SHA-512"; break;
                case 0x36: digestAlgorithm = "SHA-384"; break;
                case 0x38: digestAlgorithm = "SHA-224"; break;
                default:
                    log("[AA] unknown ISO 9796-2 trailer " + hex(Arrays.copyOfRange(block, k - 2, k)));
                    return false;
            }
        }
        if ((block[0] & 0xF0) != 0x60) {
            log("[AA] unexpected ISO 9796-2 header " + String.format("%02X", block[0]));
            return false;
        }
        MessageDigest digest = MessageDigest.getInstance(digestAlgorithm, BC);
        int hashLength = digest.getDigestLength();
        byte[] recovered = Arrays.copyOfRange(block, 1, k - trailerLength - hashLength);
        byte[] storedHash = Arrays.copyOfRange(block, k - trailerLength - hashLength, k - trailerLength);
        digest.update(recovered);
        digest.update(challenge);
        log("[AA] ISO 9796-2 digest=" + digestAlgorithm + " trailer=" + (trailerLength == 1 ? "implicit" : "explicit"));
        return Arrays.equals(storedHash, digest.digest());
    }

    // ---------------------------------------------------------------- Chip Authentication

    private void tryChipAuthentication(PassportService service, DG14File dg14) {
        if (dg14 == null || dg14.getChipAuthenticationPublicKeyInfos().isEmpty()) {
            log("[CA] skipped (no ChipAuthenticationPublicKeyInfo in DG14)");
            return;
        }
        ChipAuthenticationPublicKeyInfo keyInfo = dg14.getChipAuthenticationPublicKeyInfos().get(0);
        String caOid = null;
        for (ChipAuthenticationInfo info : dg14.getChipAuthenticationInfos()) {
            caOid = info.getObjectIdentifier();
        }
        if (caOid == null) {
            caOid = SecurityInfo.ID_PK_ECDH.equals(keyInfo.getObjectIdentifier())
                    ? SecurityInfo.ID_CA_ECDH_3DES_CBC_CBC
                    : SecurityInfo.ID_CA_DH_3DES_CBC_CBC;
        }
        try {
            service.doEACCA(keyInfo.getKeyId(), caOid, keyInfo.getObjectIdentifier(), keyInfo.getSubjectPublicKey());
            // The session is now keyed with the chip's DG14 key: reading under it proves the chip owns that key.
            byte[] check = readAll(service.getInputStream(PassportService.EF_COM));
            log("[CA] SUCCESS oid=" + caOid + " keyId=" + keyInfo.getKeyId()
                    + ", read " + check.length + " bytes under the new session -> chip holds the DG14 private key");
        } catch (Throwable t) {
            logError("[CA] FAILED oid=" + caOid, t);
        }
        step("CA");
    }

    // ---------------------------------------------------------------- helpers

    private String hashCheck(SODFile sod, int dataGroup, byte[] bytes) {
        if (sod == null) return "";
        try {
            byte[] expected = sod.getDataGroupHashes().get(dataGroup);
            byte[] actual = MessageDigest.getInstance(sod.getDigestAlgorithm(), BC).digest(bytes);
            return ", hash vs EF.SOD: " + (Arrays.equals(expected, actual) ? "MATCH" : "MISMATCH !!!");
        } catch (Throwable t) {
            return ", hash check error: " + t.getMessage();
        }
    }

    private void logCertificate(String prefix, X509Certificate cert) {
        try {
            log(prefix + " subject=" + cert.getSubjectX500Principal());
            log(prefix + " issuer=" + cert.getIssuerX500Principal() + "   <-- this is the CSCA that signed it");
            log(prefix + " serial=" + cert.getSerialNumber().toString(16).toUpperCase());
            log(prefix + " validity=" + cert.getNotBefore() + " -> " + cert.getNotAfter());
            log(prefix + " sigAlg=" + cert.getSigAlgName() + " key=" + describeKey(cert.getPublicKey()));
            byte[] aki = cert.getExtensionValue("2.5.29.35");
            if (aki != null) {
                log(prefix + " authorityKeyId (CSCA key id)=" + hex(AuthorityKeyIdentifier.getInstance(
                        ASN1OctetString.getInstance(aki).getOctets()).getKeyIdentifier()));
            }
            byte[] ski = cert.getExtensionValue("2.5.29.14");
            if (ski != null) {
                log(prefix + " subjectKeyId=" + hex(SubjectKeyIdentifier.getInstance(
                        ASN1OctetString.getInstance(ski).getOctets()).getKeyIdentifier()));
            }
            log(prefix + " sha256Fingerprint=" + hex(MessageDigest.getInstance("SHA-256").digest(cert.getEncoded())));
            // The DS certificate belongs to the issuing state, not the holder: safe to log, needed for the allowlist
            log(prefix + " PEM:\n-----BEGIN CERTIFICATE-----\n"
                    + Base64.encodeToString(cert.getEncoded(), Base64.NO_WRAP) + "\n-----END CERTIFICATE-----");
        } catch (Throwable t) {
            logError(prefix + " certificate details", t);
        }
    }

    private String describeSecurityInfo(SecurityInfo info) {
        StringBuilder sb = new StringBuilder(info.getClass().getSimpleName())
                .append(" oid=").append(info.getObjectIdentifier())
                .append(" (").append(info.getProtocolOIDString()).append(")");
        if (info instanceof PACEInfo) {
            sb.append(" version=").append(((PACEInfo) info).getVersion())
                    .append(" paramId=").append(((PACEInfo) info).getParameterId());
        } else if (info instanceof ChipAuthenticationInfo) {
            sb.append(" version=").append(((ChipAuthenticationInfo) info).getVersion())
                    .append(" keyId=").append(((ChipAuthenticationInfo) info).getKeyId());
        } else if (info instanceof ChipAuthenticationPublicKeyInfo) {
            sb.append(" keyId=").append(((ChipAuthenticationPublicKeyInfo) info).getKeyId())
                    .append(" key=").append(describeKey(((ChipAuthenticationPublicKeyInfo) info).getSubjectPublicKey()));
        } else if (info instanceof ActiveAuthenticationInfo) {
            sb.append(" signatureAlgOid=").append(((ActiveAuthenticationInfo) info).getSignatureAlgorithmOID());
        }
        return sb.toString();
    }

    private String describeKey(PublicKey key) {
        if (key instanceof RSAPublicKey) {
            return "RSA-" + ((RSAPublicKey) key).getModulus().bitLength();
        }
        if (key instanceof ECPublicKey) {
            return "EC-" + ((ECPublicKey) key).getParams().getCurve().getField().getFieldSize();
        }
        return key == null ? "null" : key.getAlgorithm();
    }

    private void step(String name) {
        long now = SystemClock.elapsedRealtime();
        log("[TIMING] " + name + "=" + (now - stepTime) + "ms");
        stepTime = now;
    }

    private static byte[] readAll(InputStream in) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int read;
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
        }
        return out.toByteArray();
    }

    private static byte[] toFixedLength(BigInteger value, int length) {
        byte[] raw = value.toByteArray();
        if (raw.length == length) return raw;
        byte[] out = new byte[length];
        int copy = Math.min(raw.length, length);
        System.arraycopy(raw, raw.length - copy, out, length - copy, copy);
        return out;
    }

    private static String hex(byte[] bytes) {
        if (bytes == null) return "null";
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02X", b));
        }
        return sb.toString();
    }

    private static String hexOrNull(BigInteger value) {
        return value == null ? "null" : value.toString(16).toUpperCase();
    }

    private void log(String message) {
        // logcat truncates around 4000 chars per line
        for (int i = 0; i < message.length(); i += 3000) {
            Log.i(TAG, message.substring(i, Math.min(message.length(), i + 3000)));
        }
    }

    private void logError(String prefix, Throwable t) {
        log(prefix + ": " + t.getClass().getSimpleName() + ": " + t.getMessage());
    }
}
