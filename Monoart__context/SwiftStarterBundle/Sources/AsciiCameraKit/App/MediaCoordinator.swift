#if canImport(UIKit) && canImport(Photos)
import UIKit
import Photos

public enum MediaCoordinatorError: Error {
    case authorizationDenied
    case saveFailed
}

@available(iOS 15.0, tvOS 16.0, *)
public protocol MediaCoordinatorProtocol {
    func save(image: UIImage) async throws
}

@available(iOS 15.0, tvOS 16.0, *)
public final class PhotosMediaCoordinator: MediaCoordinatorProtocol {
    public init() {}

    public func save(image: UIImage) async throws {
        try await ensureAuthorization()
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    private func ensureAuthorization() async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            return
        case .notDetermined:
            let result = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard result == .authorized || result == .limited else { throw MediaCoordinatorError.authorizationDenied }
        default:
            throw MediaCoordinatorError.authorizationDenied
        }
    }
}

@available(iOS 15.0, tvOS 16.0, *)
public final class InMemoryMediaCoordinator: MediaCoordinatorProtocol {
    public private(set) var savedImages: [UIImage] = []

    public init() {}

    public func save(image: UIImage) async throws {
        savedImages.append(image)
    }
}
#endif
