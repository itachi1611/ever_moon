import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]?
    ) -> Bool {
        // Google Sign-In setup was removed with the FirebaseUI auth template
        // (plan 0002, C10). Phase 2 adds sign-in back with google_sign_in.
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
