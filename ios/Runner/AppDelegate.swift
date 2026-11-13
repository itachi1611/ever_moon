import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        // Google Sign-In setup was removed with the FirebaseUI auth template
        // (plan 0002, C10). Phase 2 adds sign-in back with google_sign_in.
        // Lets local reminders show as a banner while the app is open
        // (flutter_local_notifications needs the delegate set at launch).
        UNUserNotificationCenter.current().delegate = self
        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    func didInitializeImplicitFlutterEngine(
        _ engineBridge: FlutterImplicitEngineBridge
    ) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

        let messenger = engineBridge.applicationRegistrar.messenger()
        BatteryApiSetup.setUp(binaryMessenger: messenger, api: BatteryApiBridge())
        DeviceApiSetup.setUp(binaryMessenger: messenger, api: DeviceApiBridge())
    }
}
