#if canImport(SwiftUI) && canImport(MetalKit) && os(iOS)
import SwiftUI
import MetalKit
import AsciiEngine
import AsciiDomain

@available(iOS 15.0, *)
public struct MetalPreviewView: UIViewRepresentable {
    let engine: AsciiEngine
    let effect: EffectType

    public init(engine: AsciiEngine, effect: EffectType) {
        self.engine = engine
        self.effect = effect
    }

    public func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        try? engine.setupPreview(on: view, effect: effect)
        return view
    }

    public func updateUIView(_ view: MTKView, context: Context) {
        // View updates are handled by the engine's draw(in:) method
    }
}
#endif

