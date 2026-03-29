import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @ObservedObject private var playerService = MusicPlayerService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(MenuBarViewModel.Tab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.rawValue,
                        isSelected: viewModel.selectedTab == tab
                    ) {
                        viewModel.selectedTab = tab
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .background(Theme.surface)
            
            Divider()
                .background(Theme.cardBg)
            
            // Content
            TabView(selection: $viewModel.selectedTab) {
                NowPlayingView()
                    .tag(MenuBarViewModel.Tab.nowPlaying)
                
                LibraryView()
                    .tag(MenuBarViewModel.Tab.library)
                
                PlaylistsView()
                    .tag(MenuBarViewModel.Tab.playlists)
                
                QueueView()
                    .tag(MenuBarViewModel.Tab.queue)
            }
            .tabViewStyle(.automatic)
            .background(Theme.surface)
        }
        .frame(width: 340, height: 480)
        .background(Theme.surface)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Theme.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }
}
