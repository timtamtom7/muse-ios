import Foundation
import Combine

// MARK: - Social Models

struct Friend: Identifiable, Equatable, Hashable {
    let id: UUID
    let displayName: String
    let avatarURL: URL?
    var isPrivate: Bool
    var isFollowing: Bool
    
    init(id: UUID = UUID(), displayName: String, avatarURL: URL? = nil, isPrivate: Bool = false, isFollowing: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isPrivate = isPrivate
        self.isFollowing = isFollowing
    }
}

struct FriendActivity: Identifiable, Equatable {
    let id: UUID
    let friend: Friend
    let track: Track
    let activityType: ActivityType
    let timestamp: Date
    
    enum ActivityType: String, Codable {
        case listening
        case finished
        case addedToPlaylist
        case startedPlaylist
        case reaction
    }
    
    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

struct Reaction: Identifiable, Codable, Equatable {
    let id: UUID
    let emoji: String
    let userId: UUID
    let trackId: UUID
    let timestamp: Date
}

struct CollaborativePlaylist: Identifiable, Equatable {
    let id: UUID
    var name: String
    var tracks: [Track]
    let ownerId: UUID
    var collaboratorIds: [UUID]
    var contributorNames: [UUID: String]
    let createdAt: Date
    var permissions: Permissions
    
    struct Permissions: Equatable {
        var canAdd: Bool
        var canRemove: Bool
        var canRename: Bool
        
        static let all = Permissions(canAdd: true, canRemove: true, canRename: true)
        static let addOnly = Permissions(canAdd: true, canRemove: false, canRename: false)
    }
    
    var contributorCount: Int { collaboratorIds.count }
    
    var contributorsSummary: String {
        if collaboratorIds.isEmpty {
            return "Just you"
        } else if collaboratorIds.count == 1 {
            return "1 collaborator"
        } else {
            return "\(collaboratorIds.count) collaborators"
        }
    }
}

struct LiveListeningSession: Identifiable {
    let id: UUID
    var hostId: UUID
    var participants: [UUID: LiveParticipant]
    var currentTrack: Track?
    var isPlaying: Bool
    let startedAt: Date
    
    struct LiveParticipant: Equatable {
        let userId: UUID
        let displayName: String
        var currentTrack: Track?
        var isPlaying: Bool
        var latestReaction: Reaction?
    }
}

// MARK: - SocialMusicService

final class SocialMusicService: ObservableObject, @unchecked Sendable {
    nonisolated(unsafe) static let shared = SocialMusicService()
    
    @Published private(set) var friends: [Friend] = []
    @Published private(set) var friendActivity: [FriendActivity] = []
    @Published private(set) var collaborativePlaylists: [CollaborativePlaylist] = []
    @Published private(set) var liveSessions: [LiveListeningSession] = []
    @Published private(set) var pendingRequests: [Friend] = []
    @Published var isPrivateMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadFromDisk()
        loadSampleFriends()
    }
    
    // MARK: - Friend Activity
    
    func shareListeningActivity(track: Track, toFriends friendIds: [String]) {
        guard !isPrivateMode else { return }
        // In a real app, this would send to a backend via WebSocket
        // For now, we just log the activity locally
        saveToDisk()
    }
    
    func getFriendActivity() -> [FriendActivity] {
        return friendActivity.sorted { $0.timestamp > $1.timestamp }
    }
    
    func followListener(userId: UUID) {
        if let index = friends.firstIndex(where: { $0.id == userId }) {
            friends[index].isFollowing = true
        } else {
            let newFriend = Friend(id: userId, displayName: "User \(userId.uuidString.prefix(4))", isFollowing: true)
            friends.append(newFriend)
        }
        saveToDisk()
    }
    
    func unfollowListener(userId: UUID) {
        if let index = friends.firstIndex(where: { $0.id == userId }) {
            friends[index].isFollowing = false
        }
        saveToDisk()
    }
    
    // MARK: - Collaborative Playlists
    
    func createCollaborativePlaylist(name: String, ownerId: UUID = UUID()) -> CollaborativePlaylist {
        let playlist = CollaborativePlaylist(
            id: UUID(),
            name: name,
            tracks: [],
            ownerId: ownerId,
            collaboratorIds: [],
            contributorNames: [:],
            createdAt: Date(),
            permissions: .all
        )
        collaborativePlaylists.append(playlist)
        saveToDisk()
        return playlist
    }
    
    func inviteToPlaylist(playlistId: UUID, userId: UUID) {
        guard let index = collaborativePlaylists.firstIndex(where: { $0.id == playlistId }) else { return }
        if !collaborativePlaylists[index].collaboratorIds.contains(userId) {
            collaborativePlaylists[index].collaboratorIds.append(userId)
            collaborativePlaylists[index].contributorNames[userId] = "User \(userId.uuidString.prefix(4))"
        }
        saveToDisk()
    }
    
    func addTrackToPlaylist(playlistId: UUID, track: Track, addedBy userId: UUID) {
        guard let index = collaborativePlaylists.firstIndex(where: { $0.id == playlistId }) else { return }
        guard collaborativePlaylists[index].permissions.canAdd else { return }
        collaborativePlaylists[index].tracks.append(track)
        if !collaborativePlaylists[index].contributorNames.keys.contains(userId) {
            collaborativePlaylists[index].contributorNames[userId] = "User \(userId.uuidString.prefix(4))"
        }
        saveToDisk()
    }
    
    func removeTrackFromPlaylist(playlistId: UUID, trackId: UUID) {
        guard let index = collaborativePlaylists.firstIndex(where: { $0.id == playlistId }) else { return }
        guard collaborativePlaylists[index].permissions.canRemove else { return }
        collaborativePlaylists[index].tracks.removeAll { $0.id == trackId }
        saveToDisk()
    }
    
