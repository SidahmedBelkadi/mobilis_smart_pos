package com.ai_univers.smart_point_of_sale.Dz;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.nfc.tech.IsoDep;
import android.util.Log;

import com.ai_univers.smart_point_of_sale.Reader.ActiveAuthentication;
import com.ai_univers.smart_point_of_sale.Reader.BacFailedException;
import com.ai_univers.smart_point_of_sale.Reader.DzNfcReaderImpl;
import com.ai_univers.smart_point_of_sale.Reader.NfcDiagnostics;
import com.ai_univers.smart_point_of_sale.Reader.NfcProgressListener;
import com.ai_univers.smart_point_of_sale.utils.ImageUtil;
import com.google.android.datatransport.runtime.logging.Logging;

import net.sf.scuba.smartcards.CardFileInputStream;
import net.sf.scuba.smartcards.CardService;
import net.sf.scuba.smartcards.CardServiceException;

import org.jmrtd.BACKey;
import org.jmrtd.PassportService;
import org.jmrtd.lds.DisplayedImageInfo;
import org.jmrtd.lds.SODFile;
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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class DzNfcModel {

    private final Context context;
    private final String documentType;
    private final String documentNumber;
    private final String dateOfBirth;
    private final String dateOfExpiry;
    private final boolean extractFacialImage;
    private final boolean extractSignature;

    private static final int ISO_DEP_TIMEOUT_MS = 5000;

    /** Files fully read during a previous attempt on the same document (see readFile). */
    private final Map<Short, byte[]> fileCache = new HashMap<>();

    public DzNfcModel(Context context, String documentType, String documentNumber, String dateOfBirth, String dateOfExpiry, boolean extractFacialImage, boolean extractSignature) {
        this.context = context;
        this.documentType = documentType;
        this.documentNumber = documentNumber;
        this.dateOfBirth = dateOfBirth;
        this.dateOfExpiry = dateOfExpiry;
        this.extractFacialImage = extractFacialImage;
        this.extractSignature = extractSignature;
    }

    public JSONObject readNfcData(IsoDep isoDep, NfcProgressListener progressListener) throws Exception {
        Progress progress = new Progress(progressListener);
        progress.report(2, NfcProgressListener.STEP_AUTH);

        NfcDiagnostics diagnostics = new NfcDiagnostics(context, documentType);
        diagnostics.logTag(isoDep);

        CardService cardService = CardService.getInstance(isoDep);
        PassportService passportService = new PassportService(cardService, PassportService.NORMAL_MAX_TRANCEIVE_LENGTH, PassportService.DEFAULT_MAX_BLOCKSIZE, false, true);

        String dateOfBirth = this.dateOfBirth;
        if (this.dateOfBirth.length() == 2) {
            dateOfBirth = this.dateOfBirth + "0101";
        }
        BACKey bacKey = new BACKey(this.documentNumber, dateOfBirth, this.dateOfExpiry);

        passportService.open();
        // Active Authentication makes the chip compute an RSA signature: give it time
        try {
            isoDep.setTimeout(ISO_DEP_TIMEOUT_MS);
        } catch (Exception ignored) {
        }

        // Debug builds only: probes EF.CardAccess and tries PACE before falling back to BAC
        boolean paceUsed = diagnostics.probeCardAccessAndPace(passportService, bacKey);

        passportService.sendSelectApplet(paceUsed);
        if (!paceUsed) {
            try {
                passportService.doBAC(bacKey);
            } catch (CardServiceException e) {
                // The card answered but refused the keys: the MRZ does not match this document
                if (!DzNfcReaderImpl.isTagLost(e, isoDep)) {
                    throw new BacFailedException(e);
                }
                throw e;
            }
        }
        diagnostics.logAccessControl(paceUsed);
        progress.report(10, NfcProgressListener.STEP_READ);


        JSONObject certificateJson = new JSONObject();

        // Keep the raw bytes: EF.SOD hashes must be computed on them, not on a re-encoding
        byte[] dg1Bytes = readFile(passportService, PassportService.EF_DG1, progress, 10, 20);
        DG1File dg1File = new DG1File(new ByteArrayInputStream(dg1Bytes));
        MRZInfo mrzInfo = dg1File.getMRZInfo();

        byte[] dg11Bytes = readFile(passportService, PassportService.EF_DG11, progress, 20, 45);
        DG11File dg11File = new DG11File(new ByteArrayInputStream(dg11Bytes));

        byte[] dg12Bytes = readFile(passportService, PassportService.EF_DG12, progress, 45, 60);
        DG12File dg12File = new DG12File(new ByteArrayInputStream(dg12Bytes));

        SODFile sod = new SODFile(new ByteArrayInputStream(readFile(passportService, PassportService.EF_SOD, progress, 60, 78)));

        // Rejects cloned and emulated chips: the chip on the phone right now must sign
        // a fresh random challenge (never skipped, even when the files come from the cache)
        byte[] dg15Bytes = readFile(passportService, PassportService.EF_DG15, progress, 78, 85);
        progress.report(85, NfcProgressListener.STEP_VERIFY);
        ActiveAuthentication.verify(passportService, sod, dg15Bytes);
        progress.report(95, NfcProgressListener.STEP_VERIFY);

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

        if (diagnostics.isEnabled()) {
            Map<Integer, byte[]> readDataGroups = new LinkedHashMap<>();
            readDataGroups.put(1, dg1Bytes);
            readDataGroups.put(11, dg11Bytes);
            readDataGroups.put(12, dg12Bytes);
            // Last step before close(): Chip Authentication replaces the secure messaging session
            diagnostics.inspectSecurity(passportService, readDataGroups);
        }

        passportService.close();

        String rawLastName = mrzInfo.getPrimaryIdentifier();
        String rawFirstName = mrzInfo.getSecondaryIdentifier();
        String documentNum = mrzInfo.getDocumentNumber();
        String nationality = mrzInfo.getNationality();
        String issuingState = mrzInfo.getIssuingState();
        String birthDate = dg11File.getFullDateOfBirth();
        Log.d("DATE_FORMAT", formatDateOfBirth("2006"));
        String expiryDate = mrzInfo.getDateOfExpiry();
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
        String formattedDateOfDelivery = formatDate(rawDateOfDelivery);

        JSONObject resultJson = new JSONObject();
        resultJson.put("document_type", this.documentType);
        resultJson.put("first_name", firstName);
        resultJson.put("last_name", lastName);
        resultJson.put("document_number", documentNum);
        resultJson.put("Nationality", nationality);
        resultJson.put("date_of_birth", birthDate);
        resultJson.put("gender", gender);
        resultJson.put("date_of_expiry", expiryDate);
        resultJson.put("place_of_birth", placeOfBirth);
        resultJson.put("personal_number", personalNumber);
        resultJson.put("issuing_state", issuingState);
        resultJson.put("blood_group", bloodGroup);
        resultJson.put("date_of_delivery", formattedDateOfDelivery);
        resultJson.put("issuing_authority", issuingAuthority.substring(dg12File.getIssuingAuthority().indexOf("_") + 1));
        resultJson.put("facial_image", facialImageBytes != null ? new JSONArray(convertByteArrayToList(facialImageBytes)) : JSONObject.NULL);
        resultJson.put("signature_image", signatureImageBytes != null ? new JSONArray(convertByteArrayToList(signatureImageBytes)) : JSONObject.NULL);

        // Add the signer certificate details
        resultJson.put("certificate", certificateJson);

        progress.report(100, NfcProgressListener.STEP_VERIFY);
        return resultJson;
    }

    /**
     * Reads a whole elementary file, reporting progress between [from] and [to].
     *
     * Complete files are kept for the next attempt, so after a lost connection only
     * the missing part is read again. This is safe: BAC with the same MRZ already
     * proves it is the same document, and Active Authentication is always redone live.
     */
    private byte[] readFile(PassportService service, short fid, Progress progress, int from, int to) throws Exception {
        byte[] cached = fileCache.get(fid);
        if (cached != null) {
            progress.report(to, NfcProgressListener.STEP_READ);
            return cached;
        }

        CardFileInputStream in = service.getInputStream(fid);
        int length = Math.max(in.getLength(), 1);
        ByteArrayOutputStream buffer = new ByteArrayOutputStream(length);
        byte[] data = new byte[1024];
        int nRead;
        while ((nRead = in.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
            progress.report(from + (to - from) * Math.min(buffer.size(), length) / length, NfcProgressListener.STEP_READ);
        }
        byte[] bytes = buffer.toByteArray();
        fileCache.put(fid, bytes);
        return bytes;
    }

    /** Forwards progress only when it moves forward, to keep the UI updates light. */
    private static final class Progress {
        private final NfcProgressListener listener;
        private int last = -1;
        private String lastStep;

        Progress(NfcProgressListener listener) {
            this.listener = listener;
        }

        void report(int percent, String step) {
            if (listener == null || (percent <= last && step.equals(lastStep))) return;
            last = Math.max(last, percent);
            lastStep = step;
            listener.onProgress(last, step);
        }
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

    private String formatDateOfBirth(String date) {
        SimpleDateFormat outputFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.US);

        try {
            String normalizedDate = normalizeDate(date);
            SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.US);
            Date parsedDate = inputFormat.parse(normalizedDate);
            return outputFormat.format(parsedDate);
        } catch (Exception e) {
            e.printStackTrace();
            return date; // Return the original input if parsing fails
        }
    }

    private String normalizeDate(String date) {
        String year = date.substring(0, 4); // Always take the first 4 characters as year
        String month = "01";               // Default month
        String day = "01";                 // Default day

        if (date.length() >= 6) {
            String monthPart = date.substring(4, 6);
            if (isNumeric(monthPart)) {
                month = String.format("%02d", Integer.parseInt(monthPart)); // Ensure 2 digits
            }
        }

        if (date.length() == 8) {
            String dayPart = date.substring(6, 8);
            if (isNumeric(dayPart)) {
                day = String.format("%02d", Integer.parseInt(dayPart)); // Ensure 2 digits
            }
        }

        return year + "-" + month + "-" + day;
    }

    private boolean isNumeric(String str) {
        try {
            Integer.parseInt(str);
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }



    private String formatDate(String date) {
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