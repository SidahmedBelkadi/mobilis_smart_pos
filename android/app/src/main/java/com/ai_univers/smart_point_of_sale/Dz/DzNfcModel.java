package com.ai_univers.smart_point_of_sale.Dz;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.nfc.tech.IsoDep;
import android.util.Log;

import com.ai_univers.smart_point_of_sale.utils.ImageUtil;

import net.sf.scuba.smartcards.CardService;

import org.jmrtd.BACKey;
import org.jmrtd.PassportService;
import org.jmrtd.lds.DisplayedImageInfo;
import org.jmrtd.lds.icao.DG11File;
import org.jmrtd.lds.icao.DG12File;
import org.jmrtd.lds.icao.DG1File;
import org.jmrtd.lds.icao.DG2File;
import org.jmrtd.lds.icao.DG7File;
import org.jmrtd.lds.icao.MRZInfo;
import org.jmrtd.lds.iso19794.FaceImageInfo;
import org.jmrtd.lds.iso19794.FaceInfo;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.List;
import java.util.Locale;

public class DzNfcModel {

    private final Context context;
    private final String documentType;
    private final String documentNumber;
    private final String dateOfBirth;
    private final String dateOfExpiry;
    private final boolean extractFacialImage;
    private final boolean extractSignature;

    public DzNfcModel(Context context, String documentType, String documentNumber, String dateOfBirth, String dateOfExpiry, boolean extractFacialImage, boolean extractSignature) {
        this.context = context;
        this.documentType = documentType;
        this.documentNumber = documentNumber;
        this.dateOfBirth = dateOfBirth;
        this.dateOfExpiry = dateOfExpiry;
        this.extractFacialImage = extractFacialImage;
        this.extractSignature = extractSignature;
    }

    public JSONObject readNfcData(IsoDep isoDep) throws Exception {
        CardService cardService = CardService.getInstance(isoDep);
        PassportService passportService = new PassportService(cardService, PassportService.NORMAL_MAX_TRANCEIVE_LENGTH, PassportService.DEFAULT_MAX_BLOCKSIZE, false, true);

        passportService.open();


        passportService.sendSelectApplet(false);


        String dateOfBirth = this.dateOfBirth;
        if (this.dateOfBirth.length() == 2) {
            dateOfBirth = this.dateOfBirth + "0101";
        }

        Log.d("DzNfcModel", "Received parameters: Document Type: " + documentType +
                ", Document Number: " + documentNumber +
                ", DOB: " + dateOfBirth +
                ", DOE: " + dateOfExpiry);


        BACKey bacKey = new BACKey(this.documentNumber, dateOfBirth, this.dateOfExpiry);
        passportService.doBAC(bacKey);


        JSONObject certificateJson = new JSONObject();

        InputStream dg1InputStream = passportService.getInputStream(PassportService.EF_DG1);
        DG1File dg1File = new DG1File(dg1InputStream);
        MRZInfo mrzInfo = dg1File.getMRZInfo();

        InputStream dg11InputStream = passportService.getInputStream(PassportService.EF_DG11);
        DG11File dg11File = new DG11File(dg11InputStream);

        InputStream dg12InputStream = passportService.getInputStream(PassportService.EF_DG12);
        DG12File dg12File = new DG12File(dg12InputStream);

        byte[] facialImageBytes = null;
        byte[] signatureImageBytes = null;
        Bitmap bitmap = null;

        if (extractFacialImage) {

            InputStream dg2InputStream = passportService.getInputStream(PassportService.EF_DG2);
            DG2File dg2File = new DG2File(dg2InputStream);
            List<FaceImageInfo> allFaceImageInfos = new ArrayList<>();
            List<FaceInfo> faceInfos = dg2File.getFaceInfos();
            for (FaceInfo faceInfo : faceInfos) {
                allFaceImageInfos.addAll(faceInfo.getFaceImageInfos());
            }

            if (!allFaceImageInfos.isEmpty()) {
                FaceImageInfo faceImageInfo = allFaceImageInfos.iterator().next();
                InputStream faceImageStream = faceImageInfo.getImageInputStream();
                String mimeType = faceImageInfo.getMimeType();


                if (faceImageStream != null) {
                    if (this.documentType.equals("passport")) {
                        bitmap = ImageUtil.decodeImage(context, mimeType, faceImageStream);
                    } else {
                        bitmap = BitmapFactory.decodeStream(faceImageStream);
                    }

                    if (bitmap != null) {
                        facialImageBytes = BitMapToByteArray(bitmap);

                    } else {

                    }
                } else {

                }
            } else {

            }
        }

        if (extractSignature) {

            InputStream dg7InputStream = passportService.getInputStream(PassportService.EF_DG7);
            DG7File dg7File = new DG7File(dg7InputStream);
            List<DisplayedImageInfo> displayedImages = dg7File.getImages();

            if (!displayedImages.isEmpty() && "image/jpeg".equals(displayedImages.get(0).getMimeType())) {
                signatureImageBytes = readBytes(displayedImages.get(0).getImageInputStream());

            } else {

            }
        }

        passportService.close();


        String rawLastName = mrzInfo.getPrimaryIdentifier();
        String rawFirstName = mrzInfo.getSecondaryIdentifier();
        String documentNum = mrzInfo.getDocumentNumber();
        String nationality = mrzInfo.getNationality();
        String issuingState = mrzInfo.getIssuingState();
        String birthDate = formatDate(mrzInfo.getDateOfBirth());
        String expiryDate = formatDate(mrzInfo.getDateOfExpiry());
        String gender = String.valueOf(mrzInfo.getGender());

        String firstName = cleanUpName(rawFirstName);
        String lastName = cleanUpName(rawLastName);
        String firstNameAr = "N/A";
        String lastNameAr = "N/A";
        if (!documentType.equals("passport")) {
            firstNameAr = dg11File.getNameOfHolder();
            lastNameAr = dg11File.getOtherNames() != null && !dg11File.getOtherNames().isEmpty() ? dg11File.getOtherNames().get(0) : "N/A";
        }
        String placeOfBirth = dg11File.getPlaceOfBirth() != null ? dg11File.getPlaceOfBirth().get(0) : "N/A";
        String personalNumber = dg11File.getPersonalNumber() != null ? dg11File.getPersonalNumber() : "N/A";
        String bloodGroup = this.documentType.equals("passport") ? dg11File.getCustodyInformation() != null ? dg11File.getCustodyInformation() : "N/A" : dg11File.getPermanentAddress().get(2) != null ? dg11File.getPermanentAddress().get(2) : "N/A";   // Blood Group
        String issuingAuthority = this.documentType.equals("passport") ? dg12File.getIssuingAuthority() : dg12File.getIssuingAuthority().split("<<")[0];
        String rawDateOfDelivery = dg12File.getDateOfIssue() != null ? dg12File.getDateOfIssue().toString() : "N/A";
        String formattedDateOfDelivery = formatDateOfDelivery(rawDateOfDelivery);

        JSONObject resultJson = new JSONObject();
        resultJson.put("document_type", this.documentType);
        resultJson.put("first_name", firstName);
        resultJson.put("last_name", lastName);
        resultJson.put("document_number", documentNum);
        resultJson.put("Nationality", nationality);
        if (birthDate.length() == 6) {
            birthDate = birthDate.replace("<", "");
            resultJson.put("date_of_birth", "19" + birthDate + "-01-01");
        } else {
            resultJson.put("date_of_birth", birthDate);
        }
        resultJson.put("gender", gender);
        resultJson.put("date_of_expiry", expiryDate);
        resultJson.put("place_of_birth", placeOfBirth);
        resultJson.put("personal_number", personalNumber);
        resultJson.put("issuing_state", issuingState);
        resultJson.put("blood_group", bloodGroup);
        resultJson.put("date_of_delivery", formattedDateOfDelivery);
        resultJson.put("issuing_authority", issuingAuthority);
        resultJson.put("facial_image", facialImageBytes != null ? new JSONArray(convertByteArrayToList(facialImageBytes)) : JSONObject.NULL);
        resultJson.put("signature_image", signatureImageBytes != null ? new JSONArray(convertByteArrayToList(signatureImageBytes)) : JSONObject.NULL);

        // Add the signer certificate details
        resultJson.put("certificate", certificateJson);


        return resultJson;
    }

