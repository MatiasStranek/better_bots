package com.example.better_bots

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAIA3_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "maia3Init" -> {
                    val model = call.argument<String>("model") ?: "maia3-5m"

                    result.success(
                        mapOf(
                            "status" to "stub",
                            "model" to model,
                            "message" to "Maia3 Android Bridge ist vorbereitet. Native ONNX-Inferenz ist noch nicht eingebaut.",
                        ),
                    )
                }

                "maia3GetBestMove" -> {
                    result.error(
                        "MAIA3_ANDROID_NOT_READY",
                        "Maia-3 ist auf Android noch nicht nativ implementiert. Stockfish wird im Bot-Modus bewusst nicht als Ersatz verwendet.",
                        null,
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val MAIA3_CHANNEL = "better_bots/maia3"
    }
}
