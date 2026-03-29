import SwiftUI

struct NowPlayingView: View {
    @ObservedObject private var playerService = MusicPlayerService.shared
    @State private var isDraggingProgress = false
    @State private var dragProgress: Double = 0
    @State private var waveformPhase: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Album Art
            AlbumArtView(track: playerService.state.currentTrack)
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            
            // Track Info
            if let track = playerService.state.currentTrack {
                VStack(spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                    
                    Text(track.album)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary.opacity(0.7))
                        .lineLimit(1)
                }
            } else {
                Text("No Track Playing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }
            
            // Waveform Visualization
            WaveformView(phase: waveformPhase, isPlaying: playerService.state.isPlaying)
                .frame(height: 40)
                .padding(.horizontal, 20)
            
            // Progress Bar
            VStack(spacing: 4) {
                ProgressSlider(
                    value: isDraggingProgress ? dragProgress : playerService.state.progress,
                    maximumValue: playerService.state.currentTrack?.duration ?? 1,
                    onDragChanged: { value in
                        isDraggingProgress = true
                        dragProgress = value
                    },
                    onDragEnded: { value in
                        playerService.seek(to: value)
                        isDraggingProgress = false
                    }
                )
                
                HStack {
                    Text(formatTime(isDraggingProgress ? dragProgress : playerService.state.progress))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    
                    Spacer()
                    
                    Text(formatTime(playerService.state.currentTrack?.duration ?? 0))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Playback Controls
            HStack(spacing: 32) {
                Button(action: { playerService.previous() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textPrimary)
                }
                .buttonStyle(.plain)
                
                Button(action: { playerService.togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(Theme.gradient)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: playerService.state.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                
                Button(action: { playerService.next() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textPrimary)
                }
                .buttonStyle(.plain)
            }
            
            // Volume Slider
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                
                Slider(value: Binding(
                    get: { playerService.state.volume },
                    set: { playerService.setVolume($0) }
                ), in: 0...1)
                .accentColor(Theme.hotPink)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 20)
        .background(Theme.surface)
        .onAppear {
            startWaveformAnimation()
        }
    }
    
    private func startWaveformAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if playerService.state.isPlaying {
                waveformPhase += 0.1
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AlbumArtView: View {
    let track: Track?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Theme.deepPurple, Theme.hotPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct WaveformView: View {
    let phase: Double
    let isPlaying: Bool
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    WaveformBar(
                        index: index,
                        phase: phase,
                        isPlaying: isPlaying,
                        height: geometry.size.height
                    )
                }
            }
        }
    }
}

struct WaveformBar: View {
    let index: Int
    let phase: Double
    let isPlaying: Bool
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Theme.deepPurple, Theme.hotPink],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 6)
            .frame(height: barHeight)
            .animation(.easeInOut(duration: 0.1), value: barHeight)
    }
    
    private var barHeight: CGFloat {
        guard isPlaying else { return 4 }
        let normalizedIndex = Double(index) / 30.0
        let wave1 = sin(phase + normalizedIndex * .pi * 4)
        let wave2 = sin(phase * 1.5 + normalizedIndex * .pi * 2)
        let combined = (wave1 + wave2) / 2
        return max(4, (combined + 1) / 2 * (height - 4))
    }
}

struct ProgressSlider: View {
    let value: Double
    let maximumValue: Double
    let onDragChanged: (Double) -> Void
    let onDragEnded: (Double) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.cardBg)
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.gradient)
                    .frame(width: progressWidth(in: geometry.size.width), height: 4)
                
                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: isDragging ? 14 : 12, height: isDragging ? 14 : 12)
                    .offset(x: thumbOffset(in: geometry.size.width))
                    .animation(.easeOut(duration: 0.1), value: isDragging)
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        isDragging = true
                        let newValue = (gesture.location.x / geometry.size.width) * maximumValue
                        onDragChanged(min(0, max(maximumValue, newValue)))
                    }
                    .onEnded { gesture in
                        isDragging = false
                        let newValue = (gesture.location.x / geometry.size.width) * maximumValue
                        onDragEnded(min(0, max(maximumValue, newValue)))
                    }
            )
        }
        .frame(height: 20)
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard maximumValue > 0 else { return 0 }
        return totalWidth * CGFloat(value / maximumValue)
    }
    
    private func thumbOffset(in totalWidth: CGFloat) -> CGFloat {
        guard maximumValue > 0 else { return 0 }
        return totalWidth * CGFloat(value / maximumValue) - 6
    }
}
