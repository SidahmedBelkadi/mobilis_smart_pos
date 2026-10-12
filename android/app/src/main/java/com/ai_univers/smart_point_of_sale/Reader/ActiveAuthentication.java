package com.ai_univers.smart_point_of_sale.Reader;

import android.util.Log;

import net.sf.scuba.smartcards.CardServiceException;
import net.sf.scuba.tlv.TLVInputStream;

import org.bouncycastle.asn1.pkcs.PKCSObjectIdentifiers;
import org.bouncycastle.asn1.x509.SubjectPublicKeyInfo;
import org.bouncycastle.crypto.Digest;
import org.bouncycastle.crypto.digests.SHA1Digest;
import org.bouncycastle.crypto.digests.SHA224Digest;
import org.bouncycastle.crypto.digests.SHA256Digest;
import org.bouncycastle.crypto.digests.SHA384Digest;
import org.bouncycastle.crypto.digests.SHA512Digest;
import org.bouncycastle.crypto.engines.RSAEngine;
import org.bouncycastle.crypto.params.RSAKeyParameters;
import org.bouncycastle.crypto.signers.ISO9796d2Signer;
import org.jmrtd.PassportService;
import org.jmrtd.lds.SODFile;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.spec.RSAPublicKeySpec;

/**
 * Active Authentication (ICAO 9303 part 11): the chip signs a fresh random
 * challenge with the private key matching the public key stored in DG15.
 * The private key cannot be extracted, so a cloned or emulated chip cannot answer.
 *
 * Only meaningful together with Passive Authentication: DG15 is trusted because
 * its hash is listed in EF.SOD, and EF.SOD must be verified against the CSCA.
 *
 * Algerian CNIBE and passports use RSA-1024 with ISO/IEC 9796-2 scheme 1 (SHA-1).
 */
public final class ActiveAuthentication {

    private static final String TAG = "NFC_AUTH";
    private static final int CHALLENGE_LENGTH = 8;
    private static final SecureRandom RANDOM = new SecureRandom();

    private ActiveAuthentication() {
    }

    /**
     * @throws DocumentVerificationException the chip is not genuine (reject the document)
     * @throws CardServiceException          communication error (the user may scan again)
     */
    public static void verify(PassportService service, SODFile sod) throws Exception {
        // 1. DG15 must be protected by EF.SOD, otherwise a fake chip supplies its own key
        byte[] expectedHash = sod.getDataGroupHashes().get(15);
        if (expectedHash == null) {
            throw fail("DG15 not listed in EF.SOD (document without Active Authentication)");
        }
        byte[] dg15 = readAll(service.getInputStream(PassportService.EF_DG15));
        byte[] actualHash = MessageDigest.getInstance(sod.getDigestAlgorithm()).digest(dg15);
        if (!MessageDigest.isEqual(expectedHash, actualHash)) {
            throw fail("DG15 hash does not match EF.SOD");
        }

        RSAKeyParameters key = parseRsaKey(dg15);

        // 2. Fresh challenge for every read: an old answer can never be replayed
        byte[] challenge = new byte[CHALLENGE_LENGTH];
        RANDOM.nextBytes(challenge);

        // Communication errors here propagate as CardServiceException
        byte[] response = service.doAA(toPublicKey(key), "SHA-1", "SHA1WithRSA/ISO9796-2", challenge).getResponse();

        // 3. Verify the signature over our challenge with the DG15 key
        if (response == null || response.length == 0 || response.length > (key.getModulus().bitLength() + 7) / 8) {
            throw fail("invalid Active Authentication response length");
        }
        if (!verifyIso9796(key, challenge, response)) {
            throw fail("Active Authentication signature is invalid");
        }
        Log.i(TAG, "Active Authentication OK");
    }

    private static boolean verifyIso9796(RSAKeyParameters key, byte[] challenge, byte[] response) {
        try {
            ISO9796d2Signer signer = new ISO9796d2Signer(new RSAEngine(), digestForTrailer(key, response), true);
            signer.init(false, key);
            // M1 (chip nonce) is recovered from the signature, M2 is our challenge
            signer.updateWithRecoveredMessage(response);
            signer.update(challenge, 0, challenge.length);
            return signer.verifySignature(response);
        } catch (Exception e) {
            Log.w(TAG, "ISO 9796-2 verification error: " + e);
            return false;
        }
    }

    /** ISO 9796-2 trailer: 0xBC = implicit SHA-1, otherwise 0xXXCC names the hash. */
    private static Digest digestForTrailer(RSAKeyParameters key, byte[] response) {
        RSAEngine engine = new RSAEngine();
        engine.init(false, key);
        byte[] block = engine.processBlock(response, 0, response.length);
        int last = block[block.length - 1] & 0xFF;
        if (last == 0xBC) {
            return new SHA1Digest();
        }
        switch (block[block.length - 2] & 0xFF) {
            case 0x34: return new SHA256Digest();
            case 0x35: return new SHA512Digest();
            case 0x36: return new SHA384Digest();
            case 0x38: return new SHA224Digest();
            default:   return new SHA1Digest();
        }
    }

    /** DG15 = tag 0x6F wrapping a SubjectPublicKeyInfo. */
    private static RSAKeyParameters parseRsaKey(byte[] dg15) throws Exception {
        TLVInputStream tlv = new TLVInputStream(new ByteArrayInputStream(dg15));
        tlv.readTag();
        tlv.readLength();
        SubjectPublicKeyInfo info = SubjectPublicKeyInfo.getInstance(tlv.readValue());
        if (!PKCSObjectIdentifiers.rsaEncryption.equals(info.getAlgorithm().getAlgorithm())) {
            throw fail("unsupported Active Authentication key type " + info.getAlgorithm().getAlgorithm());
        }
        org.bouncycastle.asn1.pkcs.RSAPublicKey rsa = org.bouncycastle.asn1.pkcs.RSAPublicKey.getInstance(info.parsePublicKey());
        return new RSAKeyParameters(false, rsa.getModulus(), rsa.getPublicExponent());
    }

    /** JMRTD only uses the key to size the expected response. */
    private static PublicKey toPublicKey(RSAKeyParameters key) throws Exception {
        return KeyFactory.getInstance("RSA").generatePublic(new RSAPublicKeySpec(key.getModulus(), key.getExponent()));
    }

    private static DocumentVerificationException fail(String reason) {
        Log.w(TAG, "Document rejected: " + reason);
        return new DocumentVerificationException(reason);
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
}
