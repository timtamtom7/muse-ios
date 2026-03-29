import Foundation

struct Track: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let artworkURL: URL?
    
    init(id: UUID = UUID(), title: String, artist: String, album: String, duration: TimeInterval, artworkURL: URL? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.artworkURL = artworkURL
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Playlist: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var tracks: [Track]
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, tracks: [Track] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.tracks = tracks
        self.createdAt = createdAt
    }
    
    var trackCount: Int { tracks.count }
    
    var coverMosaic: [URL?] {
        Array(tracks.prefix(4).map { $0.artworkURL })
    }
}

enum PlaybackState: Equatable {
    case stopped
    case playing
    case paused
}

struct PlayerState: Equatable {
    var currentTrack: Track?
    var playbackState: PlaybackState = .stopped
    var progress: Double = 0
    var volume: Double = 0.8
    var queue: [Track] = []
    var queueIndex: Int = 0
    
    var isPlaying: Bool { playbackState == .playing }
    var hasTrack: Bool { currentTrack != nil }
    
    var upNext: [Track] {
        guard queueIndex + 1 < queue.count else { return [] }
        return Array(queue[(queueIndex + 1)...])
    }
    
    var currentIndexInQueue: Int? {
        guard currentTrack != nil else { return nil }
        return queueIndex
    }
}
