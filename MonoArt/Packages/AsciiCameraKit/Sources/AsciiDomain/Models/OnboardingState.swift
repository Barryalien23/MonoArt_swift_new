import Foundation

// MARK: - Onboarding State

public struct OnboardingState: Codable {
    public var hasCompletedOnboarding: Bool
    public var hasCameraPermission: Bool
    public var hasPhotoLibraryPermission: Bool

    public init(
        hasCompletedOnboarding: Bool = false,
        hasCameraPermission: Bool = false,
        hasPhotoLibraryPermission: Bool = false
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCameraPermission = hasCameraPermission
        self.hasPhotoLibraryPermission = hasPhotoLibraryPermission
    }
}

// MARK: - Onboarding Step

public enum OnboardingStep: Int, CaseIterable {
    case video1 = 0
    case video2 = 1
    case video3 = 2
    case permissions = 3

    public var videoName: String? {
        switch self {
        case .video1: return "onboarding 1"
        case .video2: return "onboarding 2"
        case .video3: return "onboarding 3"
        case .permissions: return nil
        }
    }

    public var title: String {
        switch self {
        case .video1:
            return "Shoot with ASCII effect"
        case .video2:
            return "Import. Transform. Save."
        case .video3:
            return "Become a line of code"
        case .permissions:
            return "Manage your permissions"
        }
    }

    public var description: String {
        switch self {
        case .video1:
            return "Capture photos or import images and turn it into glitchy-shots in real time"
        case .video2:
            return "Adjust the look, detail, and color to create your ascii aesthetic in seconds"
        case .video3:
            return "Use 6+ ASCII art filters for avatars and wallpapers"
        case .permissions:
            return "For the best experience in MonoArt, allow camera and photo access."
        }
    }

    public var isPermissionStep: Bool {
        self == .permissions
    }

    public var next: OnboardingStep? {
        guard let nextIndex = OnboardingStep(rawValue: rawValue + 1) else {
            return nil
        }
        return nextIndex
    }
}

// MARK: - Permission Type

public enum PermissionType {
    case camera
    case photoLibrary

    public var title: String {
        switch self {
        case .camera:
            return "Camera"
        case .photoLibrary:
            return "Gallery"
        }
    }

    public var description: String {
        switch self {
        case .camera:
            return "Capture photos and instantly turn them into ASCII art."
        case .photoLibrary:
            return "Use photos from your library to create ASCII art."
        }
    }

    public var iconName: String {
        switch self {
        case .camera:
            return "Camera"
        case .photoLibrary:
            return "Gallery"
        }
    }
}
