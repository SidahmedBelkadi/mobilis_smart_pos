package com.ai_univers.smart_point_of_sale.vision;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Rect;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ExperimentalGetImage;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;


import com.ai_univers.smart_point_of_sale.R;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.concurrent.ExecutionException;


public class ScanActivity extends AppCompatActivity {

    private static final int CAMERA_PERMISSION_REQUEST_CODE = 100;

    private LiveTextRecognizer liveTextRecognizer;
    OverlayView overlayView;
    ProcessCameraProvider cameraProvider ;

    String documentType;

    @SuppressLint("MissingInflatedId")
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_scan_document);
        overlayView= findViewById(R.id.overlayView);
        documentType = getIntent().getStringExtra("documentType");
        liveTextRecognizer = new LiveTextRecognizer(this, documentType);

        Rect rect = overlayView.calculateRectangle(getResources().getDisplayMetrics().widthPixels, getResources().getDisplayMetrics().heightPixels);
        overlayView.setRect(rect, "");
        checkCameraPermission();
    }
    private void checkCameraPermission() {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA}, CAMERA_PERMISSION_REQUEST_CODE);
        } else {
            startCamera();
        }
    }



    private void startCamera() {
        ListenableFuture<ProcessCameraProvider> cameraProviderFuture = ProcessCameraProvider.getInstance(this);

        cameraProviderFuture.addListener(() -> {
            try {
                cameraProvider = cameraProviderFuture.get();
                bindPreview(cameraProvider);
            } catch (ExecutionException | InterruptedException e) {
                // Handle errors
            }
        }, ContextCompat.getMainExecutor(this));
    }

    private void bindPreview(@NonNull ProcessCameraProvider cameraProvider) {
        Preview preview = new Preview.Builder().build();
        CameraSelector cameraSelector = new CameraSelector.Builder().requireLensFacing(CameraSelector.LENS_FACING_BACK).build();

        ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST) // Drop older frames
                .setImageQueueDepth(1) // Keep only one image in the buffer
                .build();

        Camera camera = cameraProvider.bindToLifecycle(this, cameraSelector, imageAnalysis, preview);
        imageAnalysis.setAnalyzer(ContextCompat.getMainExecutor(this), liveTextRecognizer::processImage);


        PreviewView previewView = findViewById(R.id.previewView);
        preview.setSurfaceProvider(previewView.getSurfaceProvider());
    }
    public void returnResult(String documentNumber, String birthDate, String expiredDate) {
        Intent intent = new Intent();
        intent.putExtra("documentNumber", documentNumber);
        intent.putExtra("birthDate", birthDate);
        intent.putExtra("expiredDate", expiredDate);
        setResult(Activity.RESULT_OK, intent);
        finish(); // Close ScanActivity
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (cameraProvider != null) {
            cameraProvider.unbindAll();
        }
    }
    @Override
    protected void onPause() {
        super.onPause();
        if (cameraProvider != null) {
            cameraProvider.unbindAll();  // Release camera resources
        }
    }


}
