import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty,
       apiKey != "TU_API_KEY_DE_GOOGLE_MAPS" {
      GMSServices.provideAPIKey(apiKey)
    }
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let mapChannel = FlutterMethodChannel(
        name: "com.church.register/external_map",
        binaryMessenger: controller.binaryMessenger
      )
      mapChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "launchUrl":
          guard let urlString = call.arguments as? String,
                let url = URL(string: urlString) else {
            result(false)
            return
          }
          if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            result(true)
          } else {
            result(false)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let shareChannel = FlutterMethodChannel(
        name: "com.church.register/file_share",
        binaryMessenger: controller.binaryMessenger
      )
      shareChannel.setMethodCallHandler { [weak controller] call, result in
        guard let controller = controller else {
          result(false)
          return
        }
        switch call.method {
        case "shareFile":
          guard let args = call.arguments as? [String: Any],
                let fileName = args["fileName"] as? String,
                let typedData = args["bytes"] as? FlutterStandardTypedData else {
            result(false)
            return
          }
          let data = typedData.data
          let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
          do {
            try data.write(to: tempURL)
            let activityVC = UIActivityViewController(
              activityItems: [tempURL],
              applicationActivities: nil
            )
            if let subject = args["subject"] as? String, !subject.isEmpty {
              activityVC.setValue(subject, forKey: "subject")
            }
            if let popover = activityVC.popoverPresentationController {
              popover.sourceView = controller.view
              popover.sourceRect = CGRect(
                x: controller.view.bounds.midX,
                y: controller.view.bounds.midY,
                width: 0,
                height: 0
              )
              popover.permittedArrowDirections = []
            }
            controller.present(activityVC, animated: true)
            result(true)
          } catch {
            result(false)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
