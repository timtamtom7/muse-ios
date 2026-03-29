import SwiftUI

struct ListeningInsightsView: View {
    @ObservedObject private var libraryService = LibraryService.shared
    @ObservedObject private var aiService = AIMusicService.shared

    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case allTime = "All Time"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().background(Theme.cardBg)

            ScrollView {
                VStack(spacing: 20) {
                    timeRangePicker
                    genreBreakdownSection
                    listeningStatsSection
                    weeklyChartSection
                    topArtistsSection
                }
                .padding(16)
            }
        }
        .background(Theme.vinylBlack)
        .onAppear {
            aiService.updateInsights(from: libraryService.tracks)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.gradient)

            Text("Listening Insights")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            Image(systemName: "arrow.clockwise")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .onTapGesture {
                    aiService.updateInsights(from: libraryService.tracks)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 12, weight: selectedTimeRange == range ? .semibold : .regular))
                        .foregroundColor(selectedTimeRange == range ? .white : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            selectedTimeRange == range ?
                            Theme.gradient.clipShape(Capsule()) :
                            Color.clear.clipShape(Capsule())
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.cardBg)
        .clipShape(Capsule())
    }

    // MARK: - Genre Breakdown

    private var genreBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Your Music Taste", icon: "music.note.list")

            VStack(spacing: 8) {
                ForEach(insights.favoriteGenres) { genre in
                    GenreBar(genre: genre)
                }

                if insights.favoriteGenres.isEmpty {
                    Text("Play some music to see your taste profile")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(14)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Stats Cards

    private var listeningStatsSection: some View {
        HStack(spacing: 10) {
            StatCard(
                title: "Hours Listened",
                value: String(format: "%.1f", insights.totalListeningHours),
                icon: "clock.fill",
                color: Theme.hotPink
            )

            StatCard(
                title: "Tracks Played",
                value: "\(libraryService.tracks.count)",
                icon: "play.circle.fill",
                color: Theme.deepPurple
            )

            StatCard(
                title: "Genres Found",
                value: "\(max(1, insights.favoriteGenres.count))",
                icon: "music.note",
                color: .orange
            )
        }
    }

    // MARK: - Weekly Chart

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Weekly Activity", icon: "chart.line.uptrend.xyaxis")

            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(insights.weeklyListeningMinutes.enumerated()), id: \.offset) { index, minutes in
                        WeekBar(day: dayLabel(for: index), minutes: minutes, isToday: index == todayIndex)
                    }
                }
                .frame(height: 80)
                .padding(.horizontal, 8)

                HStack {
                    Text("Mon").font(.system(size: 10)).foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("Sun").font(.system(size: 10)).foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 8)
            }
            .padding(14)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Top Artists

    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Top Artists", icon: "person.fill")

            VStack(spacing: 0) {
                ForEach(Array(insights.topArtists.enumerated()), id: \.element.id) { index, artist in
                    ArtistRow(rank: index + 1, artist: artist)

                    if index < insights.topArtists.count - 1 {
                        Divider()
                            .background(Theme.cardBg.opacity(0.5))
                            .padding(.leading, 44)
                    }
                }

                if insights.topArtists.isEmpty {
                    Text("Your top artists will appear here")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(14)
            .background(Theme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private var insights: ListeningInsights {
        aiService.lastInsights
    }

    private var todayIndex: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    private func dayLabel(for index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Theme.hotPink)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Genre Bar

struct GenreBar: View {
    let genre: GenreCount

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(genre.genre)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(Int(genre.percentage))%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.surface)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.gradient)
                        .frame(width: geometry.size.width * min(genre.percentage / 100, 1))
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Week Bar

struct WeekBar: View {
    let day: String
    let minutes: Int
    let isToday: Bool

    private var barHeight: CGFloat {
        let maxMinutes: CGFloat = 120
        return max(4, min(60, CGFloat(minutes) / maxMinutes * 60))
    }

    var body: some View {
        VStack(spacing: 4) {
            Spacer()

            RoundedRectangle(cornerRadius: 2)
                .fill(isToday ? Theme.hotPink : Theme.deepPurple.opacity(0.7))
                .frame(width: 16, height: barHeight)

            Text(day)
                .font(.system(size: 9, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? Theme.hotPink : Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Artist Row

struct ArtistRow: View {
    let rank: Int
    let artist: ArtistCount

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(rankColor)
                .frame(width: 20)

            Circle()
                .fill(Theme.gradient)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(artist.artist.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(artist.artist)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text("\(artist.playCount) plays")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Theme.textSecondary
        case 3: return Color(hex: "CD7F32")
        default: return Theme.textSecondary
        }
    }
}
