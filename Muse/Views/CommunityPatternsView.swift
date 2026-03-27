import SwiftUI

struct CommunityPatternsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var communityService = CommunityPatternsService.shared
    @State private var patternManager = BreathingPatternManager.shared
    @State private var subscriptionManager = SubscriptionManager.shared

    @State private var searchText = ""
    @State private var selectedTab: CommunityTab = .popular
    @State private var showShareSheet = false
    @State private var selectedCommunityPattern: CommunityPattern?
    @State private var showImportConfirmation = false

    enum CommunityTab: String, CaseIterable {
        case popular = "Popular"
        case recent = "Recent"
        case mine = "Mine"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050508")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6b6560"))

                        TextField("Search patterns, tags...", text: $searchText)
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: "e8d5c4"))
                            .autocorrectionDisabled()
                    }
                    .padding(12)
                    .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Tab picker
                    Picker("", selection: $selectedTab) {
                        ForEach(CommunityTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Content
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            if selectedTab == .mine {
                                // My shared patterns
                                if communityService.mySharedPatterns.isEmpty {
                                    emptyMineState
                                } else {
                                    ForEach(filteredMyPatterns) { pattern in
                                        CommunityPatternCard(
                                            communityPattern: pattern,
                                            onImport: nil,
                                            onDelete: {
                                                communityService.deleteMySharedPattern(pattern)
                                            }
                                        )
                                    }
                                }
                            } else {
                                // Popular or Recent
                                ForEach(displayedPatterns) { pattern in
                                    CommunityPatternCard(
                                        communityPattern: pattern,
                                        onImport: {
                                            selectedCommunityPattern = pattern
                                            showImportConfirmation = true
                                        },
                                        onDelete: nil
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560"))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "e8d5c4"))
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                SharePatternSheet()
            }
            .alert("Import Pattern", isPresented: $showImportConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Import") {
                    if let pattern = selectedCommunityPattern {
                        let imported = communityService.importPattern(pattern)
                        patternManager.addCustomPattern(imported)
                        patternManager.saveSelectedPattern(imported)
                    }
                }
            } message: {
                if let pattern = selectedCommunityPattern {
                    Text("Import \"\(pattern.pattern.name)\" by \(pattern.authorName)?")
                }
            }
        }
        .tint(Color(hex: "e8d5c4"))
    }

    private var displayedPatterns: [CommunityPattern] {
        let source = selectedTab == .popular
            ? communityService.popularPatternsThisWeek
            : communityService.communityPatterns

        if searchText.isEmpty {
            return source
        }
        return communityService.searchPatterns(query: searchText)
    }

    private var filteredMyPatterns: [CommunityPattern] {
        if searchText.isEmpty {
            return communityService.mySharedPatterns
        }
        return communityService.mySharedPatterns.filter { cp in
            cp.pattern.name.lowercased().contains(searchText.lowercased())
        }
    }

    private var emptyMineState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "6b6560").opacity(0.5))

            Text("No shared patterns yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: "e8d5c4"))

            Text("Share your favorite breathing patterns with the community.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6b6560"))
                .multilineTextAlignment(.center)

            Button {
                showShareSheet = true
            } label: {
                Text("Share a pattern")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "050508"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "e8d5c4"), in: Capsule())
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Community Pattern Card

struct CommunityPatternCard: View {
    let communityPattern: CommunityPattern
    let onImport: (() -> Void)?
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(communityPattern.pattern.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(hex: "e8d5c4"))

