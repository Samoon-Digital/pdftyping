## Keep JNI entry points reachable after R8 obfuscation.
-keepclasseswithmembernames class * {
    native <methods>;
}

## Preserve metadata commonly used by generated/plugin code and platform APIs.
-keepattributes RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations,AnnotationDefault
-keepattributes Signature,InnerClasses,EnclosingMethod
