package com.example.better_bots

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.os.Bundle
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.FloatBuffer
import java.nio.LongBuffer
import kotlin.math.exp
import kotlin.random.Random

class MainActivity : FlutterActivity() {
    private var ortEnvironment: OrtEnvironment? = null
    private var maia3Session: OrtSession? = null
    private var maia3Options: OrtSession.SessionOptions? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        DebugCrashStore.install(application)
        DebugCrashStore.append(this, "MainActivity.onCreate")
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        DebugCrashStore.append(this, "MainActivity.configureFlutterEngine:start")
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MAIA3_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "maia3Init" -> {
                    DebugCrashStore.append(
                        this,
                        "maia3Init: policy-only bridge ready. ONNX session lazy-loaded on first move.",
                    )

                    result.success(
                        mapOf(
                            "status" to "policy_bridge_ready",
                            "model" to "maia3-5m",
                            "message" to "Maia3 Android Policy-Bridge bereit. ONNX wird beim ersten Zug geladen.",
                        ),
                    )
                }

                "maia3GetBestMove" -> runMaiaMoveInBackground(call, result)

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEBUG_CRASH_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "debugCrashLogGet" -> {
                    result.success(
                        mapOf(
                            "info" to "Nativer Log ist verfügbar. Für harte Start-Crashes nutze die zweite App-Verknüpfung: Better Bots Crash Log.",
                            "log" to DebugCrashStore.buildReport(this),
                        ),
                    )
                }

                "debugCrashLogClear" -> {
                    DebugCrashStore.clear(this)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        DebugCrashStore.append(this, "MainActivity.configureFlutterEngine:done")
    }

    private fun runMaiaMoveInBackground(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        Thread {
            try {
                val response = computeMaiaBestMove(call)

                runOnUiThread {
                    result.success(response)
                }
            } catch (error: Throwable) {
                DebugCrashStore.recordThrowable(this, "maia3GetBestMove failed", error)

                runOnUiThread {
                    result.error(
                        "MAIA3_ANDROID_POLICY_FAILED",
                        error.message ?: error.toString(),
                        null,
                    )
                }
            }
        }.start()
    }

    private fun computeMaiaBestMove(call: MethodCall): Map<String, Any?> {
        val totalStart = SystemClock.elapsedRealtime()

        val tokensList = call.argument<List<Number>>("tokens")
            ?: throw IllegalArgumentException("tokens fehlt")
        val legalIndexList = call.argument<List<Number>>("legalMoveIndices")
            ?: throw IllegalArgumentException("legalMoveIndices fehlt")
        val legalUciList = call.argument<List<String>>("legalMoveUcis")
            ?: throw IllegalArgumentException("legalMoveUcis fehlt")

        val elo = (call.argument<Number>("elo") ?: 1200).toLong()
        val temperature = (call.argument<Number>("temperature") ?: 1.0).toDouble()
        val topP = (call.argument<Number>("topP") ?: 0.95).toDouble()

        if (tokensList.size != 64 * 97) {
            throw IllegalArgumentException(
                "tokens hat Länge ${tokensList.size}, erwartet ${64 * 97}",
            )
        }

        if (legalIndexList.isEmpty()) {
            throw IllegalArgumentException("legalMoveIndices ist leer")
        }

        if (legalIndexList.size != legalUciList.size) {
            throw IllegalArgumentException(
                "legalMoveIndices (${legalIndexList.size}) und legalMoveUcis (${legalUciList.size}) passen nicht zusammen",
            )
        }

        DebugCrashStore.append(
            this,
            "maia3GetBestMove: policy-only start legal=${legalIndexList.size}, elo=$elo, temp=$temperature, topP=$topP",
        )

        val environment = ensureOrtEnvironment()
        val session = ensureMaia3Session(environment)

        val tokens = FloatArray(tokensList.size) { index ->
            tokensList[index].toFloat()
        }

        val tokensTensor = OnnxTensor.createTensor(
            environment,
            FloatBuffer.wrap(tokens),
            longArrayOf(1L, 64L, 97L),
        )
        val selfEloTensor = OnnxTensor.createTensor(
            environment,
            LongBuffer.wrap(longArrayOf(elo)),
            longArrayOf(1L),
        )
        val oppoEloTensor = OnnxTensor.createTensor(
            environment,
            LongBuffer.wrap(longArrayOf(elo)),
            longArrayOf(1L),
        )

        try {
            val inputs = mapOf(
                "tokens" to tokensTensor,
                "self_elos" to selfEloTensor,
                "oppo_elos" to oppoEloTensor,
            )

            DebugCrashStore.append(this, "maia3GetBestMove: session.run logits_move start")
            val runStart = SystemClock.elapsedRealtime()

            val logits = session.run(inputs, linkedSetOf("logits_move")).use { output ->
                DebugCrashStore.append(
                    this,
                    "maia3GetBestMove: session.run RETURNED nach ${SystemClock.elapsedRealtime() - runStart}ms",
                )

                extractFloatVector(output.get(0).value)
            }

            val candidates = buildLegalCandidates(
                logits = logits,
                legalIndexList = legalIndexList,
                legalUciList = legalUciList,
            )

            val selected = selectMove(
                candidates = candidates,
                temperature = temperature,
                topP = topP,
            )

            val topDebug = candidates
                .sortedByDescending { it.logit }
                .take(5)
                .joinToString(", ") {
                    "${it.uci}:${String.format("%.3f", it.logit)}"
                }

            DebugCrashStore.append(
                this,
                "maia3GetBestMove: selected=${selected.uci}, maiaIndex=${selected.index}, total=${SystemClock.elapsedRealtime() - totalStart}ms, top=$topDebug",
            )

            return mapOf(
                "bestMove" to selected.uci,
                "maiaIndex" to selected.index,
                "legalMoves" to legalIndexList.size,
                "elapsedMs" to (SystemClock.elapsedRealtime() - totalStart),
                "debug" to "legal=${legalIndexList.size}, ${SystemClock.elapsedRealtime() - totalStart}ms, top=$topDebug",
            )
        } finally {
            try {
                tokensTensor.close()
            } catch (_: Throwable) {
            }
            try {
                selfEloTensor.close()
            } catch (_: Throwable) {
            }
            try {
                oppoEloTensor.close()
            } catch (_: Throwable) {
            }
        }
    }

