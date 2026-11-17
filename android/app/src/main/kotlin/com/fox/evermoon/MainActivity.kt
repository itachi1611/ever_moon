package com.fox.evermoon

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.fox.evermoon.bridge.BatteryApiBridge
import com.fox.evermoon.bridge.DeviceApiBridge
import com.fox.evermoon.generated.BatteryApi
import com.fox.evermoon.generated.DeviceApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        BatteryApi.setUp(messenger, BatteryApiBridge(applicationContext))
        DeviceApi.setUp(messenger, DeviceApiBridge())
        MethodChannel(messenger, SYSTEM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openExactAlarmSettings" -> {
                    openExactAlarmSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Opens the "Alarms & reminders" page of this app, so the user can review
     * or turn off the permission. permission_handler only opens it while the
     * permission is still off; older Android versions fall back to the app's
     * details page.
     */
    private fun openExactAlarmSettings() {
        val uri = Uri.parse("package:$packageName")
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, uri)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri)
        }
        try {
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri))
        }
    }

    private companion object {
        const val SYSTEM_CHANNEL = "com.fox.evermoon/system"
    }
}
