# ONNX Runtime Java/JNI uses fixed Java class and method names from native code.
# Keep all ORT Java classes and members untouched if any build variant enables R8.
-keep class ai.onnxruntime.** { *; }
-keep enum ai.onnxruntime.** { *; }
-keep interface ai.onnxruntime.** { *; }
-keepclassmembers class ai.onnxruntime.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
-dontwarn ai.onnxruntime.**
