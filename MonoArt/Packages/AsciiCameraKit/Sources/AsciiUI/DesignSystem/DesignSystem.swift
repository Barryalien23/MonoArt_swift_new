import Foundation

public enum DesignSystem {
    private static var isBootstrapped = false

    public static func bootstrap() {
        guard !isBootstrapped else { return }
        DesignTokens.Fonts.ensureRegistered()
        isBootstrapped = true
    }
}
