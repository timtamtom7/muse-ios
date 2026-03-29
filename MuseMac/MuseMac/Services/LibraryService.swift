import Foundation

final class LibraryService: ObservableObject, @unchecked Sendable {
    nonisolated(unsafe) static let shared = LibraryService()
    
    @Published var tracks: [Track] = []
    @Published var playlists: [Playlist] = []
    @Published var searchQuery: String = ""
    @Published var sortOption: SortOption = .title
    
    enum SortOption: String, CaseIterable {
        case title = "Title"
        case artist = "Artist"
        case album = "Album"
        case duration = "Duration"
    }
    
    var filteredTracks: [Track] {
        var result = tracks
        
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.artist.localizedCaseInsensitiveContains(searchQuery) ||
                $0.album.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        switch sortOption {
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
    
    private init() {
        Task { @MainActor in
            loadSampleData()
        }
    }
    
    @MainActor
    private func loadSampleData() {
        tracks = [
            Track(title: "Midnight City", artist: "M83", album: "Hurry Up, We're Dreaming", duration: 243),
            Track(title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", duration: 200),
            Track(title: "Starboy", artist: "The Weeknd", album: "Starboy", duration: 230),
            Track(title: "Electric Feel", artist: "MGMT", album: "Oracular Spectacular", duration: 229),
            Track(title: "Take On Me", artist: "a-ha", album: "Hunting High and Low", duration: 225),
            Track(title: "Dreams", artist: "Fleetwood Mac", album: "Rumours", duration: 254),
            Track(title: "Africa", artist: "Toto", album: "Toto IV", duration: 295),
            Track(title: "Billie Jean", artist: "Michael Jackson", album: "Thriller", duration: 294),
            Track(title: "Bohemian Rhapsody", artist: "Queen", album: "A Night at the Opera", duration: 354),
            Track(title: "Sweet Child O' Mine", artist: "Guns N' Roses", album: "Appetite for Destruction", duration: 356),
            Track(title: "Smells Like Teen Spirit", artist: "Nirvana", album: "Nevermind", duration: 301),
            Track(title: "Wonderwall", artist: "Oasis", album: "Morning Glory!", duration: 258),
            Track(title: "Losing My Religion", artist: "R.E.M.", album: "Out of Time", duration: 269),
            Track(title: "Creep", artist: "Radiohead", album: "Pablo Honey", duration: 238),
            Track(title: "Under the Bridge", artist: "Red Hot Chili Peppers", album: "Blood Sugar Sex Magik", duration: 263),
        ]
        
        playlists = [
            Playlist(name: "Favorites", tracks: Array(tracks.prefix(5))),
            Playlist(name: "80s Hits", tracks: [tracks[4], tracks[7], tracks[8]]),
            Playlist(name: "Chill Vibes", tracks: Array(tracks.suffix(4))),
        ]
    }
    
    @MainActor
    func createPlaylist(name: String) {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
    }
    
    @MainActor
    func renamePlaylist(_ playlist: Playlist, to name: String) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].name = name
        }
    }
    
    @MainActor
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
    }
    
    @MainActor
    func addTrackToPlaylist(_ track: Track, playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].tracks.append(track)
        }
    }
}
