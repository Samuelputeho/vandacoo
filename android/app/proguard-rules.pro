-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.**
-keep class com.google.android.gms.** { *; }

# Keep generic types for Stripe
-keepattributes Signature
-keepattributes *Annotation*

# Keep JavaScript interface methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep Stripe model classes
-keep class com.stripe.android.model.** { *; }
-keep class com.stripe.android.view.** { *; }

# Keep PaymentConfiguration
-keep class com.stripe.android.PaymentConfiguration { *; } 