    @Synchronized
    private fun ensureOrtEnvironment(): OrtEnvironment {
        return ortEnvironment ?: OrtEnvironment.getEnvironment().also {
            ortEnvironment = it
            DebugCrashStore.append(this, "OrtEnvironment erstellt.")
        }
    }

    @Synchronized
    private fun ensureMaia3Session(environment: OrtEnvironment): OrtSession {
        maia3Session?.let {
            return it
        }

        val loadStart = SystemClock.elapsedRealtime()
        DebugCrashStore.append(this, "Maia3 ONNX Asset laden: $MAIA3_MODEL_ASSET")

        val modelBytes = assets.open(MAIA3_MODEL_ASSET).use { input ->
            input.readBytes()
        }

        DebugCrashStore.append(this, "Maia3 ONNX Asset geladen: ${modelBytes.size} bytes.")

        val options = OrtSession.SessionOptions().apply {
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.NO_OPT)
            setExecutionMode(OrtSession.SessionOptions.ExecutionMode.SEQUENTIAL)
            setIntraOpNumThreads(1)
            setInterOpNumThreads(1)
            setMemoryPatternOptimization(false)
            setCPUArenaAllocator(false)
            addConfigEntry("session.intra_op.allow_spinning", "0")
            addConfigEntry("session.inter_op.allow_spinning", "0")
        }

        maia3Options = options

        return environment.createSession(modelBytes, options).also {
            maia3Session = it
            DebugCrashStore.append(
                this,
                "Maia3 ONNX Session erstellt in ${SystemClock.elapsedRealtime() - loadStart}ms. inputs=${it.inputNames.toList()}, outputs=${it.outputNames.toList()}",
            )
        }
    }

    private fun buildLegalCandidates(
        logits: FloatArray,
        legalIndexList: List<Number>,
        legalUciList: List<String>,
    ): List<MoveCandidate> {
        val candidates = mutableListOf<MoveCandidate>()

        for (i in legalIndexList.indices) {
            val index = legalIndexList[i].toInt()

            if (index < 0 || index >= logits.size) {
                continue
            }

            candidates.add(
                MoveCandidate(
                    uci = legalUciList[i],
                    index = index,
                    logit = logits[index],
                ),
            )
        }

        if (candidates.isEmpty()) {
            throw IllegalStateException("Keine legalen Kandidaten nach Logit-Masking")
        }

        return candidates
    }

    private fun selectMove(
        candidates: List<MoveCandidate>,
        temperature: Double,
        topP: Double,
    ): MoveCandidate {
        if (temperature <= 0.0001 || candidates.size == 1) {
            return candidates.maxBy { it.logit }
        }

        val safeTemperature = temperature.coerceIn(0.05, 5.0)
        val maxScaled = candidates.maxOf { it.logit.toDouble() / safeTemperature }

        val scored = candidates.map { candidate ->
            val probability = exp(candidate.logit.toDouble() / safeTemperature - maxScaled)
            ScoredCandidate(candidate, probability)
        }.sortedByDescending { it.weight }

        val totalWeight = scored.sumOf { it.weight }

        val topPClamped = topP.coerceIn(0.01, 1.0)
        val filtered = mutableListOf<ScoredCandidate>()
        var cumulative = 0.0

        for (candidate in scored) {
            filtered.add(candidate)
            cumulative += candidate.weight

            if (cumulative / totalWeight >= topPClamped) {
                break
            }
        }

        val filteredTotal = filtered.sumOf { it.weight }
        var roll = Random.nextDouble() * filteredTotal

        for (candidate in filtered) {
            roll -= candidate.weight

            if (roll <= 0.0) {
                return candidate.move
            }
        }

        return filtered.last().move
    }

    private fun extractFloatVector(rawValue: Any?): FloatArray {
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
                "Unbekannter ONNX-Output-Typ: ${rawValue?.let { it::class.java.name } ?: "null"}",
            )
        }
    }

    data class MoveCandidate(
        val uci: String,
        val index: Int,
        val logit: Float,
    )

    data class ScoredCandidate(
        val move: MoveCandidate,
        val weight: Double,
    )

    companion object {
        private const val MAIA3_CHANNEL = "better_bots/maia3"
        private const val DEBUG_CRASH_CHANNEL = "better_bots/debugCrashLog"
        private const val MAIA3_MODEL_ASSET = "maia3/maia3-5m.onnx"
    }
}
