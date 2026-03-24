import Foundation
import AVFoundation

enum SoundscapeType: String, CaseIterable, Codable, Identifiable {
    case whiteNoise = "white_noise"
    case pinkNoise = "pink_noise"
    case brownNoise = "brown_noise"
    case lowHum = "low_hum"
    case oceanWaves = "ocean_waves"
    case forest = "forest"
    case rain = "rain"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .whiteNoise: return "White Noise"
        case .pinkNoise: return "Pink Noise"
        case .brownNoise: return "Brown Noise"
        case .lowHum: return "Low Hum"
        case .oceanWaves: return "Ocean Waves"
        case .forest: return "Forest"
        case .rain: return "Rain"
        }
    }

    var icon: String {
        switch self {
        case .whiteNoise: return "waveform"
        case .pinkNoise: return "waveform.path"
        case .brownNoise: return "waveform.circle"
        case .lowHum: return "hifispeaker"
        case .oceanWaves: return "water.waves"
        case .forest: return "leaf"
        case .rain: return "cloud.rain"
        }
    }

    var description: String {
        switch self {
        case .whiteNoise: return "Consistent static across all frequencies"
        case .pinkNoise: return "Balanced noise, deeper than white"
        case .brownNoise: return "Deep, rumbling, very relaxing"
        case .lowHum: return "Subtle bass hum for focus"
        case .oceanWaves: return "Rhythmic coastal wave patterns"
        case .forest: return "Birds and rustling leaves"
        case .rain: return "Gentle rainfall on leaves"
        }
    }

    var tier: SubscriptionTier {
        switch self {
        case .whiteNoise, .pinkNoise, .brownNoise, .lowHum:
            return .practice  // Basic sounds for Practice tier
        case .oceanWaves, .forest, .rain:
            return .master  // Nature sounds for Master tier
        }
    }
}

struct Soundscape: Codable, Identifiable {
    let id: UUID
    let type: SoundscapeType
    var volume: Float  // 0.0 to 1.0

    init(type: SoundscapeType, volume: Float = 0.5) {
        self.id = UUID()
        self.type = type
        self.volume = volume
    }
}

@Observable
final class SoundscapeManager {
    static let shared = SoundscapeManager()

    private var audioPlayers: [SoundscapeType: AVAudioPlayer] = [:]
    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }

    var activeSoundscape: SoundscapeType? {
        activePreset?.type
    }

    private(set) var activePreset: Soundscape?
    var isPlaying: Bool { activePreset != nil }

    var masterVolume: Float {
        get { UserDefaults.standard.float(forKey: "soundscapeMasterVolume") }
        set {
            UserDefaults.standard.set(newValue, forKey: "soundscapeMasterVolume")
            applyVolume(newValue, toAll: true)
        }
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "soundscapeEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "soundscapeEnabled") }
    }

    private let activePresetKey = "activeSoundscapePreset"

    init() {
        setupAudioSession()
        loadActivePreset()
        if UserDefaults.standard.object(forKey: "soundscapeMasterVolume") == nil {
            UserDefaults.standard.set(Float(0.4), forKey: "soundscapeMasterVolume")
        }
    }

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func loadActivePreset() {
        guard let data = UserDefaults.standard.data(forKey: activePresetKey),
              let preset = try? JSONDecoder().decode(Soundscape.self, from: data) else {
            return
        }
        activePreset = preset
    }

    private func saveActivePreset() {
        if let preset = activePreset,
           let data = try? JSONEncoder().encode(preset) {
            UserDefaults.standard.set(data, forKey: activePresetKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activePresetKey)
        }
    }

    func selectSoundscape(_ type: SoundscapeType, volume: Float = 0.5) {
        stop()

        activePreset = Soundscape(type: type, volume: volume)

        // Try to load the audio file
        if loadAudio(for: type) {
            saveActivePreset()
        }
    }

    func updateVolume(_ volume: Float) {
        guard var preset = activePreset else { return }
        preset = Soundscape(type: preset.type, volume: volume)
        activePreset = preset
        applyVolume(volume, to: preset.type)
        saveActivePreset()
    }

    func startIfConfigured() {
        guard let preset = activePreset, isEnabled else { return }
        if loadAudio(for: preset.type) {
            applyVolume(preset.volume, to: preset.type)
        }
    }

    func stop() {
        for (type, player) in audioPlayers {
            player.stop()
            audioPlayers[type] = nil
        }
        activePreset = nil
        saveActivePreset()
    }

    private func loadAudio(for type: SoundscapeType) -> Bool {
        // Try to load from bundle
        let fileName = type.rawValue

        // Check if file exists in bundle
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") ?? 
              Bundle.main.url(forResource: fileName, withExtension: "m4a") ??
              Bundle.main.url(forResource: fileName, withExtension: "wav") else {
            // File not found - handle gracefully
            print("Soundscape file not found: \(fileName)")
            return false
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Loop indefinitely
            player.volume = masterVolume * (activePreset?.volume ?? 0.5)
            player.prepareToPlay()
            player.play()
            audioPlayers[type] = player
            return true
        } catch {
            print("Failed to load soundscape \(fileName): \(error)")
            return false
        }
    }

    private func applyVolume(_ volume: Float, to type: SoundscapeType) {
        audioPlayers[type]?.volume = masterVolume * volume
    }

    private func applyVolume(_ volume: Float, toAll: Bool) {
        if toAll {
            for (type, player) in audioPlayers {
                player.volume = volume * (activePreset?.type == type ? (activePreset?.volume ?? 0.5) : 0.5)
            }
        }
    }

    func availableSoundscapes(for tier: SubscriptionTier) -> [SoundscapeType] {
        SoundscapeType.allCases.filter { soundType in
            tierOrder(tier) >= tierOrder(soundType.tier)
        }
    }

    private func tierOrder(_ tier: SubscriptionTier) -> Int {
        switch tier {
        case .free: return 0
        case .practice: return 1
        case .master: return 2
        }
    }
}
