#if canImport(SwiftUI) && os(iOS)
import AsciiDomain
import SwiftUI

public struct CaptureConfirmationBanner: View {
    public let status: CaptureStatus
    public let onDismiss: () -> Void
    public let onShare: (() -> Void)?

    public init(status: CaptureStatus, onDismiss: @escaping () -> Void, onShare: (() -> Void)? = nil) {
        self.status = status
        self.onDismiss = onDismiss
        self.onShare = onShare
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
            }
            Spacer()
            if case .success = status, let onShare {
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share captured image")
            }
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .padding(8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss capture banner")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStatus)
    }

    private var title: String {
        switch status {
        case .success: return "Saved"
        case .failure: return "Failed"
        }
    }

    private var message: String {
        switch status {
        case .success(let payload): return payload.message
        case .failure(let payload): return payload.message
        }
    }

    private var iconName: String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .success: return .green
        case .failure: return .red
        }
    }
}
#endif

