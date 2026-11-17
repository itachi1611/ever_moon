package com.fox.evermoon

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Re-arms the reminders when the phone's time zone changes.
 *
 * Reminders are stored as wall-clock times, so the alarms already set are at
 * the wrong instants after a zone change. The receiver starts a headless
 * Flutter engine that runs the same Dart sync as the rest of the app, then
 * destroys the engine. A time limit keeps the broadcast from being held open.
 */
class TimeZoneChangedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_TIMEZONE_CHANGED) return
        val pending = goAsync()
        val app = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(app)
        loader.ensureInitializationCompleteAsync(app, null, Handler(Looper.getMainLooper())) {
            runDartSync(app, loader.findAppBundlePath(), pending)
        }
    }

    private fun runDartSync(
        app: Context,
        bundlePath: String,
        pending: PendingResult,
    ) {
        val engine = FlutterEngine(app)
        val handler = Handler(Looper.getMainLooper())
        var finished = false
        lateinit var timeout: Runnable
        val finish = {
            if (!finished) {
                finished = true
                handler.removeCallbacks(timeout)
                engine.destroy()
                pending.finish()
            }
        }
        timeout = Runnable {
            Log.w(TAG, "Reminder resync timed out")
            finish()
        }
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "done") finish()
            result.success(null)
        }
        // A debug engine needs about 5 s to start and 3 s to sync; destroying
        // the engine earlier breaks the plugins mid-call. A background
        // broadcast may be held for up to a minute.
        handler.postDelayed(timeout, TIMEOUT_MS)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(bundlePath, LIBRARY, ENTRYPOINT),
        )
    }

    private companion object {
        const val TAG = "EvermoonZoneReceiver"
        const val CHANNEL = "com.fox.evermoon/resync"
        const val LIBRARY = "package:ever_moon/main.dart"
        const val ENTRYPOINT = "resyncRemindersAfterZoneChange"
        const val TIMEOUT_MS = 20000L
    }
}
