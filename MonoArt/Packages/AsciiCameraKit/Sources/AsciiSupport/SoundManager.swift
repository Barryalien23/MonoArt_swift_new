import AVFoundation
import Foundation

/// Manager for sound effects playback
public final class SoundManager {
    public static let shared = SoundManager()
    
    public enum SoundType: String {
        case click = "click"
        case bit8 = "8-bit"
        case explosion = "explosion"
        
        var fileName: String {
            switch self {
            case .click: return "click"
            case .bit8: return "8-bit"
            case .explosion: return "explosion"
            }
        }
    }
    
    private var players: [SoundType: AVAudioPlayer] = [:]
    private let logger: Logger
    
    public init(logger: Logger = DefaultLogger()) {
        self.logger = logger
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            // Use playback category with mixWithOthers to allow sounds while other audio plays
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.log("Failed to setup audio session: \(error)", level: .error, category: "SoundManager")
        }
    }
    
    private func preloadSounds() {
        // Sounds are bundled in AsciiUI module - search all bundles
        let bundles = Bundle.allBundles
        
        for soundType in [SoundType.click, .bit8, .explosion] {
            var foundURL: URL?
            
            // Search all bundles for the sound file
            for bundle in bundles {
                if let url = bundle.url(forResource: soundType.fileName, withExtension: "mp3") {
                    foundURL = url
                    break
                }
            }
            
            guard let url = foundURL else {
                logger.log("Sound file not found: \(soundType.fileName)", level: .warning, category: "SoundManager")
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 1.0 // Set full volume
                player.prepareToPlay()
                players[soundType] = player
                logger.log("Preloaded sound: \(soundType.fileName)", level: .debug, category: "SoundManager")
            } catch {
                logger.log("Failed to load sound \(soundType.fileName): \(error)", level: .error, category: "SoundManager")
            }
        }
    }
    
    /// Play a sound effect
    /// - Parameter type: The type of sound to play
    public func play(_ type: SoundType) {
        // Ensure audio session is active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.log("Failed to activate audio session: \(error)", level: .error, category: "SoundManager")
        }
        
        guard let player = players[type] else {
            logger.log("Player not found for sound: \(type.fileName)", level: .warning, category: "SoundManager")
            return
        }
        
        if !player.isPlaying {
            player.currentTime = 0
            player.play()
        } else {
            // If already playing, restart
            player.stop()
            player.currentTime = 0
            player.play()
        }
    }
    
    /// Play click sound (used for most UI interactions)
    public func playClick() {
        play(.click)
    }
    
    /// Play 8-bit sound (used for effect selection)
    public func play8Bit() {
        play(.bit8)
    }
    
    /// Play explosion sound (used for photo capture)
    public func playExplosion() {
        play(.explosion)
    }
}

