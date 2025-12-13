#if canImport(Combine)
import Combine
#endif
import Foundation
#if canImport(UIKit)
import UIKit
import AVFoundation
import Photos
#endif

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public final class OnboardingViewModel: ObservableObject {
    @Published public var currentStep: OnboardingStep
    @Published public var hasCameraPermission: Bool
    @Published public var hasPhotoLibraryPermission: Bool
    @Published public var isPresented: Bool

    private let userDefaultsKey = "com.monoart.onboarding.completed"

    public init() {
        self.currentStep = .video1
        self.hasCameraPermission = false
        self.hasPhotoLibraryPermission = false
        self.isPresented = false
        checkPermissions()
    }

    // MARK: - Public Methods

    public var shouldShowOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: userDefaultsKey)
    }

    public func startOnboarding() {
        currentStep = .video1
        isPresented = true
        checkPermissions()
    }

    public func nextStep() {
        if let next = currentStep.next {
            currentStep = next
        } else {
            completeOnboarding()
        }
    }

    public func skipOnboarding() {
        completeOnboarding()
    }

    public func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
        isPresented = false
    }

    // MARK: - Permission Management

    #if canImport(UIKit)
    public func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .notDetermined:
            // Request permission for the first time
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.hasCameraPermission = granted
                    if !granted {
                        self?.openSettings()
                    }
                }
            }
        case .denied, .restricted:
            // Permission previously denied - open Settings
            DispatchQueue.main.async { [weak self] in
                self?.openSettings()
            }
        case .authorized:
            hasCameraPermission = true
        @unknown default:
            break
        }
    }

    public func requestPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()

        switch status {
        case .notDetermined:
            // Request permission for the first time
            PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    self?.hasPhotoLibraryPermission = newStatus == .authorized || newStatus == .limited
                    if newStatus == .denied || newStatus == .restricted {
                        self?.openSettings()
                    }
                }
            }
        case .denied, .restricted:
            // Permission previously denied - open Settings
            DispatchQueue.main.async { [weak self] in
                self?.openSettings()
            }
        case .authorized, .limited:
            hasPhotoLibraryPermission = true
        @unknown default:
            break
        }
    }

    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
    #endif

    public func checkPermissions() {
        #if canImport(UIKit)
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        hasCameraPermission = cameraStatus == .authorized

        let photoStatus = PHPhotoLibrary.authorizationStatus()
        hasPhotoLibraryPermission = photoStatus == .authorized || photoStatus == .limited
        #endif
    }

    // MARK: - Step Progress

    public var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    public var stepIndex: Int {
        currentStep.rawValue
    }

    public var totalSteps: Int {
        OnboardingStep.allCases.count
    }
}
