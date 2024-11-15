package sms;

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.telephony.SmsManager;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.widget.Toast;

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

            // Check for necessary permissions
            if (ContextCompat.checkSelfPermission(activity, android.Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED ||
                    ContextCompat.checkSelfPermission(activity, android.Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED ||
                    ContextCompat.checkSelfPermission(activity, android.Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
                result.error("PERMISSION_DENIED", "Required permissions are not granted", null);
                return;
            }

            try {
                // Fetch and print SIM card information
                TelephonyManager telephonyManager = (TelephonyManager) activity.getSystemService(Context.TELEPHONY_SERVICE);
                String operatorName = telephonyManager.getSimOperatorName();
                String phoneNumber = telephonyManager.getLine1Number();
                String subscriberId = null;
                if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.Q) {
                    subscriberId = telephonyManager.getSubscriberId();
                } else {
                    subscriberId = "Restricted on Android Q and higher";
                }
                String networkOperatorName = telephonyManager.getNetworkOperatorName();
                String networkCountryIso = telephonyManager.getNetworkCountryIso();
                String simCountryIso = telephonyManager.getSimCountryIso();
                String simState = getSimStateString(telephonyManager.getSimState());

                // Log or print the information
                String simInfo = "Operator: " + operatorName +
                        "\nPhone Number: " + phoneNumber +
                        "\nSubscriber ID: " + subscriberId +
                        "\nNetwork Operator Name: " + networkOperatorName +
                        "\nNetwork Country ISO: " + networkCountryIso +
                        "\nSIM Country ISO: " + simCountryIso +
                        "\nSIM State: " + simState;

                System.out.println(simInfo);  // Print to log
//                Toast.makeText(activity, simInfo, Toast.LENGTH_LONG).show();
                Log.d("SIMINFO", simInfo);

                // Get the SubscriptionManager and list of active subscriptions
                SubscriptionManager subscriptionManager = null;
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP_MR1) {
                    subscriptionManager = (SubscriptionManager) activity.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);
                }
                List<SubscriptionInfo> subscriptionInfoList = null;
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP_MR1) {
                    subscriptionInfoList = subscriptionManager.getActiveSubscriptionInfoList();
                }

                if (subscriptionInfoList != null && !subscriptionInfoList.isEmpty()) {
                    SubscriptionInfo simSlot1 = subscriptionInfoList.get(0); // Assuming slot 0 is the first SIM slot
                    SmsManager smsManager = null;
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP_MR1) {
                        smsManager = SmsManager.getSmsManagerForSubscriptionId(simSlot1.getSubscriptionId());
                    }
                    smsManager.sendTextMessage(recipient, null, message, null, null);
//                    result.success("SMS sent.");
//                    Toast.makeText(activity, "SMS sent successfully via slot 1!", Toast.LENGTH_LONG).show();
                } else {
                    result.error("NO_SIM", "No active SIM found in slot 1", null);
                    Toast.makeText(activity, "No active SIM found in slot 1", Toast.LENGTH_LONG).show();
                }
            } catch (SecurityException e) {
                result.error("PERMISSION_DENIED", "Security exception: " + e.getMessage(), e);
                Toast.makeText(activity, "Failed to retrieve SIM info or send SMS due to permissions: " + e.getMessage(), Toast.LENGTH_LONG).show();
            } catch (Exception e) {
                result.error("SMS_FAILED", "Failed to send SMS", e);
                Toast.makeText(activity, "Failed to send SMS: " + e.getMessage(), Toast.LENGTH_LONG).show();
            }
        } else if (call.method.equals("setSenderPhoneNumber")) {
            String senderPhoneNumber = call.argument("senderPhoneNumber");
            sms.SmsReceiver.setSenderPhoneNumber(senderPhoneNumber);
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    private String getSimStateString(int state) {
        switch (state) {
            case TelephonyManager.SIM_STATE_ABSENT:
                return "ABSENT";
            case TelephonyManager.SIM_STATE_PIN_REQUIRED:
                return "PIN_REQUIRED";
            case TelephonyManager.SIM_STATE_PUK_REQUIRED:
                return "PUK_REQUIRED";
            case TelephonyManager.SIM_STATE_NETWORK_LOCKED:
                return "NETWORK_LOCKED";
            case TelephonyManager.SIM_STATE_READY:
                return "READY";
            case TelephonyManager.SIM_STATE_NOT_READY:
                return "NOT_READY";
            case TelephonyManager.SIM_STATE_PERM_DISABLED:
                return "PERM_DISABLED";
            case TelephonyManager.SIM_STATE_CARD_IO_ERROR:
                return "CARD_IO_ERROR";
            case TelephonyManager.SIM_STATE_CARD_RESTRICTED:
                return "CARD_RESTRICTED";
            default:
                return "UNKNOWN";
        }
    }
}