import Foundation
import Combine
#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(AVFoundation)

@available(macOS 10.15, iOS 13, tvOS 13, *)
public protocol CameraServiceProtocol: AnyObject {
    var framePublisher: AnyPublisher<FrameEnvelope, Never> { get }
    var authorizationStatus: AVAuthorizationStatus { get }

    func startSession() async throws
    func stopSession()
    func switchCamera() async throws
}

@available(macOS 10.15, iOS 13, tvOS 13, *)
public final class FrameEnvelope: @unchecked Sendable {
    public let pixelBuffer: CVPixelBuffer
    public let timestamp: CMTime
    public let orientation: AVCaptureVideoOrientation

    public init(pixelBuffer: CVPixelBuffer, timestamp: CMTime, orientation: AVCaptureVideoOrientation) {
        self.pixelBuffer = pixelBuffer
        self.timestamp = timestamp
        self.orientation = orientation
    }

    deinit {
    }
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
public final class CameraService: NSObject, CameraServiceProtocol {
    private enum CameraServiceError: Error {
        case authorizationDenied
        case deviceUnavailable
        case configurationFailed(String)
    }

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.monoart.camera.session", qos: .userInitiated)
    private let outputQueue = DispatchQueue(label: "com.monoart.camera.output", qos: .userInitiated)
    private let subject = PassthroughSubject<FrameEnvelope, Never>()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var desiredPosition: AVCaptureDevice.Position = .back
    private var isConfigured = false
    private var isRunning = false
    private var videoOrientation: AVCaptureVideoOrientation = .portrait

    public override init() {
        super.init()
        session.sessionPreset = .high
    }

    public var framePublisher: AnyPublisher<FrameEnvelope, Never> {
        subject.eraseToAnyPublisher()
    }

    public var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    public func startSession() async throws {
        try await requestAccessIfNeeded()
        try await configureSessionIfNeeded()
        guard !isRunning else { return }
        isRunning = true
        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    public func stopSession() {
        guard isRunning else { return }
        isRunning = false
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    public func switchCamera() async throws {
        desiredPosition = desiredPosition == .back ? .front : .back
        try await replaceInput(position: desiredPosition)
    }

    public func updateVideoOrientation(_ orientation: AVCaptureVideoOrientation) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.videoOrientation = orientation
            if let connection = self.videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = orientation
            }
        }
    }

    private func requestAccessIfNeeded() async throws {
        switch authorizationStatus {
        case .authorized:
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { throw CameraServiceError.authorizationDenied }
        default:
            throw CameraServiceError.authorizationDenied
        }
    }

    private func configureSessionIfNeeded() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraServiceError.configurationFailed("Service released"))
                    return
                }

                do {
                    if !self.isConfigured {
                        try self.configureSessionLocked(position: self.desiredPosition)
                    }
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func replaceInput(position: AVCaptureDevice.Position) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraServiceError.configurationFailed("Service released"))
                    return
                }

                do {
                    try self.configureSessionLocked(position: position)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func configureSessionLocked(position: AVCaptureDevice.Position) throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        if let existingInput = currentInput {
            session.removeInput(existingInput)
            currentInput = nil
        }

        let device = try selectDevice(for: position)
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraServiceError.configurationFailed("Cannot add camera input")
        }
        session.addInput(input)
        currentInput = input

        if !session.outputs.contains(videoOutput) {
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
            guard session.canAddOutput(videoOutput) else {
                throw CameraServiceError.configurationFailed("Cannot add video output")
            }
            session.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = videoOrientation
        }

        isConfigured = true
    }

    private func selectDevice(for position: AVCaptureDevice.Position) throws -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return device
        }
#if os(iOS) || os(tvOS)
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: position) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: position) {
            return device
        }
#endif
        throw CameraServiceError.deviceUnavailable
    }
}

@available(macOS 11.0, iOS 15.0, tvOS 15.0, *)
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let orientation = connection.videoOrientation
        let envelope = FrameEnvelope(pixelBuffer: pixelBuffer, timestamp: timestamp, orientation: orientation)
        subject.send(envelope)
    }
}

/// Stub implementation used for previews and tests.
@available(macOS 10.15, iOS 13, tvOS 13, *)
public final class StubCameraService: CameraServiceProtocol {
    private let subject = PassthroughSubject<FrameEnvelope, Never>()

    public init() {}

    public var framePublisher: AnyPublisher<FrameEnvelope, Never> {
        subject.eraseToAnyPublisher()
    }

    public var authorizationStatus: AVAuthorizationStatus {
        .authorized
    }

    public func startSession() async throws {}

    public func stopSession() {}

    public func switchCamera() async throws {}

    public func emit(_ envelope: FrameEnvelope) {
        subject.send(envelope)
    }
}

#else

@available(macOS 10.15, iOS 13, tvOS 13, *)
public protocol CameraServiceProtocol: AnyObject {
    func stopSession()
}

@available(macOS 10.15, iOS 13, tvOS 13, *)
public final class StubCameraService: CameraServiceProtocol {
    public init() {}

    public func stopSession() {}
}

#endif