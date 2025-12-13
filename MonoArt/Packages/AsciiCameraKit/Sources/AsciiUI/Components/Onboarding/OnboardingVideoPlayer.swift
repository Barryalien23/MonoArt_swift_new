#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import AVKit
import AVFoundation

@available(iOS 14.0, *)
struct OnboardingVideoPlayer: UIViewControllerRepresentable {
    let videoName: String

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = .black

        // Ensure all subviews have black background
        if let contentOverlayView = controller.contentOverlayView {
            contentOverlayView.backgroundColor = .clear
        }

        // Try to find video
        guard let videoURL = Bundle.module.url(forResource: videoName, withExtension: "mp4") else {
            print("❌ OnboardingVideo: Video not found - \(videoName).mp4")
            print("📂 Bundle path: \(Bundle.module.bundleURL)")
            print("📂 Bundle identifier: \(Bundle.module.bundleIdentifier ?? "unknown")")

            // List all resources
            if let resourcePath = Bundle.module.resourcePath {
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    print("📋 Available resources:")
                    items.prefix(30).forEach { item in
                        print("   - \(item)")
                    }
                } catch {
                    print("❌ Error listing resources: \(error)")
                }
            }

            return controller
        }

        print("✅ OnboardingVideo: Found video at \(videoURL.path)")

        // Create player
        let player = AVPlayer(url: videoURL)
        player.isMuted = true
        controller.player = player

        // Store in coordinator
        context.coordinator.player = player

        // Setup looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            print("🔄 OnboardingVideo: Looping video")
            player.seek(to: .zero)
            player.play()
        }

        // Start playing
        player.play()
        print("▶️ OnboardingVideo: Started playing")

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Nothing to update
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player = nil
        print("⏹ OnboardingVideo: Stopped playing")
    }

    class Coordinator {
        var player: AVPlayer?
    }
}
#endif
