package com.fox.evermoon

import com.fox.evermoon.bridge.BatteryApiBridge
import com.fox.evermoon.bridge.DeviceApiBridge
import com.fox.evermoon.generated.BatteryApi
import com.fox.evermoon.generated.DeviceApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        BatteryApi.setUp(messenger, BatteryApiBridge(applicationContext))
        DeviceApi.setUp(messenger, DeviceApiBridge())
    }
}
