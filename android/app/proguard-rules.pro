# R8 keep rules for the release artifact.
#
# Flutter's embedding and the media3 ExoPlayer AAR ship their own consumer
# rules, so this file only covers what R8 cannot see: classes that are only
# ever reached by name at runtime.

# flutter_local_notifications deserialises NotificationDetails and the
# scheduled-notification payload with Gson, which resolves fields and the
# RuntimeTypeAdapterFactory subtype map reflectively. Without the keep, a
# scheduled prayer reminder fails after the build is minified even though the
# same code works in debug.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Gson's own reflection surface: generic signatures and the annotations that
# map JSON keys onto fields.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# The plugin reads the launcher icon and the notification channel metadata by
# name from the merged resources.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