                    Text("by \(communityPattern.authorName)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6b6560"))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 11))
                    Text("\(communityPattern.downloads)")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Color(hex: "6b6560").opacity(0.7))
            }

            // Description
            Text(communityPattern.description)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6b6560"))
                .lineLimit(2)

            // Pattern rhythm visualization
            HStack(spacing: 6) {
                PatternRhythmBar(label: "In", seconds: Int(communityPattern.pattern.inhaleSeconds), color: Color(hex: "e8d5c4"))
                PatternRhythmBar(label: "Hold", seconds: Int(communityPattern.pattern.holdInSeconds), color: Color(hex: "c4b5a0"))
                PatternRhythmBar(label: "Out", seconds: Int(communityPattern.pattern.exhaleSeconds), color: Color(hex: "a09890"))
                PatternRhythmBar(label: "Hold", seconds: Int(communityPattern.pattern.holdOutSeconds), color: Color(hex: "7a7068"))
                Spacer()

                if let onImport = onImport {
                    Button {
                        onImport()
                    } label: {
                        Text("Import")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "050508"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "e8d5c4"), in: Capsule())
                    }
                }

                if let onDelete = onDelete {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "c4a87a"))
                    }
                }
            }

            // Tags
            if !communityPattern.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(communityPattern.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color(hex: "c4b5a0"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "2a2520"), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: Theme.CornerRadius.extraLarge))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.extraLarge)
                .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
        )
    }
}

// MARK: - Pattern Rhythm Bar

struct PatternRhythmBar: View {
    let label: String
    let seconds: Int
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(seconds == 0 ? "—" : "\(seconds)s")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(color)

            RoundedRectangle(cornerRadius: Theme.CornerRadius.extraSmall)
                .fill(color.opacity(seconds == 0 ? 0.2 : 0.6))
                .frame(width: 28, height: 4)
        }
    }
}

// MARK: - Share Pattern Sheet

struct SharePatternSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var patternManager = BreathingPatternManager.shared
    @State private var communityService = CommunityPatternsService.shared
    @State private var selectedPattern: BreathingPattern?
    @State private var description = ""
    @State private var tagsText = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050508")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Pattern selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pattern to share")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))

                            if let selected = selectedPattern {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selected.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Color(hex: "e8d5c4"))

                                        Text("In \(Int(selected.inhaleSeconds))s · Out \(Int(selected.exhaleSeconds))s")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color(hex: "6b6560"))
                                    }

                                    Spacer()

                                    Button {
                                        selectedPattern = nil
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color(hex: "6b6560"))
                                    }
                                }
                                .padding(12)
                                .background(Color(hex: "1e1e24"), in: RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                            } else {
                                Menu {
                                    ForEach(patternManager.allPatterns) { pattern in
                                        Button {
                                            selectedPattern = pattern
                                        } label: {
                                            Text(pattern.name)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text("Select a pattern")
                                            .font(.system(size: 15))
                                            .foregroundStyle(Color(hex: "6b6560"))
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color(hex: "6b6560"))
                                    }
                                    .padding(12)
                                    .background(Color(hex: "1e1e24"), in: RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                                }
                            }
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))

                            TextField("What makes this pattern special?", text: $description, axis: .vertical)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(hex: "e8d5c4"))
                                .lineLimit(3...5)
                                .padding(12)
                                .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
                                )
                        }

                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))

                            TextField("e.g. sleep, focus, beginner (comma separated)", text: $tagsText)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(hex: "e8d5c4"))
                                .padding(12)
                                .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
                                )
                        }

                        // Popular tags hint
                        if !communityService.allTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Popular tags")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "6b6560").opacity(0.6))

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(communityService.allTags.prefix(8), id: \.self) { tag in
                                            Button {
                                                if !tagsText.isEmpty && !tagsText.hasSuffix(",") && !tagsText.hasSuffix(" ") {
                                                    tagsText += ", "
                                                }
                                                tagsText += tag
                                            } label: {
                                                Text(tag)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundStyle(Color(hex: "c4b5a0"))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color(hex: "2a2520"), in: Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Share Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "6b6560"))
                    .font(.system(size: 15))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Share") {
                        sharePattern()
                    }
                    .foregroundStyle(Color(hex: "e8d5c4"))
                    .font(.system(size: 15, weight: .medium))
                    .disabled(selectedPattern == nil)
                }
            }
            .alert("Cannot share", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please select a pattern to share.")
            }
        }
        .tint(Color(hex: "e8d5c4"))
    }

    private func sharePattern() {
        guard let pattern = selectedPattern else {
            showError = true
            return
        }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        communityService.sharePattern(pattern, description: description, tags: tags)
        dismiss()
    }
}

#Preview {
    CommunityPatternsView()
}
