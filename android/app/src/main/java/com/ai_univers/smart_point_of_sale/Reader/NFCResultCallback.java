package com.ai_univers.smart_point_of_sale.Reader;

import org.json.JSONObject;

public interface NFCResultCallback {
    void onSuccess(JSONObject result);

    void onError(String errorMessage);
}
