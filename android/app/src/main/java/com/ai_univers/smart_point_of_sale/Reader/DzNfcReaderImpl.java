package com.ai_univers.smart_point_of_sale.Reader;

import android.content.Context;
import android.nfc.TagLostException;
import android.nfc.tech.IsoDep;

import com.ai_univers.smart_point_of_sale.Dz.DzNfcModel;

import net.sf.scuba.smartcards.CardServiceException;

import org.json.JSONObject;

import java.io.IOException;

public class DzNfcReaderImpl implements NFCReader {

    private final DzNfcModel dzNfcModel;

    public DzNfcReaderImpl(Context context, String documentType, String documentNumber, String dateOfBirth, String dateOfExpiry, boolean extractFacialImage, boolean extractSignature) {
        dzNfcModel = new DzNfcModel(context, documentType, documentNumber, dateOfBirth, dateOfExpiry, extractFacialImage, extractSignature);
    }

    @Override
    public void readNFC(IsoDep isoDep, NfcProgressListener progressListener, NFCResultCallback callback) {
        try {
            JSONObject result = dzNfcModel.readNfcData(isoDep, progressListener);
            callback.onSuccess(result);
        } catch (DocumentVerificationException e) {
            // Not a reading problem: the chip is not a genuine document
            callback.onError(NFCResultCallback.DOCUMENT_NOT_AUTHENTIC, e.getMessage(), false);
        } catch (BacFailedException e) {
            callback.onError(NFCResultCallback.BAC_FAILED, e.getMessage(), false);
        } catch (Exception e) {
            boolean tagLost = isTagLost(e, isoDep);
            // The next attempt opens a new connection when the card is presented again
            try {
                isoDep.close();
            } catch (Exception ignored) {
            }
            if (tagLost) {
                callback.onError(NFCResultCallback.TAG_LOST, e.getMessage(), true);
            } else if (e instanceof CardServiceException || e instanceof IOException) {
                callback.onError(NFCResultCallback.READ_ERROR, e.getMessage(), true);
            } else {
                callback.onError(NFCResultCallback.NFC_READ_ERROR, "NFC reading failed: " + e.getMessage(), false);
            }
        }
    }

    /** JMRTD wraps the TagLostException, and some phones only report a closed connection. */
    public static boolean isTagLost(Throwable error, IsoDep isoDep) {
        for (Throwable t = error; t != null; t = t.getCause()) {
            if (t instanceof TagLostException) return true;
        }
        try {
            return !isoDep.isConnected();
        } catch (Exception e) {
            return true;
        }
    }
}
