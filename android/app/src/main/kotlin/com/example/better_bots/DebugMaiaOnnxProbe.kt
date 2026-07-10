package com.example.better_bots

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.os.SystemClock
import java.nio.FloatBuffer
import java.nio.LongBuffer
import kotlin.math.min

object DebugMaiaOnnxProbe {
    private const val MAIA3_MODEL_ASSET = "maia3/maia3-5m.onnx"

    fun runLoadOnlyProbe(context: Context) {
        DebugCrashStore.append(context, "MANUAL ONNX LOAD TEST: start")
        try {
            val start = SystemClock.elapsedRealtime()
            val env = OrtEnvironment.getEnvironment()
            DebugCrashStore.append(context, "MANUAL ONNX LOAD TEST: OrtEnvironment OK")

            val bytes = context.assets.open(MAIA3_MODEL_ASSET).use { it.readBytes() }
            DebugCrashStore.append(context, "MANUAL ONNX LOAD TEST: Asset geladen ${bytes.size} bytes")

            val opts = OrtSession.SessionOptions().apply {
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.BASIC_OPT)
            }

            DebugCrashStore.append(context, "MANUAL ONNX LOAD TEST: createSession start")
            val session = env.createSession(bytes, opts)
            DebugCrashStore.append(
                context,
                "MANUAL ONNX LOAD TEST: createSession OK nach ${SystemClock.elapsedRealtime() - start}ms",
            )
            DebugCrashStore.append(
                context,
                "MANUAL ONNX LOAD TEST: inputs=${session.inputNames.toList()}, outputs=${session.outputNames.toList()}",
            )

            session.close()
            opts.close()
            DebugCrashStore.append(context, "MANUAL ONNX LOAD TEST: SUCCESS total=${SystemClock.elapsedRealtime() - start}ms")
        } catch (error: Throwable) {
            DebugCrashStore.recordThrowable(context, "MANUAL ONNX LOAD TEST failed", error)
        }
    }

    fun runPolicyOnlyInferenceProbe(context: Context) {
        DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: start")
        DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: requested output = logits_move")

        var session: OrtSession? = null
        var opts: OrtSession.SessionOptions? = null
        var tokensTensor: OnnxTensor? = null
        var selfEloTensor: OnnxTensor? = null
        var oppoEloTensor: OnnxTensor? = null

        try {
            val totalStart = SystemClock.elapsedRealtime()
            val env = OrtEnvironment.getEnvironment()
            DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: OrtEnvironment OK")

            val bytes = context.assets.open(MAIA3_MODEL_ASSET).use { it.readBytes() }
            DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: Asset geladen ${bytes.size} bytes")

            opts = OrtSession.SessionOptions().apply {
                setOptimizationLevel(OrtSession.SessionOptions.OptLevel.NO_OPT)
                setExecutionMode(OrtSession.SessionOptions.ExecutionMode.SEQUENTIAL)
                setIntraOpNumThreads(1)
                setInterOpNumThreads(1)
                setMemoryPatternOptimization(false)
                setCPUArenaAllocator(false)
                addConfigEntry("session.intra_op.allow_spinning", "0")
                addConfigEntry("session.inter_op.allow_spinning", "0")
            }
            DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: SessionOptions OK")

            DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: createSession start")
            session = env.createSession(bytes, opts)
            DebugCrashStore.append(
                context,
                "MANUAL ONNX POLICY-LOGITS TEST: createSession OK nach ${SystemClock.elapsedRealtime() - totalStart}ms",
            )
            DebugCrashStore.append(
                context,
                "MANUAL ONNX POLICY-LOGITS TEST: inputs=${session.inputNames.toList()}, outputs=${session.outputNames.toList()}",
            )

            tokensTensor = OnnxTensor.createTensor(
                env,
                FloatBuffer.wrap(FloatArray(64 * 97) { 0.0f }),
                longArrayOf(1L, 64L, 97L),
            )
            selfEloTensor = OnnxTensor.createTensor(
                env,
                LongBuffer.wrap(longArrayOf(1200L)),
                longArrayOf(1L),
            )
            oppoEloTensor = OnnxTensor.createTensor(
                env,
                LongBuffer.wrap(longArrayOf(1200L)),
                longArrayOf(1L),
            )
            DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: tensors OK")

            val inputs = mapOf(
                "tokens" to tokensTensor,
                "self_elos" to selfEloTensor,
                "oppo_elos" to oppoEloTensor,
            )
            val requestedOutputs = linkedSetOf("logits_move")

            DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: session.run logits_move start")
            val runStart = SystemClock.elapsedRealtime()

            session.run(inputs, requestedOutputs).use { output ->
                DebugCrashStore.append(
                    context,
                    "MANUAL ONNX POLICY-LOGITS TEST: session.run RETURNED nach ${SystemClock.elapsedRealtime() - runStart}ms",
                )

                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: output count=${output.size()}")
                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: output[0].info=${output.get(0).info}")

                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: output[0].value extract start")
                val rawValue = output.get(0).value
                val logits = extractFloatVector(rawValue)
                DebugCrashStore.append(
                    context,
                    "MANUAL ONNX POLICY-LOGITS TEST: logits extracted length=${logits.size}",
                )

                val top = topIndices(logits, 10)
                    .map { index -> "$index=${String.format("%.4f", logits[index])}" }
                    .joinToString(", ")

                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: top10 raw logits: $top")
            }

            DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: SUCCESS total=${SystemClock.elapsedRealtime() - totalStart}ms")
        } catch (error: Throwable) {
            DebugCrashStore.recordThrowable(context, "MANUAL ONNX POLICY-LOGITS TEST failed", error)
        } finally {
            try {
                tokensTensor?.close()
                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: tokensTensor.close")
            } catch (_: Throwable) {
            }
            try {
                selfEloTensor?.close()
                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: selfEloTensor.close")
            } catch (_: Throwable) {
            }
            try {
                oppoEloTensor?.close()
                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: oppoEloTensor.close")
            } catch (_: Throwable) {
            }
            try {
                session?.close()
                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: session.close")
            } catch (_: Throwable) {
            }
            try {
                opts?.close()
                DebugCrashStore.append(context, "MANUAL ONNX POLICY-LOGITS TEST: options.close")
            } catch (_: Throwable) {
            }
        }
    }

    private fun extractFloatVector(rawValue: Any): FloatArray {
        return when (rawValue) {
            is FloatArray -> rawValue
            is Array<*> -> {
                val first = rawValue.firstOrNull()
                    ?: throw IllegalStateException("Leeres Array als ONNX-Output")
                when (first) {
                    is FloatArray -> first
                    is Array<*> -> {
                        val nestedFirst = first.firstOrNull()
                            ?: throw IllegalStateException("Leeres verschachteltes Array als ONNX-Output")
                        if (nestedFirst is FloatArray) {
                            nestedFirst
                        } else {
                            throw IllegalStateException(
                                "Unbekannter verschachtelter ONNX-Output-Typ: ${nestedFirst::class.java.name}",
                            )
                        }
                    }
                    else -> throw IllegalStateException(
                        "Unbekannter ONNX-Output-Array-Typ: ${first::class.java.name}",
                    )
                }
            }
            else -> throw IllegalStateException(
                "Unbekannter ONNX-Output-Typ: ${rawValue::class.java.name}",
            )
        }
    }

    private fun topIndices(values: FloatArray, count: Int): List<Int> {
        val topCount = min(count, values.size)
        val indices = MutableList(topCount) { -1 }
        val scores = FloatArray(topCount) { Float.NEGATIVE_INFINITY }

        for (i in values.indices) {
            val score = values[i]
            var insertAt = -1

            for (slot in 0 until topCount) {
                if (score > scores[slot]) {
                    insertAt = slot
                    break
                }
            }

            if (insertAt < 0) {
                continue
            }

            for (slot in topCount - 1 downTo insertAt + 1) {
                scores[slot] = scores[slot - 1]
                indices[slot] = indices[slot - 1]
            }

            scores[insertAt] = score
            indices[insertAt] = i
        }

        return indices.filter { it >= 0 }
    }
}
