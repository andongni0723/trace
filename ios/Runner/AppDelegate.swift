import AVFoundation
import CryptoKit
import Flutter
import QuickLook
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let mediaOpenerChannel = "trace/media_opener"
  private let mediaThumbnailerChannel = "trace/media_thumbnailer"
  private var mediaPreviewDataSource: MediaPreviewDataSource?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(
        name: mediaOpenerChannel,
        binaryMessenger: controller.binaryMessenger
      ).setMethodCallHandler { [weak self] call, result in
        guard call.method == "openMediaFile" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let arguments = call.arguments as? [String: Any],
          let filePath = arguments["filePath"] as? String
        else {
          result(false)
          return
        }

        self?.openMediaFile(filePath: filePath, result: result)
      }

      FlutterMethodChannel(
        name: mediaThumbnailerChannel,
        binaryMessenger: controller.binaryMessenger
      ).setMethodCallHandler { [weak self] call, result in
        guard call.method == "thumbnailForVideo" else {
          result(FlutterMethodNotImplemented)
          return
        }

        guard
          let arguments = call.arguments as? [String: Any],
          let videoPath = arguments["videoPath"] as? String
        else {
          result(nil)
          return
        }

        self?.thumbnailForVideo(videoPath: videoPath, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func openMediaFile(filePath: String, result: @escaping FlutterResult) {
    let trimmedPath = filePath.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedPath.isEmpty, FileManager.default.fileExists(atPath: trimmedPath) else {
      result(false)
      return
    }

    let fileUrl = URL(fileURLWithPath: trimmedPath)
    let dataSource = MediaPreviewDataSource(fileUrl: fileUrl)
    let previewController = QLPreviewController()
    previewController.dataSource = dataSource
    mediaPreviewDataSource = dataSource

    DispatchQueue.main.async { [weak self] in
      guard let rootController = self?.window?.rootViewController else {
        result(false)
        return
      }

      rootController.present(previewController, animated: true) {
        result(true)
      }
    }
  }

  private func thumbnailForVideo(videoPath: String, result: @escaping FlutterResult) {
    let trimmedPath = videoPath.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedPath.isEmpty, FileManager.default.fileExists(atPath: trimmedPath) else {
      result(nil)
      return
    }

    let videoUrl = URL(fileURLWithPath: trimmedPath)
    let thumbnailDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("media_video_thumbnails", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: thumbnailDirectory,
      withIntermediateDirectories: true
    )

    let cacheKey = "\(videoUrl.path):\(fileModificationTime(path: trimmedPath))".sha256
    let thumbnailUrl = thumbnailDirectory.appendingPathComponent("\(cacheKey).jpg")
    if FileManager.default.fileExists(atPath: thumbnailUrl.path) {
      result(thumbnailUrl.path)
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let asset = AVURLAsset(url: videoUrl)
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      generator.requestedTimeToleranceBefore = .zero
      generator.requestedTimeToleranceAfter = .zero

      do {
        let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
        let image = UIImage(cgImage: cgImage)
        guard let data = image.jpegData(compressionQuality: 0.86) else {
          DispatchQueue.main.async { result(nil) }
          return
        }
        try data.write(to: thumbnailUrl, options: .atomic)
        DispatchQueue.main.async { result(thumbnailUrl.path) }
      } catch {
        DispatchQueue.main.async { result(nil) }
      }
    }
  }

  private func fileModificationTime(path: String) -> TimeInterval {
    guard
      let attributes = try? FileManager.default.attributesOfItem(atPath: path),
      let modifiedDate = attributes[.modificationDate] as? Date
    else {
      return 0
    }
    return modifiedDate.timeIntervalSince1970
  }
}

private final class MediaPreviewDataSource: NSObject, QLPreviewControllerDataSource {
  private let fileUrl: URL

  init(fileUrl: URL) {
    self.fileUrl = fileUrl
  }

  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }

  func previewController(
    _ controller: QLPreviewController,
    previewItemAt index: Int
  ) -> QLPreviewItem {
    return fileUrl as NSURL
  }
}

private extension String {
  var sha256: String {
    let data = Data(utf8)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}
