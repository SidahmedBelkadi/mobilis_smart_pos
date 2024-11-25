package com.ai_univers.smart_point_of_sale.vision;

import android.annotation.SuppressLint;
import android.util.Log;



import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.TextRecognizer;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;


import androidx.camera.core.ImageProxy;

import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class LiveTextRecognizer {

    private TextRecognizer recognizer;

    ScanActivity scanActivity;
    String documentType;
    public LiveTextRecognizer(ScanActivity scanActivity, String documentType) {
        recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
        this.scanActivity=scanActivity;
        this.documentType = documentType;
    }

    public void processImage(ImageProxy imageProxy) {
        try {
            Log.d("OCR", "Process Image ............");
            int rotationDegrees = imageProxy.getImageInfo().getRotationDegrees();
            @SuppressLint("UnsafeOptInUsageError")
            InputImage image = InputImage.fromMediaImage(
                    Objects.requireNonNull(imageProxy.getImage()),
                    rotationDegrees
            );

            recognizer.process(image)
                    .addOnSuccessListener(visionText -> {

                        if (visionText.getText().contains("P<DZA") && documentType.equals("passport")) {

                            processAlgerianPassport(visionText.getText());

                        } else if (visionText.getText().contains("IDDZA") && documentType.equals("id_card")) {
                            processAlgerianID(visionText.getText());

                        }
                    })
                    .addOnFailureListener(e -> {
                        Log.e("TextRecognition", "Failed to recognize text", e);
                    })
                    .addOnCompleteListener(task -> {
                        // Ensure closure of the ImageProxy in all cases
                        imageProxy.close();
                    });
        } catch (Exception e) {
            Log.e("processImage", "Error processing image", e);
            imageProxy.close();
        }
    }


    private void processAlgerianID(String text) {
        Log.d("OCR", "Process ID Card Image ............");

        // Clean the text
        text = text.replaceAll(" ", "").replaceAll("[^a-zA-Z0-9<]", "");

        // Line 1: Extract Document Number
        String documentNumberRegex = "IDDZA([0-9]{9})";
        Pattern documentNumberPattern = Pattern.compile(documentNumberRegex);
        Matcher documentNumberMatcher = documentNumberPattern.matcher(text);

        if (!documentNumberMatcher.find()) {
            Log.e("processAlgerianID", "Document Number not found");
            return;
        }

        String extractedDocumentNumber = documentNumberMatcher.group(1);
        Log.d("IDMrz", "Extracted Document Number: " + extractedDocumentNumber);

        // Line 2: Extract Birth Date, Expiry Date, and Gender
        String line2Regex = "([0-9<]{6})([0-9]{1})([MFX<]{1})([0-9]{6})";
        Pattern line2Pattern = Pattern.compile(line2Regex);
        Matcher line2Matcher = line2Pattern.matcher(text);

        if (line2Matcher.find()) {
            String birthDate = line2Matcher.group(1);  // Group 1: Birth Date (YYMMDD)
            String expiryDate = line2Matcher.group(4); // Group 4: Expiry Date (YYMMDD)
            String gender = line2Matcher.group(3);     // Group 3: Gender (M/F/X)

            // Log extracted details
            Log.d("IDMrz", "Birth Date: " + birthDate);
            Log.d("IDMrz", "Expiry Date: " + expiryDate);
            Log.d("IDMrz", "Gender: " + gender);

            // Return results to ScanActivity
            scanActivity.returnResult(extractedDocumentNumber, birthDate, expiryDate);
        } else {
            Log.e("processAlgerianID", "Line 2 information not found");
        }
    }


    private void processAlgerianPassport(String text) {
        // Clean the text
        text = text.replaceAll(" ", "").replaceAll("[^a-zA-Z0-9<]", "");

        // Regex for Passport MRZ
        String passportRegex = "([A-Z0-9]{9})([0-9])([A-Z]{3})(\\d{6}|\\d{2}<<<<)([0-9])([MF])([0-9]{6})([0-9])";
        Pattern passportPattern = Pattern.compile(passportRegex);
        Matcher passportMatcher = passportPattern.matcher(text);

        if (passportMatcher.find()) {
            String documentNumber = passportMatcher.group(1); // Group 1: Document Number
            String birthDate = passportMatcher.group(4);      // Group 4: Birth Date (YYMMDD)
            String expiryDate = passportMatcher.group(7);     // Group 7: Expiry Date (YYMMDD)

            // Log extracted details
            Log.d("PassportMrz", "Document Number: " + documentNumber);
            Log.d("PassportMrz", "Birth Date: " + birthDate);
            Log.d("PassportMrz", "Expiry Date: " + expiryDate);

            // Return results to ScanActivity
            scanActivity.returnResult(documentNumber, birthDate, expiryDate);
        } else {
            Log.e("processAlgerianPassport", "Passport MRZ data not found");
        }
    }



}