    private String bytesToHex(byte[] bytes) {
        StringBuilder hexString = new StringBuilder();
        for (byte b : bytes) {
            String hex = Integer.toHexString(0xFF & b);
            if (hex.length() == 1) {
                hexString.append('0');
            }
            hexString.append(hex);
        }
        return hexString.toString().toUpperCase();
    }

    private String cleanUpName(String rawName) {
        return rawName.replace("<", " ").trim().replaceAll("\\s+", " ");
    }

    private String formatDate(String date) {
        SimpleDateFormat inputFormat = new SimpleDateFormat("yyMMdd", Locale.US);
        SimpleDateFormat outputFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.US);

        // Set a custom pivot year to start from 1921
        inputFormat.set2DigitYearStart(new GregorianCalendar(1924, Calendar.JANUARY, 1).getTime());

        try {
            Date parsedDate = inputFormat.parse(date);
            return outputFormat.format(parsedDate);
        } catch (Exception e) {
            e.printStackTrace();
            return date;
        }
    }


    private String formatDateOfDelivery(String date) {
        SimpleDateFormat inputFormat = new SimpleDateFormat("yyyyMMdd", Locale.US);
        SimpleDateFormat outputFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
        try {
            Date parsedDate = inputFormat.parse(date);
            return outputFormat.format(parsedDate);
        } catch (Exception e) {
            e.printStackTrace();
            return date;
        }
    }

    private byte[] BitMapToByteArray(Bitmap bitmap) {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, bos);
        return bos.toByteArray();
    }

    private List<Integer> convertByteArrayToList(byte[] byteArray) {
        List<Integer> list = new ArrayList<>();
        for (byte b : byteArray) {
            list.add((int) b & 0xFF);  // Convert each byte to its unsigned int value
        }
        return list;
    }

    private byte[] readBytes(InputStream inputStream) throws Exception {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int nRead;
        byte[] data = new byte[32768];
        while ((nRead = inputStream.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }
        buffer.flush();
        return buffer.toByteArray();
    }
}