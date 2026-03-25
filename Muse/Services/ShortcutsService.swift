import Foundation
import AppIntents

// R11: Shortcuts Integration for Muse
// Now Playing, Play Playlist, Add to Queue Shortcuts actions
@MainActor
final class ShortcutsService: ObservableObject {
    static let shared = ShortcutsService()

    @Published var recentPlaylists: [ShortcutPlaylist] = []

    struct ShortcutPlaylist: Identifiable {
        let id: UUID
        let name: String
        let trackCount: Int
    }

    private init() {
        loadRecentPlaylists()
    }

    // MARK: - Shortcuts Actions

    /// Get current playing track info
    func getNowPlaying() -> NowPlayingInfo? {
        // Returns current track for Shortcuts
        return NowPlayingInfo(name: "Unknown", artist: "Unknown")
    }

    struct NowPlayingInfo {
        let name: String
        let artist: String
    }

    /// Play a playlist by name
    func playPlaylist(named name: String) async throws {
        // Find playlist and start playback
        // In a real implementation, this would use Spotify/Apple Music APIs
        print("Playing playlist: \(name)")
    }

    /// Add a track to the playback queue
    func addToQueue(trackName: String, artist: String) {
        let track = StreamingIntegrationService.QueuedTrack(
            name: trackName,
            artist: artist,
            albumArt: nil
        )
        StreamingIntegrationService.shared.addToQueue(track)
    }

    /// Refresh data for Shortcuts
    func refresh() {
        loadRecentPlaylists()
    }

    // MARK: - Private

    private func loadRecentPlaylists() {
        // Load from UserDefaults or Spotify API
        // For now, use mock data
        recentPlaylists = [
            ShortcutPlaylist(id: UUID(), name: "Focus Flow", trackCount: 25),
            ShortcutPlaylist(id: UUID(), name: "Deep Work", trackCount: 18)
        ]
    }
}

// MARK: - App Intents (Shortcuts)

/// Intent to get current now playing
struct GetNowPlayingIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Now Playing"
    static var description = IntentDescription("Returns the currently playing track")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let info = await ShortcutsService.shared.getNowPlaying()
        guard let unwrappedInfo = info else {
            return .result(value: "Nothing playing")
        }
        return .result(value: "\(unwrappedInfo.name) - \(unwrappedInfo.artist)")
    }
}

/// Intent to play a playlist
struct PlayPlaylistIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Playlist"
    static var description = IntentDescription("Play a playlist by name")

    @Parameter(title: "Playlist Name")
    var playlistName: String

    func perform() async throws -> some IntentResult {
        try await ShortcutsService.shared.playPlaylist(named: playlistName)
        return .result()
    }
}

/// Intent to add to queue
struct AddToQueueIntent: AppIntent {
    static var title: LocalizedStringResource = "Add to Queue"
    static var description = IntentDescription("Add a track to the queue")

    @Parameter(title: "Track Name")
    var trackName: String

    @Parameter(title: "Artist")
    var artist: String

    @MainActor
    func perform() async throws -> some IntentResult {
        ShortcutsService.shared.addToQueue(trackName: trackName, artist: artist)
        return .result()
    }
}

/// App Shortcuts provider
struct MuseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetNowPlayingIntent(),
            phrases: ["What song is playing in \(.applicationName)", "Now playing in \(.applicationName)"],
            shortTitle: "Now Playing",
            systemImageName: "play.circle"
        )

        AppShortcut(
            intent: PlayPlaylistIntent(),
            phrases: ["Play playlist in \(.applicationName)", "Start playlist in \(.applicationName)"],
            shortTitle: "Play Playlist",
            systemImageName: "music.note.list"
        )
    }
}
