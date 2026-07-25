# Flutter and Android plugins ship their required consumer keep rules.
# Add project-specific rules here only after a verified release-build failure.

# Google Mobile Ads (AdMob) + User Messaging Platform (UMP).
# The release build runs R8 with minify + resource shrinking, and internal
# testing serves that release artifact. Ad/consent SDK startup crashes that
# only appear in release are typically R8 stripping reflectively-loaded classes,
# so keep the ad + consent SDK surface explicitly as a safeguard.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**
