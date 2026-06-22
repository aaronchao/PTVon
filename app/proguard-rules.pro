# Keep kotlinx.serialization metadata for @Serializable DTOs.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class **$$serializer { *; }
-keep,includedescriptorclasses class com.ptvon.**$$serializer { *; }
-keepclassmembers class com.ptvon.** {
    *** Companion;
}
-keepclasseswithmembers class com.ptvon.** {
    kotlinx.serialization.KSerializer serializer(...);
}
