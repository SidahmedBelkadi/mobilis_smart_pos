package sms;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.telephony.SmsMessage;
import android.util.Log;

import io.flutter.plugin.common.MethodChannel;

public class SmsReceiver extends BroadcastReceiver {
    private static MethodChannel channel;
    private static String senderPhoneNumber;

    public static void setMethodChannel(MethodChannel methodChannel) {
        channel = methodChannel;
    }

    public static void setSenderPhoneNumber(String phoneNumber) {
        senderPhoneNumber = phoneNumber;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        Bundle bundle = intent.getExtras();
        SmsMessage[] msgs = null;
        String str = "";
        if (bundle != null) {
            Object[] pdus = (Object[]) bundle.get("pdus");
            msgs = new SmsMessage[pdus.length];
            for (int i = 0; i < msgs.length; i++) {
                msgs[i] = SmsMessage.createFromPdu((byte[]) pdus[i]);
                String sender = msgs[i].getOriginatingAddress();
                int messageClass = msgs[i].getMessageClass().ordinal();

                // Handling flash message (Class 0 SMS)
                if (messageClass == SmsMessage.MessageClass.CLASS_0.ordinal()) {
                    str += msgs[i].getMessageBody().toString();
                    Log.d("SmsReceiver", "Flash SMS Received: " + str);
                    if (channel != null) {
                        channel.invokeMethod("receivedSms", str);
                    } else {
                        Log.e("SmsReceiver", "MethodChannel is null");
                    }
                }
            }
        }
    }
}