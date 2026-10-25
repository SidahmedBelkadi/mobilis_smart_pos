package com.ai_univers.smart_point_of_sale.Reader;

import org.json.JSONObject;

public interface NFCResultCallback {

    /** The card was moved away or the radio link dropped: present it again. */
    String TAG_LOST = "TAG_LOST";
    /** Communication error while the card was still there: present it again. */
    String READ_ERROR = "READ_ERROR";
    /** The MRZ data does not unlock this chip: the document must be scanned again. */
    String BAC_FAILED = "BAC_FAILED";
    /** The chip failed a cryptographic check: the document is rejected. */
    String DOCUMENT_NOT_AUTHENTIC = "DOCUMENT_NOT_AUTHENTIC";
    /** Unexpected error (unreadable data...). */
    String NFC_READ_ERROR = "NFC_READ_ERROR";

    void onSuccess(JSONObject result);

    /**
     * @param retryable true when presenting the same card again may succeed
     */
    void onError(String code, String errorMessage, boolean retryable);
}
