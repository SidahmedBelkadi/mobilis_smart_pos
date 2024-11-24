package com.ai_univers.smart_point_of_sale;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.nfc.NfcAdapter;
import android.nfc.NfcManager;
import android.nfc.Tag;
import android.nfc.tech.IsoDep;
import android.os.Build;
import android.os.Bundle;
import android.os.Debug;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.ai_univers.smart_point_of_sale.Reader.NFCResultCallback;
import com.ai_univers.smart_point_of_sale.vision.BarcodeScannerActivity;
import com.ai_univers.smart_point_of_sale.vision.ScanActivity;

import org.json.JSONObject;

import java.io.File;
import java.util.HashMap;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import sms.OtpReceiver;
import sms.SmsReceiver;
import sms.SmsSender;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "channel";
    private static final String SMS_CHANNEL = "sms/sms_receiver";
    private static final String OTP_CHANNEL = "otp_receiver";
    private NfcAdapter nfcAdapter;
    private boolean isNfcReadCompleted = false;

    private boolean resultSent = false;
    private static final int OCR_REQUEST_CODE = 1001;
    private static final int BARCODE_REQUEST_CODE = 2002;
    private MethodChannel.Result pendingResult;
    private MethodChannel.Result barCodePendingResult;


    // Method to check if NFC is enabled on the device
    public static boolean isNfcEnabled(Context context) {
        NfcManager nfcManager = (NfcManager) context.getSystemService(Context.NFC_SERVICE);
        if (nfcManager != null) {
            NfcAdapter nfcAdapter = nfcManager.getDefaultAdapter();
            return nfcAdapter != null && nfcAdapter.isEnabled();
        }
        return false;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Initialize NFC adapter
        nfcAdapter = NfcAdapter.getDefaultAdapter(this);

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        new MethodChannel.MethodCallHandler() {
                            @Override
                            public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
                                if (call.method.equals("readNfc")) {
                                    // Extract the parameters
                                    String documentType = call.argument("documentType");
                                    String documentNumber = call.argument("documentNumber");
                                    String dateOfBirth = call.argument("dateOfBirth");
                                    String dateOfExpiry = call.argument("dateOfExpiry");
                                    boolean extractFacialImage = call.argument("exractFacialImage");
                                    boolean extractSignature = call.argument("extrcatSignature");

                                    // Initialize Kameleon SDK with the received parameters
                                    Kameleon.initialize(MainActivity.this, documentType, documentNumber, dateOfBirth, dateOfExpiry, extractFacialImage, extractSignature);

                                    // Reset flags
                                    resultSent = false;
                                    isNfcReadCompleted = false;

                                    // Start the NFC read process
                                    startNfcReading(result);
                                } else if (call.method.equals("securityCheck")) {
                                    boolean securityStatus = checkSecurity();
                                    result.success(securityStatus);

                                } else if (call.method.equals("otp_received")) {
                                    String otp = call.arguments.toString();

                                } else if (call.method.equals("isNfcEnabled")) {
                                    result.success(isNfcEnabled(MainActivity.this));
                                }else if (call.method.equals("startOCR")) {
                                    String documentType = call.argument("documentType");
                                    pendingResult = result;
                                    Intent intent = new Intent(MainActivity.this, ScanActivity.class);
                                    intent.putExtra("documentType", documentType);
                                    startActivityForResult(intent, OCR_REQUEST_CODE);

                                }if (call.method.equals("startBarcodeScanner")) {
                                    if (barCodePendingResult != null) {
                                        result.error("ALREADY_ACTIVE", "A scan is already in progress", null);
                                        return;
                                    }
                                    barCodePendingResult = result;
                                    startBarcodeScanner();
                                }
                            }
                        }
                );


        // Set up Otp method channel
        MethodChannel otpMethodChannel = new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), OTP_CHANNEL);
        OtpReceiver otpReceiver = new OtpReceiver(otpMethodChannel);

        // Set up SMS method channel
        MethodChannel smsMethodChannel = new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), SMS_CHANNEL);
        smsMethodChannel.setMethodCallHandler(new SmsSender(this));
        SmsReceiver.setMethodChannel(smsMethodChannel);

        // Register the SMS receiver
        registerReceiver(new SmsReceiver(), new IntentFilter("android.provider.Telephony.SMS_RECEIVED"));

        // Register the OTP receiver
        registerReceiver(otpReceiver, new IntentFilter("android.provider.Telephony.SMS_RECEIVED"));

        // Request necessary permissions
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, android.Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECEIVE_SMS) != PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{
                    android.Manifest.permission.READ_PHONE_STATE,
                    android.Manifest.permission.SEND_SMS,
                    android.Manifest.permission.RECEIVE_SMS,
                    android.Manifest.permission.READ_SMS,
                    Manifest.permission.READ_PHONE_NUMBERS
            }, 1);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (requestCode == BARCODE_REQUEST_CODE) {
            if (barCodePendingResult != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    String scannedData = data.getStringExtra("SCAN_RESULT");
                    barCodePendingResult.success(scannedData); // Pass barcode data to Flutter
                } else {
                    barCodePendingResult.error("SCAN_ERROR", "Barcode scan failed or canceled", null);
                }
                barCodePendingResult = null; // Clear pendingResult
            }
        }



        if (requestCode == OCR_REQUEST_CODE) {
            if (pendingResult != null) {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    String documentNumber = data.getStringExtra("documentNumber");
                    String birthDate = data.getStringExtra("birthDate");
                    String expiredDate = data.getStringExtra("expiredDate");

                    // Pass the result back to Flutter
                    pendingResult.success(new HashMap<String, String>() {{
                        put("documentNumber", documentNumber);
                        put("birthDate", birthDate);
                        put("expiredDate", expiredDate);
                    }});
                } else {
                    pendingResult.error("ERROR", "OCR failed or canceled", null);
                }
                pendingResult = null; // Clear the result to avoid duplicate replies
            }
        }
    }

    private void startBarcodeScanner() {
        Intent intent = new Intent(this, BarcodeScannerActivity.class);
        startActivityForResult(intent, BARCODE_REQUEST_CODE);
    }


    private void startNfcReading(MethodChannel.Result result) {
        NfcAdapter.ReaderCallback readerCallback = new NfcAdapter.ReaderCallback() {
            @Override
            public void onTagDiscovered(Tag tag) {

                if (isNfcReadCompleted || resultSent) {
                    return;  // Prevent further NFC reads if reading is already completed
                }

                IsoDep isoDep = IsoDep.get(tag);
                if (isoDep != null) {
                    try {
                        // Notify Flutter that NFC reading has started
                        runOnUiThread(() -> new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                                .invokeMethod("reading_started", null));

                        // Read the NFC data using the Kameleon SDK
                        Kameleon.readNFC(isoDep, new NFCResultCallback() {
                            @Override
                            public void onSuccess(JSONObject json) {
                                runOnUiThread(() -> result.success(json.toString()));
                                resultSent = true;
                                isNfcReadCompleted = true;
                            }

                            @Override
                            public void onError(String errorMessage) {
                                runOnUiThread(() -> result.error("NFC_READ_ERROR", errorMessage, null));
                                resultSent = true;
                            }
                        });
                    } catch (Exception e) {
                        Log.e("MainActivity", "Error reading NFC tag : " + e, e);
                        runOnUiThread(() -> result.error("NFC_READ_ERROR", "Failed to read NFC tag" + e, null));
                    }
                }
            }
        };

        nfcAdapter.enableReaderMode(this, readerCallback, NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK | NfcAdapter.FLAG_READER_NFC_A | NfcAdapter.FLAG_READER_NFC_B, null);
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (nfcAdapter != null) {
            nfcAdapter.disableReaderMode(this);
        }
    }

    private boolean checkSecurity() {
        boolean isEmulator = isRunningOnEmulator();
        boolean isDebugger = isDebuggerAttached();
        boolean isRooted = isDeviceRooted();


        return isEmulator || isDebugger || isRooted;
    }

    private boolean isRunningOnEmulator() {
        String buildFingerprint = Build.FINGERPRINT;
        String buildModel = Build.MODEL;
        String buildManufacturer = Build.MANUFACTURER;
        String hardware = Build.HARDWARE;
        String product = Build.PRODUCT;
        String brand = Build.BRAND;
        String device = Build.DEVICE;

        return (Build.PRODUCT.contains("sdk") ||
                Build.MODEL.contains("Emulator") ||
                Build.MODEL.contains("Android SDK built for") ||
                Build.MANUFACTURER.contains("Genymotion") ||
                (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")) ||
                "google_sdk".equals(product) ||
                "goldfish".equals(hardware) ||
                "ranchu".equals(hardware) ||
                buildFingerprint.contains("vbox") || buildFingerprint.contains("generic") ||
                brand.contains("generic") || device.contains("generic"));
    }

    private boolean isDebuggerAttached() {
        return Debug.isDebuggerConnected() || Debug.waitingForDebugger();
    }

    // Enhanced root detection
    private boolean isDeviceRooted() {
        // Check for known root apps
        String[] knownRootAppsPackages = {
                "com.noshufou.android.su", "com.thirdparty.superuser",
                "eu.chainfire.supersu", "com.koushikdutta.superuser",
                "com.zachspong.temprootremovejb", "com.ramdroid.appquarantine"
        };
        for (String packageName : knownRootAppsPackages) {
            if (isPackageInstalled(packageName)) {
                return true;
            }
        }

        // Check for common root binaries
        String[] paths = {
                "/system/app/Superuser.apk",
                "/sbin/su", "/system/bin/su", "/system/xbin/su",
                "/data/local/xbin/su", "/data/local/bin/su", "/system/sd/xbin/su",
                "/system/bin/failsafe/su", "/data/local/su"
        };
        for (String path : paths) {
            if (new File(path).exists()) {
                // Try to use the su command to check for root access
                if (canExecuteCommand("whoami")) {
                    return true;
                } else {
                }
            }
        }

        // Check if the 'su' command can be executed
        if (canExecuteCommand("whoami")) {
            return true;
        }

        if (canExecuteCommand("busybox whoami")) {
            return true;
        }

        return false;
    }

    // Helper method to check if a command can be executed
    private boolean canExecuteCommand(String command) {
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"su", "-c", command});
            int exitValue = process.waitFor();
            return exitValue == 0;  // If exit value is 0, the command executed successfully
        } catch (Exception e) {
            return false;  // The command could not be executed, so assume no root
        }
    }

    // Helper method to check if a known root app is installed
    private boolean isPackageInstalled(String packageName) {
        PackageManager packageManager = getPackageManager();
        try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

}
