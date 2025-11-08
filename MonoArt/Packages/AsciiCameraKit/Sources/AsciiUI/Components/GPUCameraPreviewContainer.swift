#if canImport(SwiftUI) && canImport(MetalKit) && os(iOS)
import AsciiDomain
import AsciiEngine
import SwiftUI
import MetalKit

/// GPU-accelerated camera preview container using MetalPreviewView
@available(iOS 15.0, *)
public struct GPUCameraPreviewContainer: View {
    public let engine: AsciiEngine
    public let effect: EffectType
    public let status: PreviewStatus
    
    public init(engine: AsciiEngine, effect: EffectType, status: PreviewStatus) {
        self.engine = engine
        self.effect = effect
        self.status = status
    }
    
    public var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            MetalPreviewView(engine: engine, effect: effect)
                .ignoresSafeArea()
                .accessibilityLabel("GPU-accelerated ASCII preview")
            
            statusOverlay
        }
        .overlay(alignment: .topLeading) {
            Text(effect.displayTitle)
                .font(.caption.bold())
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(12)
                .accessibilityLabel("Effect \(effect.displayTitle)")
        }
    }
    
    @ViewBuilder
    private var statusOverlay: some View {
        switch status {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView("Initializing GPU preview…")
                .progressViewStyle(.circular)
                .foregroundStyle(.white)
        case .running:
            EmptyView()
        case .failed(let failure):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text(failure.message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding()
        }
    }
}

private extension EffectType {
    var displayTitle: String {
        rawValue.capitalized
    }
}
#endif

