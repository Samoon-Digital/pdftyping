## Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Dart/Flutter embedding
-keep class io.flutter.embedding.** { *; }

## Play Core (Flutter deferred components — not used, suppress missing-class warnings)
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.**

## Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

## Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

## Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

## AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

## url_launcher
-keep class android.content.Intent { *; }

## PDF / Printing plugin
-keep class com.pdfviewer.** { *; }
-dontwarn com.pdfviewer.**

## Syncfusion PDF Viewer
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

## WebView (used by some plugins)
-keep class android.webkit.** { *; }

## Device Info Plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

## Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

## path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

## General: keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

## General: keep serialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

## Prevent R8 from removing native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
