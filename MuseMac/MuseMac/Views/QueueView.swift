import SwiftUI

struct QueueView: View {
    @ObservedObject private var playerService = MusicPlayerService.shared
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Queue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { isEditing.toggle() }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.hotPink)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Theme.cardBg)
            
            if playerService.state.queue.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textSecondary.opacity(0.5))
                    Text("Your queue is empty")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                    Text("Add songs from your library")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary.opacity(0.7))
                    Spacer()
                }
            } else {
                List {
                    // Now Playing section
                    if let currentTrack = playerService.state.currentTrack {
                        Section {
                            QueueRow(
                                track: currentTrack,
                                isCurrent: true,
                                onTap: {}
                            )
                        } header: {
                            Text("NOW PLAYING")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    
                    // Up Next section
                    if !playerService.state.upNext.isEmpty {
                        Section {
                            ForEach(playerService.state.upNext) { track in
                                QueueRow(
                                    track: track,
                                    isCurrent: false,
                                    onTap: { playerService.playTrack(track) }
                                )
                            }
                            .onMove { source, destination in
                                playerService.moveTrack(from: source, to: destination)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let actualIndex = playerService.state.queueIndex + 1 + index
                                    playerService.removeTrack(at: actualIndex)
                                }
                            }
                        } header: {
                            HStack {
                                Text("UP NEXT")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                if isEditing {
                                    Text("Reordering enabled")
                                        .font(.system(size: 9))
                                        .foregroundColor(Theme.hotPink)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.surface)
    }
}

struct QueueRow: View {
    let track: Track
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Album art
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.cardBg)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "music.note")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 12, weight: isCurrent ? .semibold : .medium))
                    .foregroundColor(isCurrent ? Theme.hotPink : Theme.textPrimary)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.hotPink)
            }
            
            Text(track.formattedDuration)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .listRowBackground(Theme.surface)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}