    func setPlaylistPermissions(playlistId: UUID, permissions: CollaborativePlaylist.Permissions) {
        guard let index = collaborativePlaylists.firstIndex(where: { $0.id == playlistId }) else { return }
        collaborativePlaylists[index].permissions = permissions
        saveToDisk()
    }
    
    func leavePlaylist(playlistId: UUID, userId: UUID) {
        guard let index = collaborativePlaylists.firstIndex(where: { $0.id == playlistId }) else { return }
        collaborativePlaylists[index].collaboratorIds.removeAll { $0 == userId }
        collaborativePlaylists[index].contributorNames.removeValue(forKey: userId)
        if collaborativePlaylists[index].collaboratorIds.isEmpty {
            collaborativePlaylists.remove(at: index)
        }
        saveToDisk()
    }
    
    // MARK: - Live Listening Sessions
    
    func createLiveSession(hostId: UUID) -> LiveListeningSession {
        let session = LiveListeningSession(
            id: UUID(),
            hostId: hostId,
            participants: [:],
            currentTrack: nil,
            isPlaying: false,
            startedAt: Date()
        )
        liveSessions.append(session)
        saveToDisk()
        return session
    }
    
    func joinSession(_ sessionId: UUID, userId: UUID, displayName: String) {
        guard let index = liveSessions.firstIndex(where: { $0.id == sessionId }) else { return }
        let participant = LiveListeningSession.LiveParticipant(
            userId: userId,
            displayName: displayName,
            currentTrack: nil,
            isPlaying: false,
            latestReaction: nil
        )
        liveSessions[index].participants[userId] = participant
        saveToDisk()
    }
    
    func updateSessionTrack(_ sessionId: UUID, track: Track?, isPlaying: Bool) {
        guard let index = liveSessions.firstIndex(where: { $0.id == sessionId }) else { return }
        liveSessions[index].currentTrack = track
        liveSessions[index].isPlaying = isPlaying
        saveToDisk()
    }
    
    func sendReaction(toSession sessionId: UUID, userId: UUID, emoji: String) {
        guard let index = liveSessions.firstIndex(where: { $0.id == sessionId }) else { return }
        guard let participantIndex = liveSessions[index].participants[userId] else { return }
        var updated = participantIndex
        updated.latestReaction = Reaction(
            id: UUID(),
            emoji: emoji,
            userId: userId,
            trackId: liveSessions[index].currentTrack?.id ?? UUID(),
            timestamp: Date()
        )
        liveSessions[index].participants[userId] = updated
        saveToDisk()
    }
    
    func leaveSession(_ sessionId: UUID, userId: UUID) {
        guard let index = liveSessions.firstIndex(where: { $0.id == sessionId }) else { return }
        liveSessions[index].participants.removeValue(forKey: userId)
        if liveSessions[index].participants.isEmpty {
            liveSessions.remove(at: index)
        }
        saveToDisk()
    }
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(to userId: UUID, displayName: String) {
        let friend = Friend(id: userId, displayName: displayName, isFollowing: false)
        pendingRequests.append(friend)
        saveToDisk()
    }
    
    func acceptFriendRequest(_ friend: Friend) {
        pendingRequests.removeAll { $0.id == friend.id }
        var accepted = friend
        accepted.isFollowing = true
        friends.append(accepted)
        saveToDisk()
    }
    
    func declineFriendRequest(_ friend: Friend) {
        pendingRequests.removeAll { $0.id == friend.id }
        saveToDisk()
    }
    
    func blockUser(_ userId: UUID) {
        friends.removeAll { $0.id == userId }
        pendingRequests.removeAll { $0.id == userId }
        saveToDisk()
    }
    
    // MARK: - Persistence
    
    private var persistenceKey: String { "SocialMusicService" }
    
    private func saveToDisk() {
        // Basic persistence - store friend IDs and playlist IDs
        let friendIds = friends.map { $0.id.uuidString }
        userDefaults.set(friendIds, forKey: "\(persistenceKey).friends")
    }
    
    private func loadFromDisk() {
        // Placeholder - in production would deserialize properly
    }
    
    private func loadSampleFriends() {
        if friends.isEmpty {
            friends = [
                Friend(displayName: "Alex Rivera", isFollowing: true),
                Friend(displayName: "Jordan Chen", isFollowing: true),
                Friend(displayName: "Sam Taylor", isFollowing: false),
                Friend(displayName: "Casey Morgan", isFollowing: true),
            ]
        }
        
        if friendActivity.isEmpty {
            let sampleTracks = [
                Track(title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", duration: 200),
                Track(title: "Starboy", artist: "The Weeknd", album: "Starboy", duration: 230),
                Track(title: "Midnight City", artist: "M83", album: "Hurry Up, We're Dreaming", duration: 243),
                Track(title: "Electric Feel", artist: "MGMT", album: "Oracular Spectacular", duration: 229),
            ]
            
            friendActivity = [
                FriendActivity(
                    id: UUID(),
                    friend: friends[0],
                    track: sampleTracks[0],
                    activityType: .listening,
                    timestamp: Date().addingTimeInterval(-120)
                ),
                FriendActivity(
                    id: UUID(),
                    friend: friends[1],
                    track: sampleTracks[1],
                    activityType: .addedToPlaylist,
                    timestamp: Date().addingTimeInterval(-1800)
                ),
                FriendActivity(
                    id: UUID(),
                    friend: friends[3],
                    track: sampleTracks[2],
                    activityType: .finished,
                    timestamp: Date().addingTimeInterval(-3600)
                ),
            ]
        }
    }
}
