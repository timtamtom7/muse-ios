import SwiftUI

struct CollaborativePlaylistView: View {
    @ObservedObject private var socialService = SocialMusicService.shared
    @State private var showingCreateSheet = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylist: CollaborativePlaylist?
    @State private var showingInviteSheet = false
    @State private var inviteEmail = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Collaborative Playlists")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { showingCreateSheet = true }) {
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
            
            if socialService.collaborativePlaylists.isEmpty {
                emptyStateView
            } else {
                playlistList
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            createPlaylistSheet
        }
        .sheet(item: $selectedPlaylist) { playlist in
            playlistDetailSheet(playlist: playlist)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.textSecondary)
            
            Text("No Collaborative Playlists")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            Text("Create a playlist and invite friends to add tracks together")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: { showingCreateSheet = true }) {
                Text("Create Playlist")
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
    
    private var playlistList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(socialService.collaborativePlaylists) { playlist in
                    CollaborativePlaylistRow(
                        playlist: playlist,
                        onTap: { selectedPlaylist = playlist }
                    )
                }
            }
        }
    }
    
    private var createPlaylistSheet: some View {
        VStack(spacing: 20) {
            Text("Create Collaborative Playlist")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            TextField("Playlist Name", text: $newPlaylistName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    newPlaylistName = ""
                    showingCreateSheet = false
                }
                .foregroundColor(Theme.textSecondary)
                
                Button("Create") {
                    if !newPlaylistName.isEmpty {
                        _ = socialService.createCollaborativePlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                        showingCreateSheet = false
                    }
                }
                .foregroundColor(Theme.hotPink)
                .fontWeight(.semibold)
            }
        }
        .padding(24)
        .frame(width: 320, height: 160)
        .background(Theme.surface)
    }
    
    private func playlistDetailSheet(playlist: CollaborativePlaylist) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(playlist.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { selectedPlaylist = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
                .background(Theme.cardBg)
            
            // Contributors summary
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Theme.hotPink)
                    .font(.system(size: 14))
                
                Text(playlist.contributorsSummary)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Button(action: { showingInviteSheet = true }) {
                    Text("Invite")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.hotPink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.cardBg)
            
            // Tracks
            if playlist.tracks.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 36))
                        .foregroundColor(Theme.textSecondary)
                    Text("No tracks yet")
                        .foregroundColor(Theme.textSecondary)
                    Text("Invite friends to start adding!")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(playlist.tracks) { track in
                            CollaborativeTrackRow(track: track, contributors: playlist.contributorNames)
                        }
                    }
                }
            }
        }
        .frame(width: 400, height: 500)
        .background(Theme.surface)
        .sheet(isPresented: $showingInviteSheet) {
            inviteSheet(playlistId: playlist.id)
        }
    }
    
    private func inviteSheet(playlistId: UUID) -> some View {
        VStack(spacing: 16) {
            Text("Invite Friends")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            TextField("Email or username", text: $inviteEmail)
                .textFieldStyle(.roundedBorder)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    inviteEmail = ""
                    showingInviteSheet = false
                }
                .foregroundColor(Theme.textSecondary)
                
                Button("Send Invite") {
                    if !inviteEmail.isEmpty {
                        let userId = UUID()
                        socialService.inviteToPlaylist(playlistId: playlistId, userId: userId)
                        inviteEmail = ""
                        showingInviteSheet = false
                    }
                }
                .foregroundColor(Theme.hotPink)
                .fontWeight(.semibold)
            }
        }
        .padding(24)
        .frame(width: 300, height: 160)
        .background(Theme.surface)
    }
}

// MARK: - CollaborativePlaylistRow

struct CollaborativePlaylistRow: View {
    let playlist: CollaborativePlaylist
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Cover mosaic or default
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.cardBg)
                    
                    if playlist.tracks.isEmpty {
                        Image(systemName: "music.note.list")
                            .foregroundColor(Theme.textSecondary)
                    } else {
                        // Show gradient if no artwork
                        Theme.gradient
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text(playlist.contributorsSummary)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Text("\(playlist.tracks.count) tracks")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        
        Divider()
            .background(Theme.cardBg)
            .padding(.leading, 76)
    }
}

// MARK: - CollaborativeTrackRow

struct CollaborativeTrackRow: View {
    let track: Track
    let contributors: [UUID: String]
    
    var body: some View {
        HStack(spacing: 12) {
            // Track artwork placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.cardBg)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(track.formattedDuration)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        
        Divider()
            .background(Theme.cardBg)
            .padding(.leading, 64)
    }
}
