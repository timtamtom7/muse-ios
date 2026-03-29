import SwiftUI

struct LibraryView: View {
    @ObservedObject private var libraryService = LibraryService.shared
    @ObservedObject private var playerService = MusicPlayerService.shared
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Library")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                // Sort menu
                Menu {
                    ForEach(LibraryService.SortOption.allCases, id: \.self) { option in
                        Button(action: { libraryService.sortOption = option }) {
                            HStack {
                                Text(option.rawValue)
                                if libraryService.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Sort: \(libraryService.sortOption.rawValue)")
                            .font(.system(size: 11))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Theme.textSecondary)
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.textSecondary)
                    .font(.system(size: 12))
                
                TextField("Search songs...", text: $libraryService.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.cardBg)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            
            Divider()
                .background(Theme.cardBg)
                .padding(.top, 8)
            
            // Songs list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredTracks) { track in
                        LibraryRow(
                            track: track,
                            isPlaying: playerService.state.currentTrack == track,
                            onTap: { playerService.playTrack(track) },
                            onDoubleTap: {
                                playerService.playTrack(track)
                                playerService.play()
                            }
                        )
                    }
                }
            }
        }
        .background(Theme.surface)
    }
    
    private var filteredTracks: [Track] {
        var result = libraryService.tracks
        
        if !libraryService.searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(libraryService.searchQuery) ||
                $0.artist.localizedCaseInsensitiveContains(libraryService.searchQuery) ||
                $0.album.localizedCaseInsensitiveContains(libraryService.searchQuery)
            }
        }
        
        switch libraryService.sortOption {
        case .title:
            result.sort { $0.title < $1.title }
        case .artist:
            result.sort { $0.artist < $1.artist }
        case .album:
            result.sort { $0.album < $1.album }
        case .duration:
            result.sort { $0.duration < $1.duration }
        }
        
        return result
    }
}

struct LibraryRow: View {
    let track: Track
    let isPlaying: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    
    @State private var lastTapTime: Date?
    
    var body: some View {
        HStack(spacing: 12) {
            // Album art thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.cardBg)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "music.note")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
            
            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isPlaying ? Theme.hotPink : Theme.textPrimary)
                    .lineLimit(1)
                
                Text("\(track.artist) • \(track.album)")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration
            Text(track.formattedDuration)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
            
            // Playing indicator
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.hotPink)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(isPlaying ? Theme.cardBg.opacity(0.5) : Color.clear)
        .onTapGesture {
            let now = Date()
            if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) < 0.3 {
                onDoubleTap()
                lastTapTime = nil
            } else {
                onTap()
                lastTapTime = now
            }
        }
    }
}
