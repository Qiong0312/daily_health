import Flutter
import UIKit

public class WidgetBridgePlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.dailyhealth/widget_bridge",
            binaryMessenger: registrar.messenger()
        )
        let instance = WidgetBridgePlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.observeWidgetDataChanges()
    }

    private func observeWidgetDataChanges() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let name = WidgetDataStore.dataChangedDarwinNotification
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let plugin = Unmanaged<WidgetBridgePlugin>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    plugin.channel?.invokeMethod("onWidgetDataChanged", arguments: nil)
                }
            },
            name,
            nil,
            .deliverImmediately
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "writeSnapshot":
            guard let json = call.arguments as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Expected JSON string", details: nil))
                return
            }
            do {
                try WidgetDataStore.writeRaw(json)
                WidgetDataStore.reloadTimelines()
                result(nil)
            } catch {
                result(FlutterError(code: "WRITE_FAILED", message: error.localizedDescription, details: nil))
            }
        case "readSnapshot":
            WidgetDataStore.clearStaleSnapshotIfNeeded()
            result(WidgetDataStore.readRaw())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
