import SwiftUI

struct PlaylistGeneratorView: View {
    @ObservedObject private var libraryService = LibraryService.shared
    @ObservedObject private var aiService = AIMusicService.shared

    @State private var selectedMood: PlaylistMood?
    @State private var generatedPlaylist: [Track] = []
    @State private var isGenerating = false
    @State private var playlistName: String = ""
    @State private var showingSaveConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider().background(Theme.cardBg)

            ScrollView {
                VStack(spacing: 24) {
                    if generatedPlaylist.isEmpty && !isGenerating {
                        moodSelectorSection
                    } else if isGenerating {
                        generatingView
                    } else {
                        generatedPlaylistSection
                    }
                }
                .padding(16)
            }
        }
        .background(Theme.vinylBlack)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "waveform.badge.magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.gradient)

            Text("AI Playlist Generator")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            if !generatedPlaylist.isEmpty {
                Button("Reset") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        generatedPlaylist = []
                        selectedMood = nil
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.hotPink)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Mood Selector

    private var moodSelectorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What vibe are you after?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ], spacing: 10) {
                ForEach(PlaylistMood.allCases) { mood in
                    MoodCard(
                        mood: mood,
                        isSelected: selectedMood == mood
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMood = mood
                        }
                        generateForMood(mood)
                    }
                }
            }
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(Theme.hotPink)
            Text("Curating your \(selectedMood?.rawValue.lowercased() ?? "") playlist...")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Generated Playlist

    private var generatedPlaylistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Playlist info header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your \(selectedMood?.rawValue.lowercased() ?? "custom") playlist")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    Text("\(generatedPlaylist.count) tracks • ~\(estimatedDuration) min")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Button(action: savePlaylist) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                        Text("Save")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.gradient)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Track list
            VStack(spacing: 0) {
                ForEach(Array(generatedPlaylist.enumerated()), id: \.element.id) { index, track in
                    GeneratedTrackRow(track: track, index: index + 1)

                    if index < generatedPlaylist.count - 1 {
                        Divider()
                            .background(Theme.cardBg.opacity(0.5))
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var estimatedDuration: Int {
        let total = generatedPlaylist.reduce(0) { $0 + $1.duration }
        return total / 60
    }

    // MARK: - Actions

    private func generateForMood(_ mood: PlaylistMood) {
        isGenerating = true
        generatedPlaylist = []

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let tracks = aiService.generatePlaylist(for: mood, from: libraryService.tracks, count: 25)
            withAnimation(.easeInOut(duration: 0.3)) {
                generatedPlaylist = tracks
                isGenerating = false
            }
        }
    }

    private func savePlaylist() {
        guard !generatedPlaylist.isEmpty else { return }
        let moodName = selectedMood?.rawValue ?? "Custom"
        let name = "\(moodName) Mix"
        let playlist = Playlist(name: name, tracks: generatedPlaylist)

        DispatchQueue.main.async {
            libraryService.playlists.append(playlist)
            showingSaveConfirmation = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingSaveConfirmation = false
            }
        }
    }
}

// MARK: - Mood Card

struct MoodCard: View {
    let mood: PlaylistMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: mood.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.gradient : LinearGradient(colors: [Theme.textSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))

                Text(mood.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)

                Text(mood.description)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.cardBg : Theme.vinylBlack)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Theme.hotPink.opacity(0.5) : Theme.cardBg, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Generated Track Row

struct GeneratedTrackRow: View {
    let track: Track
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text("\(track.artist) • \(track.album)")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(track.formattedDuration)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
