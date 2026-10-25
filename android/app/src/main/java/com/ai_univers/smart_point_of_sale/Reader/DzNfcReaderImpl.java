package com.ai_univers.smart_point_of_sale.Reader;

import android.content.Context;
import android.nfc.tech.IsoDep;

import com.ai_univers.smart_point_of_sale.Dz.DzNfcModel;

import org.json.JSONObject;

public class DzNfcReaderImpl implements NFCReader {

    private final DzNfcModel dzNfcModel;

    public DzNfcReaderImpl(Context context, String documentType, String documentNumber, String dateOfBirth, String dateOfExpiry, boolean extractFacialImage, boolean extractSignature) {
        dzNfcModel = new DzNfcModel(context, documentType, documentNumber, dateOfBirth, dateOfExpiry, extractFacialImage, extractSignature);
    }

    @Override
    public void readNFC(IsoDep isoDep, NFCResultCallback callback) {
        try {
            JSONObject result = dzNfcModel.readNfcData(isoDep);
            callback.onSuccess(result);
        } catch (DocumentVerificationException e) {
            // Not a reading problem: the chip is not a genuine document
            callback.onError("DOCUMENT_NOT_AUTHENTIC: " + e.getMessage());
        } catch (Exception e) {
            callback.onError("NFC reading failed: " + e.getMessage());
        }
    }
}
