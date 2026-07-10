package com.example.better_bots

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class DebugCrashLogActivity : Activity() {
    private lateinit var logTextView: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DebugCrashStore.append(this, "DebugCrashLogActivity.onCreate")
        buildUi()
        refreshLog()
        if (intent?.getBooleanExtra(EXTRA_AUTO_OPENED_AFTER_CRASH, false) == true) {
            Toast.makeText(this, "Better Bots ist abgestürzt. Crash-Log kann kopiert werden.", Toast.LENGTH_LONG).show()
        }
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.rgb(16, 16, 20))
            setPadding(dp(16), dp(16), dp(16), dp(16))
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
        }

        root.addView(TextView(this).apply {
            text = "Better Bots Crash Log"
            setTextColor(Color.WHITE)
            textSize = 22f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        })

        root.addView(TextView(this).apply {
            text = "Policy Only testet nur logits_move. Das umgeht Value/Ponder-Ausgaben und prüft R8/JNI-Klassen."
            setTextColor(Color.LTGRAY)
            textSize = 14f
            setPadding(0, dp(8), 0, dp(12))
        })

        logTextView = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 11f
            typeface = android.graphics.Typeface.MONOSPACE
            setTextIsSelectable(true)
            setPadding(dp(12), dp(12), dp(12), dp(12))
        }

        val scroll = ScrollView(this).apply {
            setBackgroundColor(Color.BLACK)
            addView(logTextView, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        }

        root.addView(scroll, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))

        root.addView(row(
            button("Kopieren") { copyLog() },
            button("Aktualisieren") { refreshLog() },
        ))

        root.addView(row(
            button("Leeren") { DebugCrashStore.clear(this); refreshLog() },
            button("Load Test") {
                runProbeInBackground("Load Test") {
                    DebugMaiaOnnxProbe.runLoadOnlyProbe(applicationContext)
                }
            },
        ))

        root.addView(row(
            button("Policy Only") {
                runProbeInBackground("Policy Only") {
                    DebugMaiaOnnxProbe.runPolicyOnlyInferenceProbe(applicationContext)
                }
            },
            button("App starten") {
                DebugCrashStore.tryLaunchMainActivity(this)
                Toast.makeText(this, "Better Bots Start wurde ausgelöst.", Toast.LENGTH_SHORT).show()
            },
        ))

        setContentView(root)
    }

    private fun row(left: Button, right: Button): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(10), 0, 0)
            addView(left, LinearLayout.LayoutParams(0, dp(48), 1f))
            addView(TextView(this@DebugCrashLogActivity).apply { width = dp(10) })
            addView(right, LinearLayout.LayoutParams(0, dp(48), 1f))
        }
    }

    private fun runProbeInBackground(label: String, action: () -> Unit) {
        Toast.makeText(this, "$label gestartet. Bitte warten.", Toast.LENGTH_SHORT).show()
        DebugCrashStore.append(this, "$label: background thread launch")

        Thread {
            DebugCrashStore.append(applicationContext, "$label: background thread start")
            action()
            DebugCrashStore.append(applicationContext, "$label: background thread done")
            runOnUiThread {
                refreshLog()
                Toast.makeText(this, "$label fertig. Log aktualisiert.", Toast.LENGTH_SHORT).show()
            }
        }.start()
    }

    private fun refreshLog() {
        logTextView.text = DebugCrashStore.buildReport(this)
    }

    private fun copyLog() {
        val report = DebugCrashStore.buildReport(this)
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(ClipData.newPlainText("Better Bots Crash Log", report))
        Toast.makeText(this, "Crash-Log kopiert.", Toast.LENGTH_SHORT).show()
    }

    private fun button(text: String, onClick: () -> Unit): Button {
        return Button(this).apply {
            this.text = text
            setAllCaps(false)
            setOnClickListener { onClick() }
        }
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    companion object {
        const val EXTRA_AUTO_OPENED_AFTER_CRASH = "com.example.better_bots.EXTRA_AUTO_OPENED_AFTER_CRASH"
    }
}
