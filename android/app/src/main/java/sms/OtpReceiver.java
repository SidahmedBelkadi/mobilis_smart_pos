package sms;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.telephony.SmsMessage;

import io.flutter.plugin.common.MethodChannel;

public class OtpReceiver extends BroadcastReceiver {
    private static final String OTP_CHANNEL = "otp/otp_receiver";
    private MethodChannel methodChannel;

    public OtpReceiver(MethodChannel channel) {
        this.methodChannel = channel;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        Bundle bundle = intent.getExtras();
        if (bundle != null) {
            Object[] pdus = (Object[]) bundle.get("pdus");
            if (pdus != null) {
                for (Object pdu : pdus) {
                    SmsMessage smsMessage = SmsMessage.createFromPdu((byte[]) pdu);
                    String messageBody = smsMessage.getMessageBody();
                    String sender = smsMessage.getDisplayOriginatingAddress();

                    // Check if the message is from a known sender
                    if (isOtpMessage(messageBody, sender)) {
                        // Extract the OTP and send it back to Flutter
                        String otp = extractOtp(messageBody);
                        methodChannel.invokeMethod("otp_received", otp);
                    }
                }
            }
        }
    }

    private boolean isOtpMessage(String message, String sender) {
        return sender.equalsIgnoreCase("MS-POS") && message.matches(".*\\d{6}.*");
    }

    private String extractOtp(String message) {
        // Logic to extract OTP from the message
        String[] parts = message.split(" ");
        for (String part : parts) {
            if (part.matches("\\d{6}")) {
                return part;
            }
        }
        return null;
    }
}
