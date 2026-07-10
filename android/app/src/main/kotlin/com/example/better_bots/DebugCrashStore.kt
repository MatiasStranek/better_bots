package com.example.better_bots

import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.system.exitProcess

object DebugCrashStore {
    private const val PREFS_NAME = "better_bots_native_crash_meta"
    private const val KEY_LAST_CRASH_AT = "last_crash_at"
    private const val MAX_CHARS = 120000
    private const val LOG_FILE_NAME = "better_bots_native_crash_log.txt"

    @Volatile
    private var installed = false

    fun install(application: Application) {
        if (installed) {
            return
        }

        installed = true

        val processName = currentProcessName(application)
        append(application, "DebugCrashStore.install process=$processName")

        val previousHandler = Thread.getDefaultUncaughtExceptionHandler()
        val isCrashLogProcess = processName.endsWith(":crashlog")

        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            recordThrowable(application, "UNCAUGHT thread=${thread.name}", throwable)

            if (!isCrashLogProcess) {
                tryLaunchCrashActivity(application)
            }

            try {
                Thread.sleep(900)
            } catch (_: InterruptedException) {
            }

            if (previousHandler != null && isCrashLogProcess) {
                previousHandler.uncaughtException(thread, throwable)
            } else {
                Process.killProcess(Process.myPid())
                exitProcess(10)
            }
        }
    }

    @Synchronized
    fun append(context: Context, message: String) {
        val newEntry = "[${timestamp()}] $message"
        val oldLog = read(context)
        val combined = "$oldLog\n$newEntry".takeLast(MAX_CHARS)

        try {
            logFile(context).writeText(combined)
        } catch (_: Throwable) {
            // Crash-Logging darf nie selbst die App abstürzen lassen.
        }
    }

    fun recordThrowable(context: Context, title: String, throwable: Throwable) {
        val writer = StringWriter()
        throwable.printStackTrace(PrintWriter(writer))

        try {
            prefs(context)
                .edit()
                .putLong(KEY_LAST_CRASH_AT, System.currentTimeMillis())
                .apply()
        } catch (_: Throwable) {
        }

        append(context, "$title\n${writer.toString()}")
    }

    @Synchronized
    fun read(context: Context): String {
        return try {
            val file = logFile(context)
            if (file.exists()) {
                file.readText()
            } else {
                ""
            }
        } catch (_: Throwable) {
            ""
        }
    }

    @Synchronized
    fun clear(context: Context) {
        try {
            logFile(context).delete()
        } catch (_: Throwable) {
        }

        try {
            prefs(context)
                .edit()
                .remove(KEY_LAST_CRASH_AT)
                .apply()
        } catch (_: Throwable) {
        }

        append(context, "Native Crash-Log geleert.")
    }

    fun buildReport(context: Context): String {
        val lastCrashAt = try {
            prefs(context).getLong(KEY_LAST_CRASH_AT, 0L)
        } catch (_: Throwable) {
            0L
        }

        val lastCrashText =
            if (lastCrashAt > 0L) timestamp(lastCrashAt) else "kein gespeicherter Fatal-Crash"

        return buildString {
            appendLine("Better Bots Native Crash Report")
            appendLine("generated: ${timestamp()}")
            appendLine("package: ${context.packageName}")
            appendLine("process: ${currentProcessName(context)}")
            appendLine("android sdk: ${Build.VERSION.SDK_INT}")
            appendLine("device: ${Build.MANUFACTURER} ${Build.MODEL}")
            appendLine("last fatal crash: $lastCrashText")
            appendLine("log file: ${logFile(context).absolutePath}")
            appendLine("")
            appendLine("Native Log")
            appendLine("------------------------------")
            val log = read(context).trim()
            if (log.isEmpty()) {
                appendLine("Kein nativer Log gespeichert.")
            } else {
                appendLine(log)
            }
        }
    }

    fun tryLaunchMainActivity(context: Context) {
        append(context, "DebugCrashLogActivity: App starten gedrückt.")

        try {
            val intent = Intent().apply {
                setClassName(context.packageName, "${context.packageName}.MainActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(intent)
            append(context, "MainActivity Start-Intent gesendet.")
        } catch (error: Throwable) {
            recordThrowable(context, "MainActivity konnte nicht gestartet werden", error)
        }
    }

    fun tryLaunchCrashActivity(context: Context) {
        try {
            val intent = Intent(context, DebugCrashLogActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra(DebugCrashLogActivity.EXTRA_AUTO_OPENED_AFTER_CRASH, true)
            }
            context.startActivity(intent)
            append(context, "DebugCrashLogActivity nach Crash gestartet.")
        } catch (error: Throwable) {
            recordThrowable(context, "CrashActivity konnte nicht gestartet werden", error)
        }
    }

    private fun logFile(context: Context): File {
        return File(context.applicationContext.filesDir, LOG_FILE_NAME)
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun timestamp(timeMillis: Long = System.currentTimeMillis()): String {
        return SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(Date(timeMillis))
    }

    private fun currentProcessName(context: Context): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            Application.getProcessName()
        } else {
            context.packageName
        }
    }
}
