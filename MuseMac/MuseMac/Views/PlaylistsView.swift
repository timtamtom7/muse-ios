import SwiftUI

struct PlaylistsView: View {
    @ObservedObject private var libraryService = LibraryService.shared
    @State private var showingCreateSheet = false
    @State private var newPlaylistName = ""
    @State private var editingPlaylist: Playlist?
    @State private var editingName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Playlists")
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
            
            // Playlists list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(libraryService.playlists) { playlist in
                        PlaylistRow(
                            playlist: playlist,
                            onRename: {
                                editingPlaylist = playlist
                                editingName = playlist.name
                            },
                            onDelete: {
                                libraryService.deletePlaylist(playlist)
                            }
                        )
                    }
                }
            }
        }
        .background(Theme.surface)
        .sheet(isPresented: $showingCreateSheet) {
            CreatePlaylistSheet(
                playlistName: $newPlaylistName,
                onCancel: {
                    showingCreateSheet = false
                    newPlaylistName = ""
                },
                onCreate: {
                    libraryService.createPlaylist(name: newPlaylistName)
                    showingCreateSheet = false
                    newPlaylistName = ""
                }
            )
        }
        .sheet(item: $editingPlaylist) { playlist in
            EditPlaylistSheet(
                playlistName: $editingName,
                onCancel: {
                    editingPlaylist = nil
                    editingName = ""
                },
                onSave: {
                    libraryService.renamePlaylist(playlist, to: editingName)
                    editingPlaylist = nil
                    editingName = ""
                }
            )
        }
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    let onRename: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Cover mosaic
            PlaylistCoverView(tracks: playlist.tracks)
                .frame(width: 48, height: 48)
            
            // Playlist info
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Text("\(playlist.trackCount) songs")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            // Context menu
            Menu {
                Button(action: onRename) {
                    Label("Rename", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .padding(8)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct PlaylistCoverView: View {
    let tracks: [Track]
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let halfWidth = size.width / 2
            let halfHeight = size.height / 2
            
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.cardBg)
                
                if tracks.isEmpty {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.textSecondary)
                } else {
                    VStack(spacing: 1) {
                        HStack(spacing: 1) {
                            coverCell(index: 0)
                            coverCell(index: 1)
                        }
                        HStack(spacing: 1) {
                            coverCell(index: 2)
                            coverCell(index: 3)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func coverCell(index: Int) -> some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: gradientForIndex(index),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "music.note")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func gradientForIndex(_ index: Int) -> [Color] {
        let gradients: [[Color]] = [
            [Theme.deepPurple, Theme.deepPurple.opacity(0.7)],
            [Theme.hotPink, Theme.hotPink.opacity(0.7)],
            [Theme.deepPurple.opacity(0.8), Theme.hotPink.opacity(0.8)],
            [Theme.hotPink.opacity(0.6), Theme.deepPurple.opacity(0.6)],
        ]
        return gradients[index % gradients.count]
    }
}

struct CreatePlaylistSheet: View {
    @Binding var playlistName: String
    let onCancel: () -> Void
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Playlist")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            TextField("Playlist name", text: $playlistName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                
                Button("Create", action: onCreate)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.hotPink)
                    .disabled(playlistName.isEmpty)
            }
        }
        .padding(24)
        .background(Theme.surface)
    }
}

struct EditPlaylistSheet: View {
    @Binding var playlistName: String
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Playlist")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            
            TextField("Playlist name", text: $playlistName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            
            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                
                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.hotPink)
                    .disabled(playlistName.isEmpty)
            }
        }
        .padding(24)
        .background(Theme.surface)
    }
}
