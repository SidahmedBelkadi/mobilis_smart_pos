package com.ai_univers.smart_point_of_sale.Reader;

import android.nfc.tech.IsoDep;

public interface NFCReader {
    void readNFC(IsoDep isoDep, NFCResultCallback callback);
}

