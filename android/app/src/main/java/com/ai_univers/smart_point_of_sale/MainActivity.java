package com.ai_univers.smart_point_of_sale;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.IntentSender;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.nfc.NfcAdapter;
import android.nfc.NfcManager;
import android.nfc.Tag;
import android.nfc.tech.IsoDep;
import android.os.Build;
import android.os.Bundle;
import android.os.Debug;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.ai_univers.smart_point_of_sale.Reader.NFCResultCallback;
import com.ai_univers.smart_point_of_sale.Reader.vision.BarcodeScannerActivity;
import com.ai_univers.smart_point_of_sale.Reader.vision.ScanActivity;
import com.ai_univers.smart_point_of_sale.security.DeviceSecurityPlugin;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanner;
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult;

import org.json.JSONObject;

import java.io.File;
import java.io.BufferedReader;
import java.io.FileReader;
import java.net.Socket;
import android.provider.Settings;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

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
    private static final int MAX_NFC_READ_ERRORS = 3;
    /** Pending "readNfc" call, null when no NFC session is open. */
    private volatile MethodChannel.Result nfcSessionResult;
    private volatile boolean nfcReading = false;
    private int nfcReadErrors = 0;

    private static final int OCR_REQUEST_CODE = 1001;
    private static final int BARCODE_REQUEST_CODE = 2002;
    private static final int MLKIT_SCANNER_REQUEST_CODE = 5555;



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

                                    // Start the NFC read process
                                    startNfcReading(result);
                                } else if (call.method.equals("cancelNfc")) {
                                    stopNfcReading();
                                    finishNfcSession(null, "CANCELLED", "NFC reading cancelled");
                                    result.success(null);
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

                                }else if (call.method.equals("startBarcodeScanner")) {
                                    if (barCodePendingResult != null) {
                                        result.error("ALREADY_ACTIVE", "A scan is already in progress", null);
                                        return;
                                    }
                                    barCodePendingResult = result;
                                    startBarcodeScanner();
                                }else if (call.method.equals("openBrowser")) {
                                    String url = call.argument("downloadUrl");
                                    openBrowser(url);
                                    result.success(null);
                                }else if (call.method.equals("getSimOperators")) {
                                    List<String> simOperators = getSimOperators();
                                    result.success(simOperators);
                                }else if (call.method.equals("startDocumentScanner")) {
                                    pendingResult = result;
                                    startDocumentScanner();
                                }
                            }
                        }
                );


        // Device key (Android Keystore) used to sign API requests
        new DeviceSecurityPlugin(getApplicationContext(), getFlutterEngine().getDartExecutor().getBinaryMessenger()).register();

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

        if (requestCode == MLKIT_SCANNER_REQUEST_CODE && pendingResult != null) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                GmsDocumentScanningResult scanResult = GmsDocumentScanningResult.fromActivityResultIntent(data);

                if (scanResult != null && scanResult.getPages() != null && !scanResult.getPages().isEmpty()) {
                    Uri imageUri = scanResult.getPages().get(0).getImageUri(); // Only one page

                    HashMap<String, Object> resultMap = new HashMap<>();
                    resultMap.put("imageUri", imageUri.toString());
                    pendingResult.success(resultMap);
                } else {
                    pendingResult.error("NO_RESULT", "Scan returned no pages", null);
                }
            } else {
                pendingResult.error("SCAN_CANCELLED", "User cancelled scan", null);
            }

            pendingResult = null;
        }


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

    private List<String> getSimOperators() {
        List<String> simOperators = new ArrayList<>();

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
            SubscriptionManager subscriptionManager = (SubscriptionManager) getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);

            if (subscriptionManager != null) {
                List<SubscriptionInfo> subscriptionInfoList = subscriptionManager.getActiveSubscriptionInfoList();
                if (subscriptionInfoList != null && !subscriptionInfoList.isEmpty()) {
                    for (SubscriptionInfo subscriptionInfo : subscriptionInfoList) {
                        int subscriptionId = subscriptionInfo.getSubscriptionId();
                        TelephonyManager telephonyManager = (TelephonyManager) getSystemService(Context.TELEPHONY_SERVICE);
                        TelephonyManager subscriptionTelephonyManager = telephonyManager.createForSubscriptionId(subscriptionId);

                        String operatorName = subscriptionTelephonyManager.getNetworkOperatorName();
                        if (operatorName != null && !operatorName.isEmpty()) {
                            simOperators.add(operatorName);
                        } else {
                            simOperators.add(null);
                        }
                    }
                }
            }
        } else {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.READ_PHONE_STATE}, 1);
        }

        return simOperators;
    }

    private void openBrowser(String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    private void startBarcodeScanner() {
        Intent intent = new Intent(this, BarcodeScannerActivity.class);
        startActivityForResult(intent, BARCODE_REQUEST_CODE);
    }

    private void startDocumentScanner() {
        GmsDocumentScannerOptions options =
                new GmsDocumentScannerOptions.Builder()
                        .setGalleryImportAllowed(false)
                        .setPageLimit(1)
                        .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                        .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_BASE)
                        .build();

        GmsDocumentScanner scanner = GmsDocumentScanning.getClient(options);

        scanner.getStartScanIntent(MainActivity.this)
                .addOnSuccessListener(intentSender -> {
                    try {
                        startIntentSenderForResult(intentSender, MLKIT_SCANNER_REQUEST_CODE, null, 0, 0, 0);
                    } catch (IntentSender.SendIntentException e) {
                        if (pendingResult != null) {
                            pendingResult.error("SEND_INTENT_FAILED", e.getMessage(), null);
                            pendingResult = null;
                        }
                    }
                })
                .addOnFailureListener(e -> {
                    if (pendingResult != null) {
                        pendingResult.error("SCAN_FAILED", e.getMessage(), null);
                        pendingResult = null;
                    }
                });
    }



    /**
     * One NFC session per "readNfc" call: the Flutter result stays pending until the
     * document is read, definitively refused or the session is cancelled. When the
     * card is moved away, the session keeps waiting for it: no need to rescan the MRZ.
     */
    private void startNfcReading(MethodChannel.Result result) {
        // A previous session still waiting (screen reopened): close it first
        finishNfcSession(null, "CANCELLED", "Replaced by a new NFC session");
        nfcSessionResult = result;
        nfcReadErrors = 0;
        nfcReading = false;
        enableNfcReaderMode();
    }

    private void enableNfcReaderMode() {
        if (nfcAdapter == null || nfcSessionResult == null) return;
        nfcAdapter.enableReaderMode(this, this::onNfcTagDiscovered,
                NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK | NfcAdapter.FLAG_READER_NFC_A | NfcAdapter.FLAG_READER_NFC_B, null);
    }

    private void stopNfcReading() {
        if (nfcAdapter != null) {
            nfcAdapter.disableReaderMode(this);
        }
    }

    /** Runs on the NFC thread: the whole chip read happens here. */
    private void onNfcTagDiscovered(Tag tag) {
        if (nfcSessionResult == null || nfcReading) return;
        IsoDep isoDep = IsoDep.get(tag);
        if (isoDep == null) return;

        nfcReading = true;
        sendNfcEvent("reading_started", null);
        Kameleon.readNFC(isoDep, (percent, step) -> {
            HashMap<String, Object> progress = new HashMap<>();
            progress.put("progress", percent);
            progress.put("step", step);
            sendNfcEvent("reading_progress", progress);
        }, new NFCResultCallback() {
            @Override
            public void onSuccess(JSONObject json) {
                stopNfcReading();
                finishNfcSession(json.toString(), null, null);
            }

            @Override
            public void onError(String code, String errorMessage, boolean retryable) {
                Log.w("MainActivity", "NFC read failed: " + code + " " + errorMessage);
                if (NFCResultCallback.READ_ERROR.equals(code) && ++nfcReadErrors >= MAX_NFC_READ_ERRORS) {
                    // The card stays on the phone but keeps failing: stop asking to present it again
                    retryable = false;
                    code = NFCResultCallback.NFC_READ_ERROR;
                }
                if (retryable) {
                    nfcReading = false;
                    HashMap<String, Object> event = new HashMap<>();
                    event.put("reason", code);
                    sendNfcEvent("reading_interrupted", event);
                } else {
                    stopNfcReading();
                    finishNfcSession(null, code, errorMessage);
                }
            }
        });
    }

    private void sendNfcEvent(String method, Object arguments) {
        runOnUiThread(() -> {
            if (getFlutterEngine() != null) {
                new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                        .invokeMethod(method, arguments);
            }
        });
    }

    /** Replies once to the pending "readNfc" call: [json] on success, otherwise the error [code]. */
    private void finishNfcSession(String json, String code, String message) {
        MethodChannel.Result result = nfcSessionResult;
        nfcSessionResult = null;
        nfcReading = false;
        if (result == null) return;
        runOnUiThread(() -> {
            if (json != null) {
                result.success(json);
            } else {
                result.error(code, message, null);
            }
        });
    }

    @Override
    protected void onPause() {
        super.onPause();
        stopNfcReading();
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Reader mode is dropped in onPause: resume a session that is still waiting for the card
        enableNfcReaderMode();
    }

    private boolean checkSecurity() {
        boolean isEmulator = isRunningOnEmulator();
        boolean isDebugger = isDebuggerAttached();
        boolean isRooted = isDeviceRooted();
        boolean isFrida = isFridaRunning();
        boolean isHooked = isHookingDetected();
        boolean isUsbDebug = isUsbDebuggingEnabled();

        return isEmulator || isDebugger || isRooted || isFrida || isHooked || isUsbDebug;
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

        // Check for Magisk
        if (isPackageInstalled("com.topjohnwu.magisk")) {
            return true;
        }

        return false;
    }

    private boolean isFridaRunning() {
        try {
            // Check for Frida's default port
            Socket socket = new Socket("localhost", 27042);
            socket.close();
            return true;
        } catch (Exception e) {
            // Port not open
        }

        // Check for Frida files in common locations
        String[] fridaFiles = {
                "frida-server",
                "re.frida.server",
                "frida-agent"
        };
        for (String file : fridaFiles) {
            if (new File("/data/local/tmp/" + file).exists()) return true;
        }

        // Check for frida-agent in maps
        try {
            BufferedReader reader = new BufferedReader(new FileReader("/proc/self/maps"));
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.toLowerCase().contains("frida-agent") || line.toLowerCase().contains("frida-server")) {
                    reader.close();
                    return true;
                }
            }
            reader.close();
        } catch (Exception e) {
            // Ignore
        }

        return false;
    }

    private boolean isHookingDetected() {
        try {
            throw new Exception("SecurityCheck");
        } catch (Exception e) {
            int zygoteInitCount = 0;
            for (StackTraceElement stackTraceElement : e.getStackTrace()) {
                if (stackTraceElement.getClassName().equals("com.android.internal.os.ZygoteInit")) {
                    zygoteInitCount++;
                    if (zygoteInitCount == 2) {
                        return true;
                    }
                }
                if (stackTraceElement.getClassName().equals("com.saurik.substrate.MSHookMethod") ||
                        stackTraceElement.getClassName().equals("de.robv.android.xposed.XposedBridge")) {
                    return true;
                }
            }
        }
        return false;
    }

    private boolean isUsbDebuggingEnabled() {
        return Settings.Global.getInt(getContentResolver(), Settings.Global.ADB_ENABLED, 0) != 0;
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
