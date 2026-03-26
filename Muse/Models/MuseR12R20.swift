import Foundation

// MARK: - Muse R12-R20: Collaboration, Ensemble, Platform

struct EnsembleProject: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var ownerID: String
    var collaboratorIDs: [String]
    var bpm: Int
    var timeSignature: String
    var trackIDs: [UUID]
    var sharedSessionURL: String
    var isLive: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, ownerID: String, collaboratorIDs: [String] = [], bpm: Int = 120, timeSignature: String = "4/4", trackIDs: [UUID] = [], sharedSessionURL: String = "", isLive: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.ownerID = ownerID
        self.collaboratorIDs = collaboratorIDs
        self.bpm = bpm
        self.timeSignature = timeSignature
        self.trackIDs = trackIDs
        self.sharedSessionURL = sharedSessionURL.isEmpty ? "https://muse.app/ensemble/\(id.uuidString)" : sharedSessionURL
        self.isLive = isLive
        self.createdAt = createdAt
    }
}

struct RealTimeCollaboration: Identifiable, Codable, Equatable {
    let id: UUID
    var projectID: UUID
    var participantIDs: [String]
    var activeTrackID: UUID?
    var cursorPositions: [String: Int]
    var changes: [MusicChange]
    
    struct MusicChange: Identifiable, Codable, Equatable {
        let id: UUID
        var changeType: ChangeType
        var trackID: UUID
        var data: String
        var authorID: String
        var timestamp: Date
        
        enum ChangeType: String, Codable {
            case noteAdded, noteRemoved, paramChanged, trackAdded, trackRemoved
        }
    }
    
    init(id: UUID = UUID(), projectID: UUID, participantIDs: [String] = [], activeTrackID: UUID? = nil, cursorPositions: [String: Int] = [:], changes: [MusicChange] = []) {
        self.id = id
        self.projectID = projectID
        self.participantIDs = participantIDs
        self.activeTrackID = activeTrackID
        self.cursorPositions = cursorPositions
        self.changes = changes
    }
}

struct SoundPack: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var creatorName: String
    var soundIDs: [UUID]
    var category: Category
    var isPremium: Bool
    var downloadCount: Int
    
    enum Category: String, Codable {
        case drums, bass, synth, vocals, fx, orchestral, world, organic
    }
    
    init(id: UUID = UUID(), name: String, creatorName: String, soundIDs: [UUID] = [], category: Category, isPremium: Bool = false, downloadCount: Int = 0) {
        self.id = id
        self.name = name
        self.creatorName = creatorName
        self.soundIDs = soundIDs
        self.category = category
        self.isPremium = isPremium
        self.downloadCount = downloadCount
    }
}

struct MIDIExport: Identifiable, Codable, Equatable {
    let id: UUID
    var projectID: UUID
    var format: Format
    var exportedURL: URL?
    var createdAt: Date
    
    enum Format: String, Codable {
        case midi = "MIDI"
        case wav = "WAV"
        case mp3 = "MP3"
        case aac = "AAC"
        case stems = "Stems"
    }
    
    init(id: UUID = UUID(), projectID: UUID, format: Format, exportedURL: URL? = nil, createdAt: Date = Date()) {
        self.id = id
        self.projectID = projectID
        self.format = format
        self.exportedURL = exportedURL
        self.createdAt = createdAt
    }
}

struct MuseSubscriptionTier: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var displayName: String
    var monthlyPrice: Decimal
    var annualPrice: Decimal
    var lifetimePrice: Decimal
    var features: [String]
    var isMostPopular: Bool
    
    static let free = MuseSubscriptionTier(id: UUID(), name: "free", displayName: "Free", monthlyPrice: 0, annualPrice: 0, lifetimePrice: 0, features: ["3 projects", "Basic sounds", "Simple export"], isMostPopular: false)
    static let pro = MuseSubscriptionTier(id: UUID(), name: "pro", displayName: "Pro", monthlyPrice: 9.99, annualPrice: 95.88, lifetimePrice: 199, features: ["Unlimited projects", "Pro sounds", "Collaboration", "MIDI export", "Priority support"], isMostPopular: true)
    static let studio = MuseSubscriptionTier(id: UUID(), name: "studio", displayName: "Studio", monthlyPrice: 19.99, annualPrice: 191.88, lifetimePrice: 0, features: ["Everything in Pro", "Sound packs", "Advanced mixing", "STEMS export", "Priority support"], isMostPopular: false)
}

struct SupportedLocale: Identifiable, Codable, Equatable {
    let id: UUID
    var code: String
    var displayName: String
    
    static let supported: [SupportedLocale] = [
        SupportedLocale(id: UUID(), code: "en", displayName: "English"),
        SupportedLocale(id: UUID(), code: "es", displayName: "Spanish"),
        SupportedLocale(id: UUID(), code: "fr", displayName: "French"),
        SupportedLocale(id: UUID(), code: "de", displayName: "German"),
    ]
}

struct CrossPlatformDevice: Identifiable, Codable, Equatable {
    let id: UUID
    var deviceName: String
    var platform: Platform
    
    enum Platform: String, Codable { case ios, macOS, web }
    
    init(id: UUID = UUID(), deviceName: String, platform: Platform) {
        self.id = id
        self.deviceName = deviceName
        self.platform = platform
    }
}

struct TeamMember: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var role: String
    var email: String
    
    init(id: UUID = UUID(), name: String, role: String, email: String) {
        self.id = id
        self.name = name
        self.role = role
        self.email = email
    }
}

struct AwardSubmission: Identifiable, Codable, Equatable {
    let id: UUID
    var awardName: String
    var category: String
    var status: Status
    
    enum Status: String, Codable { case draft, submitted, inReview, won, rejected }
    
    init(id: UUID = UUID(), awardName: String, category: String, status: Status = .draft) {
        self.id = id
        self.awardName = awardName
        self.category = category
        self.status = status
    }
}

struct PlatformIntegration: Identifiable, Codable, Equatable {
    let id: UUID
    var platform: String
    var isEnabled: Bool
    
    init(id: UUID = UUID(), platform: String, isEnabled: Bool = false) {
        self.id = id
        self.platform = platform
        self.isEnabled = isEnabled
    }
}

struct MuseAPI: Codable, Equatable {
    var clientID: String
    var tier: APITier
    
    enum APITier: String, Codable { case free, paid }
    
    init(clientID: String = UUID().uuidString, tier: APITier = .free) {
        self.clientID = clientID
        self.tier = tier
    }
}
