import Foundation
import Combine

final class MusicPlayerService: ObservableObject, @unchecked Sendable {
    nonisolated(unsafe) static let shared = MusicPlayerService()
    
    @Published var state = PlayerState()
    
    private var progressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        Task { @MainActor in
            loadSampleData()
        }
    }
    
    @MainActor
    private func loadSampleData() {
        let tracks = [
            Track(title: "Midnight City", artist: "M83", album: "Hurry Up, We're Dreaming", duration: 243),
            Track(title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", duration: 200),
            Track(title: "Starboy", artist: "The Weeknd", album: "Starboy", duration: 230),
            Track(title: "Electric Feel", artist: "MGMT", album: "Oracular Spectacular", duration: 229),
            Track(title: "Take On Me", artist: "a-ha", album: "Hunting High and Low", duration: 225),
            Track(title: "Dreams", artist: "Fleetwood Mac", album: "Rumours", duration: 254),
            Track(title: "Africa", artist: "Toto", album: "Toto IV", duration: 295),
            Track(title: "Billie Jean", artist: "Michael Jackson", album: "Thriller", duration: 294),
        ]
        
        state.queue = tracks
        state.currentTrack = tracks.first
        state.queueIndex = 0
    }
    
    @MainActor
    func togglePlayPause() {
        switch state.playbackState {
        case .playing:
            pause()
        case .paused, .stopped:
            play()
        }
    }
    
    @MainActor
    func play() {
        guard state.hasTrack else { return }
        state.playbackState = .playing
        startProgressTimer()
    }
    
    @MainActor
    func pause() {
        state.playbackState = .paused
        stopProgressTimer()
    }
    
    @MainActor
    func stop() {
        state.playbackState = .stopped
        state.progress = 0
        stopProgressTimer()
    }
    
    @MainActor
    func next() {
        guard state.queueIndex < state.queue.count - 1 else {
            stop()
            return
        }
        state.queueIndex += 1
        state.currentTrack = state.queue[state.queueIndex]
        state.progress = 0
        if state.playbackState == .playing {
            startProgressTimer()
        }
    }
    
    @MainActor
    func previous() {
        if state.progress > 3 {
            state.progress = 0
            return
        }
        guard state.queueIndex > 0 else { return }
        state.queueIndex -= 1
        state.currentTrack = state.queue[state.queueIndex]
        state.progress = 0
    }
    
    @MainActor
    func seek(to progress: Double) {
        state.progress = progress
    }
    
    @MainActor
    func setVolume(_ volume: Double) {
        state.volume = volume
    }
    
    @MainActor
    func playTrack(_ track: Track) {
        if let index = state.queue.firstIndex(of: track) {
            state.queueIndex = index
            state.currentTrack = track
            state.progress = 0
            play()
        }
    }
    
    @MainActor
    func playTrack(at index: Int) {
        guard index >= 0 && index < state.queue.count else { return }
        state.queueIndex = index
        state.currentTrack = state.queue[index]
        state.progress = 0
        play()
    }
    
    @MainActor
    func moveTrack(from source: IndexSet, to destination: Int) {
        state.queue.move(fromOffsets: source, toOffset: destination)
        if let sourceIndex = source.first {
            if sourceIndex < state.queueIndex && destination > state.queueIndex {
                state.queueIndex -= 1
            } else if sourceIndex > state.queueIndex && destination <= state.queueIndex {
                state.queueIndex += 1
            } else if sourceIndex == state.queueIndex {
                state.queueIndex = destination > sourceIndex ? destination - 1 : destination
            }
        }
    }
    
    @MainActor
    func removeTrack(at index: Int) {
        guard index >= 0 && index < state.queue.count else { return }
        state.queue.remove(at: index)
        if index < state.queueIndex {
            state.queueIndex -= 1
        } else if index == state.queueIndex {
            if state.queueIndex >= state.queue.count {
                state.queueIndex = max(0, state.queue.count - 1)
            }
            state.currentTrack = state.queue[safe: state.queueIndex]
        }
    }
    
    @MainActor
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.incrementProgress()
            }
        }
    }
    
    @MainActor
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    @MainActor
    private func incrementProgress() {
        guard let track = state.currentTrack else { return }
        if state.progress < track.duration {
            state.progress += 1
        } else {
            next()
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
