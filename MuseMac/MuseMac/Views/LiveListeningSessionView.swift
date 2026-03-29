import SwiftUI

struct LiveListeningSessionView: View {
    @ObservedObject private var socialService = SocialMusicService.shared
    @ObservedObject private var playerService = MusicPlayerService.shared
    @State private var currentSession: LiveListeningSession?
    @State private var showingCreateSession = false
    @State private var sessionName = ""
    @State private var selectedReaction: String?
    @State private var reactionAnimation = false
    
    private let reactions = ["🔥", "❤️", "😂", "😮", "👏", "🎵"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Live Listening")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { showingCreateSession = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.hotPink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Theme.cardBg)
            
            if let session = currentSession {
                activeSessionView(session)
            } else {
                noActiveSessionView
            }
        }
        .sheet(isPresented: $showingCreateSession) {
            createSessionSheet
        }
    }
    
    private var noActiveSessionView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(Theme.textSecondary)
            
            Text("No Active Session")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            Text("Start a live session to listen with friends in real-time")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: { showingCreateSession = true }) {
                Text("Start Session")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Theme.gradient)
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    private func activeSessionView(_ session: LiveListeningSession) -> some View {
        VStack(spacing: 0) {
            // Now playing
            if let track = playerService.state.currentTrack {
                nowPlayingCard(track: track)
            }
            
            // Reaction bar
            reactionBar
            
            Divider()
                .background(Theme.cardBg)
            
            // Participants
            participantsList(session)
        }
    }
    
    private func nowPlayingCard(track: Track) -> some View {
        VStack(spacing: 12) {
            // Artwork
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardBg)
                .frame(width: 160, height: 160)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.textSecondary)
                )
            
            // Track info
            VStack(spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            
            // Playback indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(playerService.state.isPlaying ? Theme.hotPink : Theme.textSecondary)
                    .frame(width: 8, height: 8)
                
                Text(playerService.state.isPlaying ? "Playing" : "Paused")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            VStack {
                Spacer()
                Theme.gradient
                    .opacity(0.1)
                    .frame(height: 200)
            }
        )
    }
    
    private var reactionBar: some View {
        HStack(spacing: 16) {
            ForEach(reactions, id: \.self) { emoji in
                Button(action: {
                    selectedReaction = emoji
                    reactionAnimation = true
                    if let session = currentSession {
                        socialService.sendReaction(
                            toSession: session.id,
                            userId: UUID(),
                            emoji: emoji
                        )
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        reactionAnimation = false
                    }
                }) {
                    Text(emoji)
                        .font(.system(size: 24))
                        .scaleEffect(selectedReaction == emoji && reactionAnimation ? 1.4 : 1.0)
                        .animation(.spring(response: 0.3), value: reactionAnimation)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBg)
    }
    
    private func participantsList(_ session: LiveListeningSession) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Listening Together")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Text("\(session.participants.count) joined")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
                .background(Theme.cardBg)
            
            if session.participants.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.textSecondary)
                    
                    Text("Share your session link to invite friends")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(session.participants.values), id: \.userId) { participant in
                            participantRow(participant, currentTrack: session.currentTrack)
                        }
                    }
                }
            }
            
            // End session button
            Button(action: endSession) {
                Text("End Session")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(16)
        }
    }
    
    @ViewBuilder
    private func participantRow(_ participant: LiveListeningSession.LiveParticipant, currentTrack: Track?) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.cardBg)
                    .frame(width: 40, height: 40)
                
                Text(String(participant.displayName.prefix(1)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.hotPink)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                
                if let track = participant.currentTrack {
                    HStack(spacing: 4) {
                        Text("🎧")
                            .font(.system(size: 10))
                        Text("\(track.artist) — \(track.title)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                } else {
                    Text("Idle")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            Spacer()
            
            // Status indicator
            if participant.isPlaying {
                Image(systemName: "waveform")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.hotPink)
                    .symbolEffect(.variableColor.iterative)
            }
            
            // Latest reaction
            if let reaction = participant.latestReaction {
                Text(reaction.emoji)
                    .font(.system(size: 16))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        
        Divider()
            .background(Theme.cardBg)
            .padding(.leading, 68)
    }
    
    private var createSessionSheet: some View {
        VStack(spacing: 20) {
            Text("Start Live Session")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text("Create a session to listen with friends in real-time")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            
            TextField("Session name (optional)", text: $sessionName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    sessionName = ""
                    showingCreateSession = false
                }
                .foregroundColor(Theme.textSecondary)
                
                Button("Start") {
                    let hostId = UUID()
                    let session = socialService.createLiveSession(hostId: hostId)
                    currentSession = session
                    socialService.joinSession(session.id, userId: hostId, displayName: "You")
                    sessionName = ""
                    showingCreateSession = false
                }
                .foregroundColor(Theme.hotPink)
                .fontWeight(.semibold)
            }
        }
        .padding(24)
        .frame(width: 320, height: 220)
        .background(Theme.surface)
    }
    
    private func endSession() {
        if let session = currentSession {
            socialService.leaveSession(session.id, userId: UUID())
            currentSession = nil
        }
    }
}

// MARK: - FriendActivityView (Bonus - Activity Feed)

struct FriendActivityView: View {
    @ObservedObject private var socialService = SocialMusicService.shared
    @State private var selectedFilter: ActivityFilter = .all
    
    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case listening = "Listening"
        case playlists = "Playlists"
    }
    
    var filteredActivity: [FriendActivity] {
        let all = socialService.getFriendActivity()
        switch selectedFilter {
        case .all: return all
        case .listening: return all.filter { $0.activityType == .listening || $0.activityType == .finished }
        case .playlists: return all.filter { $0.activityType == .addedToPlaylist || $0.activityType == .startedPlaylist }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Friend Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Filter pills
            HStack(spacing: 8) {
                ForEach(ActivityFilter.allCases, id: \.self) { filter in
                    filterPill(filter)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            Divider()
                .background(Theme.cardBg)
            
            if filteredActivity.isEmpty {
                emptyActivityView
            } else {
                activityList
            }
        }
    }
    
    private func filterPill(_ filter: ActivityFilter) -> some View {
        Button(action: { selectedFilter = filter }) {
            Text(filter.rawValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(selectedFilter == filter ? .white : Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(selectedFilter == filter ? Theme.hotPink : Theme.cardBg)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var emptyActivityView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 36))
                .foregroundColor(Theme.textSecondary)
            Text("No activity yet")
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
    }
    
    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredActivity) { activity in
                    activityRow(activity)
                }
            }
        }
    }
    
    @ViewBuilder
    private func activityRow(_ activity: FriendActivity) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.cardBg)
                    .frame(width: 40, height: 40)
                
                Text(String(activity.friend.displayName.prefix(1)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.deepPurple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(activity.friend.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text(activityVerb(activity.activityType))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.hotPink)
                    
                    Text("\(activity.track.artist) — \(activity.track.title)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(activity.timeAgo)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
                
                activityTypeIcon(activity.activityType)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        
        Divider()
            .background(Theme.cardBg)
            .padding(.leading, 68)
    }
    
    private func activityVerb(_ type: FriendActivity.ActivityType) -> String {
        switch type {
        case .listening: return "is listening to"
        case .finished: return "finished"
        case .addedToPlaylist: return "added to playlist"
        case .startedPlaylist: return "started a playlist"
        case .reaction: return "reacted to"
        }
    }
    
    @ViewBuilder
    private func activityTypeIcon(_ type: FriendActivity.ActivityType) -> some View {
        switch type {
        case .listening:
            Image(systemName: "waveform")
                .font(.system(size: 12))
                .foregroundColor(Theme.hotPink)
        case .finished:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
        case .addedToPlaylist:
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.deepPurple)
        case .startedPlaylist:
            Image(systemName: "play.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.hotPink)
        case .reaction:
            Image(systemName: "face.smiling.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
        }
    }
}
