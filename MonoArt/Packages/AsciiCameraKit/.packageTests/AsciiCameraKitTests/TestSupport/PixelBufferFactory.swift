import CoreVideo

func makeGradientPixelBuffer(width: Int, height: Int) throws -> CVPixelBuffer {
    var pixelBuffer: CVPixelBuffer?
    let attrs: [String: Any] = [
        kCVPixelBufferMetalCompatibilityKey as String: true
    ]

    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
        throw NSError(domain: "PixelBufferFactory", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Unable to create pixel buffer"])
    }

    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

    guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
        throw NSError(domain: "PixelBufferFactory", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing base address"])
    }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    let ptr = baseAddress.bindMemory(to: UInt8.self, capacity: bytesPerRow * height)

    for row in 0 ..< height {
        for column in 0 ..< width {
            let offset = row * bytesPerRow + column * 4
            let normalizedX = Float(column) / Float(max(width - 1, 1))
            let normalizedY = Float(row) / Float(max(height - 1, 1))
            ptr[offset + 2] = UInt8((normalizedX * 255).rounded().clamped(to: 0.0 ... 255.0)) // R
            ptr[offset + 1] = UInt8((normalizedY * 255).rounded().clamped(to: 0.0 ... 255.0)) // G
            ptr[offset + 0] = UInt8(((1 - normalizedX) * 255).rounded().clamped(to: 0.0 ... 255.0)) // B
            ptr[offset + 3] = 255
        }
    }

    return buffer
}

private extension Comparable where Self == Float {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(range.upperBound, max(range.lowerBound, self))
    }
}
