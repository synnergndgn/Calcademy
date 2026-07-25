# Flutter and Android plugins ship their required consumer keep rules.
# Add project-specific rules here only after a verified release-build failure.

# --- AdMob Retry 1.0 -----------------------------------------------------------
# Google Mobile Ads (AdMob) + User Messaging Platform (UMP). The release build
# runs R8 with minify + resource shrinking and internal testing serves that
# release artifact, so ad SDK surface is kept explicitly.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.ump.**

# AndroidX Room / WorkManager reflective instantiation.
#
# Verified failure (1.0.0+6, release AAB on device):
#   Unable to get provider androidx.startup.InitializationProvider
#     Caused by: com.google.android.gms.internal.ads...
#     Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
#
# play-services-ads pulls in WorkManager, whose AndroidX Startup initializer
# builds a Room database during process start -- before Dart main() runs, so no
# Dart-side guard can catch it. Room looks up the generated `<Database>_Impl`
# class *and its no-arg constructor* reflectively; "Failed to create an instance
# of" specifically means the class was found but the constructor was not. R8
# full mode must therefore keep the constructor, not just the class.
-keep class * extends androidx.room.RoomDatabase { <init>(); }

# AndroidX Startup initializers are named as manifest meta-data strings and
# instantiated reflectively by InitializationProvider.
-keep class * implements androidx.startup.Initializer { <init>(); }
