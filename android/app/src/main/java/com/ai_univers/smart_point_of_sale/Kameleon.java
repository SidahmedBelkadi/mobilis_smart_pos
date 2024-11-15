package com.ai_univers.smart_point_of_sale;

import android.content.Context;
import android.nfc.tech.IsoDep;

import com.ai_univers.smart_point_of_sale.Reader.DzNfcReaderImpl;
import com.ai_univers.smart_point_of_sale.Reader.NFCReader;
import com.ai_univers.smart_point_of_sale.Reader.NFCResultCallback;


public class Kameleon {
    private static NFCReader nfcReader;

    public static void initialize(Context context, String documentType, String documentNumber, String dateOfBirth, String dateOfExpiry, boolean extractFacialImage, boolean extractSignature) {
        nfcReader = new DzNfcReaderImpl(context, documentType, documentNumber, dateOfBirth, dateOfExpiry, extractFacialImage, extractSignature);
    }

    public static void readNFC(IsoDep isoDep, NFCResultCallback callback) {
        if (nfcReader != null) {
            nfcReader.readNFC(isoDep, callback);
        } else {
            callback.onError("NFCReader not initialized");
        }
    }
}