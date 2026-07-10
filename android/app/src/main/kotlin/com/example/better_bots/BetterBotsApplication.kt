package com.example.better_bots

import io.flutter.app.FlutterApplication

class BetterBotsApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        DebugCrashStore.install(this)
        DebugCrashStore.append(this, "BetterBotsApplication.onCreate")
    }
}
