package com.ai_univers.smart_point_of_sale.Dz;

import android.content.Context;
import android.nfc.tech.IsoDep;


public class DzNfcViewModel {

    private final DzNfcModel nfcModel;

    // Modify the constructor to accept Context
    public DzNfcViewModel(Context context, String documentType, String documentNumber, String dateOfBirth, String dateOfExpiry, boolean extractFacialImage, boolean extractSignature) {
        // Initialize the NfcModel with the passed context
        nfcModel = new DzNfcModel(context, documentType, documentNumber, dateOfBirth, dateOfExpiry, extractFacialImage, extractSignature);

    }

    public String readNfcTag(IsoDep isoDep) {
        try {
            String result = String.valueOf(nfcModel.readNfcData(isoDep, null));
            return result;
        } catch (Exception e) {
            return "Error reading NFC tag: " + e.getMessage();
        }
    }
}
