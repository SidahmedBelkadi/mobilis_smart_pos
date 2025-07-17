-keep,allowoptimization class net.sf.scuba.** { *; }
-keep,allowoptimization class org.bouncycastle.** { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_barcode_scanning.** { *; }

# Keep only non-desktop parts of your JAR dependencies
-keep class org.jmrtd.** {
    *;
}
-keep class jj2000.** {
    *;
}
-keep class org.jnbis.** {
    *;
}

# Remove/ignore ALL desktop Java classes
-dontwarn java.awt.**
-dontwarn javax.swing.**
-dontwarn javax.imageio.**
-dontwarn javax.naming.**
-dontwarn java.applet.**
-dontwarn jj2000.disp.**
-dontwarn org.jnbis.imageio.**
-dontwarn org.jmrtd.imageio.**

# Remove desktop-specific classes entirely
-assumenosideeffects class jj2000.disp.** { *; }
-assumenosideeffects class java.awt.** { *; }
-assumenosideeffects class java.applet.** { *; }