package sms;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.provider.Settings;
import android.telephony.ServiceState;
import android.telephony.SmsManager;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import java.util.List;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class SmsSender implements MethodChannel.MethodCallHandler {
    private final Activity activity;

    public SmsSender(Activity activity) {
        this.activity = activity;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.equals("sendSms")) {
            String message = call.argument("message");
            String recipient = call.argument("recipient");
            int slot = call.argument("slot");


            // Check required permissions
            if (!hasRequiredPermissions()) {
                result.error("PERMISSION_DENIED", "Required permissions are not granted", null);
                return;
            }

            try {
                // Verify if the SIM is ready
                if (!isSimReady()) {
                    result.error("SIM_NOT_READY", "SIM is not ready", null);
                    return;
                }

                // Check if Airplane mode is enabled
                if (isAirplaneModeOn()) {
                    result.error("AIRPLANE_MODE", "Airplane mode is enabled", null);
                    return;
                }

                // Check SMS network availability
                if (!isSmsNetworkAvailable()) {
                    result.error("NO_SMS_NETWORK", "No network available for sending SMS", null);
                    return;
                }

                // Validate SIM and operator
                SubscriptionManager subscriptionManager = (SubscriptionManager) activity.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);
                if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
                    result.error("PERMISSION_DENIED", "READ_PHONE_STATE permission is not granted", null);
                    return;
                }

                List<SubscriptionInfo> subscriptionInfoList = subscriptionManager.getActiveSubscriptionInfoList();
                if (subscriptionInfoList == null || subscriptionInfoList.isEmpty()) {
                    result.error("NO_SIM", "No active SIM found", null);
                    return;
                }

                // Check SIM slot selected by user and operator name
                SubscriptionInfo simSlot = subscriptionInfoList.get(slot);
                String operatorName = simSlot.getCarrierName().toString();
                if (!"Mobilis".equalsIgnoreCase(operatorName)) {
                    result.error("INVALID_OPERATOR", "Operator in slot 1 is not Mobilis", null);
                    return;
                }

                // Send SMS using the appropriate subscription
                SmsManager smsManager = SmsManager.getSmsManagerForSubscriptionId(simSlot.getSubscriptionId());
                smsManager.sendTextMessage(recipient, null, message, null, null);
                result.success("SMS_SENT");
            } catch (Exception e) {
                result.error("SMS_FAILED", "Failed to send SMS: " + e.getMessage(), e);
            }
        } else {
            result.notImplemented();
        }
    }

    // Check if required permissions are granted
    private boolean hasRequiredPermissions() {
        return ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(activity, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED;
    }

    // Check if the SIM is ready
    private boolean isSimReady() {
        TelephonyManager telephonyManager = (TelephonyManager) activity.getSystemService(Context.TELEPHONY_SERVICE);
        int simState = telephonyManager.getSimState();
        return simState == TelephonyManager.SIM_STATE_READY;
    }

    // Check if Airplane mode is enabled
    private boolean isAirplaneModeOn() {
        return Settings.System.getInt(activity.getContentResolver(), Settings.Global.AIRPLANE_MODE_ON, 0) != 0;
    }

    // Check if SMS network is available
    private boolean isSmsNetworkAvailable() {
        TelephonyManager telephonyManager = (TelephonyManager) activity.getSystemService(Context.TELEPHONY_SERVICE);
        if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            return false;
        }

        ServiceState serviceState = telephonyManager.getServiceState();
        return serviceState != null && serviceState.getState() == ServiceState.STATE_IN_SERVICE;
    }
}
