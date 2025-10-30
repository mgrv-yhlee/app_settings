@preconcurrency import Flutter
import UIKit
import StoreKit

public class AppSettingsPlugin: NSObject, @preconcurrency FlutterPlugin, UIWindowSceneDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.spencerccf.app_settings/methods", binaryMessenger: registrar.messenger())
        let instance = AppSettingsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method) {
        case "openSettings":
            DispatchQueue.main.async {
                self.handleOpenSettings(call: call, result: result)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Handle the 'openSettings' method call.
    private func handleOpenSettings(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as! Dictionary<String, Any?>
        let type = arguments["type"] as! String

        switch(type) {
        case "notification":
            if #available(iOS 16.0, *) {
                openSettings(settingsUrl: UIApplication.openNotificationSettingsURLString)
            } else if #available(iOS 15.4, *) {
                openSettings(settingsUrl: UIApplicationOpenNotificationSettingsURLString)
            } else {
                openSettings(settingsUrl: UIApplication.openSettingsURLString)
            }
            result(nil)
            break
        case "subscriptions":
            if #available(iOS 15.0, *) {
                Task { @MainActor [weak self] in
                    guard let self = self else {
                        result(FlutterError(code: "app_settings", message: "Plugin deallocated", details: nil))
                        return
                    }

                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        await self.openSubscriptionSettings(windowScene)
                    } else {
                        self.openSettings(settingsUrl: UIApplication.openSettingsURLString)
                    }

                    result(nil)
                }
            } else {
                // Show the default settings as fallback.
                openSettings(settingsUrl: UIApplication.openSettingsURLString)
                result(nil)
            }
            break
        default:
            // Show the default settings as fallback.
            openSettings(settingsUrl: UIApplication.openSettingsURLString)
            result(nil)
            break
        }
    }

    private func openSettings(settingsUrl: String) {
        guard let url = URL(string: settingsUrl) else {
            return
        }

        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    @available(iOS 15.0.0, *)
    @MainActor
    private func openSubscriptionSettings(_ windowScene: UIWindowScene) async {
        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            // Show the default settings as fallback.
            openSettings(settingsUrl: UIApplication.openSettingsURLString)
        }
    }
}
