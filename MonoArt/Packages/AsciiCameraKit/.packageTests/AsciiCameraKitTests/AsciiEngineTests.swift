#if canImport(XCTest) && !os(iOS)
import CoreVideo
import Metal
import XCTest
@testable import AsciiEngine
import AsciiDomain

final class AsciiEngineTests: XCTestCase {
    func testRenderPreviewProducesGlyphGrid() async throws {
        guard MTLCreateSystemDefaultDevice() != nil else {
            throw XCTSkip("Metal device unavailable on this host")
        }

        let engine = AsciiEngine()
        try engine.prepare(configuration: EngineConfiguration(maxPreviewCells: 4_000, maxCaptureCells: 8_000))

        let pixelBuffer = try makeGradientPixelBuffer(width: 160, height: 120)
        let frame = try await engine.renderPreview(
            pixelBuffer: pixelBuffer,
            effect: .ascii,
            parameters: EffectParameters(),
            palette: PaletteState()
        )

        let text = try XCTUnwrap(frame.glyphText)
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

        XCTAssertEqual(lines.count, frame.rows)
        XCTAssertTrue(lines.allSatisfy { $0.count == frame.columns })
    }

    func testCPURendererFallbackSucceedsWithoutMetal() async throws {
        let engine = AsciiEngine(deviceProvider: { nil })
        try engine.prepare(configuration: EngineConfiguration(maxPreviewCells: 2_500, maxCaptureCells: 5_000))

        let pixelBuffer = try makeGradientPixelBuffer(width: 120, height: 90)
        let frame = try await engine.renderPreview(
            pixelBuffer: pixelBuffer,
            effect: .ascii,
            parameters: EffectParameters(),
            palette: PaletteState()
        )

        XCTAssertNotNil(frame.glyphText)
        XCTAssertGreaterThan(frame.columns, 0)
        XCTAssertGreaterThan(frame.rows, 0)
    }
}
#endif

