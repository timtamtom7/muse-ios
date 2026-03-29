import Foundation
import Combine

final class MenuBarViewModel: ObservableObject {
    @Published var selectedTab: Tab = .nowPlaying
    @Published var showingLibrary = false
    @Published var showingPlaylists = false
    @Published var showingQueue = false
    
    let playerService = MusicPlayerService.shared
    let libraryService = LibraryService.shared
    
    enum Tab: String, CaseIterable {
        case nowPlaying = "Now Playing"
        case library = "Library"
        case playlists = "Playlists"
        case queue = "Queue"
    }
    
    init() {}
}
