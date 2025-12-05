import UIKit

/// Manager for haptic feedback with different intensity levels
public final class HapticManager {
    public static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare generators for lower latency
        lightGenerator.prepare()
        mediumGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    /// Micro haptic feedback for subtle interactions (20-30% intensity)
    /// Use for: tab selection, effect selection, color picker selection
    public func playMicro() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    /// Progressive haptic feedback for slider interactions
    /// Intensity increases from minimal at 0 to ~65% at maximum
    /// - Parameter progress: Value from 0.0 to 1.0 representing slider position
    public func playSliderFeedback(progress: Double) {
        let clampedProgress = min(max(progress, 0.0), 1.0)
        
        // Map progress to intensity: 0.0 → light, 0.5 → medium, 1.0 → rigid (but not too strong)
        if clampedProgress < 0.33 {
            lightGenerator.impactOccurred(intensity: 0.3 + (clampedProgress * 0.3))
            lightGenerator.prepare()
        } else if clampedProgress < 0.67 {
            mediumGenerator.impactOccurred(intensity: 0.4 + ((clampedProgress - 0.33) * 0.4))
            mediumGenerator.prepare()
        } else {
            // Max out at 0.65 intensity for rigid
            let adjustedProgress = (clampedProgress - 0.67) / 0.33
            rigidGenerator.impactOccurred(intensity: 0.5 + (adjustedProgress * 0.15))
            rigidGenerator.prepare()
        }
    }
    
    /// Medium haptic feedback for main UI interactions (35-40% intensity)
    /// Use for: parameter tiles, color tiles, effect button, import/rotate/gallery/about buttons
    public func playMedium() {
        mediumGenerator.impactOccurred(intensity: 0.4)
        mediumGenerator.prepare()
    }
    
    /// Short strong haptic for important actions (capture, save)
    public func playShort() {
        rigidGenerator.impactOccurred(intensity: 0.7)
        rigidGenerator.prepare()
    }
}

