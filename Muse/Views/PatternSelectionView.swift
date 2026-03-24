import SwiftUI

struct PatternSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var patternManager = BreathingPatternManager.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showCustomEditor = false
    @State private var editingPattern: BreathingPattern?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050508")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Pattern visualizer
                        BreathingPatternVisualizerView(
                            pattern: patternManager.selectedPattern,
                            isActive: false,
                            currentPhase: .idle,
                            phaseProgress: 0
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // Built-in patterns
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Presets")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))
                                .padding(.horizontal, 24)

                            ForEach(BreathingPattern.builtInPatterns) { pattern in
                                PatternPresetCard(
                                    pattern: pattern,
                                    isSelected: patternManager.selectedPattern.id == pattern.id,
                                    onTap: {
                                        patternManager.saveSelectedPattern(pattern)
                                    }
                                )
                                .padding(.horizontal, 24)
                            }
                        }

                        // Custom patterns
                        if patternManager.customPatterns.count > 0 {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Custom")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: "6b6560"))
                                    .padding(.horizontal, 24)

                                ForEach(patternManager.customPatterns) { pattern in
                                    PatternPresetCard(
                                        pattern: pattern,
                                        isSelected: patternManager.selectedPattern.id == pattern.id,
                                        onTap: {
                                            patternManager.saveSelectedPattern(pattern)
                                        }
                                    )
                                    .padding(.horizontal, 24)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            patternManager.deleteCustomPattern(pattern)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }

                        // Create custom pattern button
                        if subscriptionManager.currentTier.hasCustomBreathingPatterns {
                            Button {
                                showCustomEditor = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Create custom pattern")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "e8d5c4"))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "1e1e24"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        } else {
                            // Upgrade prompt
                            VStack(spacing: 12) {
                                Text("Custom patterns")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: "e8d5c4"))

                                Text(subscriptionManager.upgradePrompt(for: "custom_patterns"))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "6b6560"))
                                    .multilineTextAlignment(.center)

                                Button {
                                    dismiss()
                                } label: {
                                    Text("See plans")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color(hex: "050508"))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color(hex: "e8d5c4"), in: Capsule())
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "141418"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
                                    )
                            )
                            .padding(.horizontal, 24)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Breathing Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "e8d5c4"))
                    .font(.system(size: 15, weight: .medium))
                }
            }
            .sheet(isPresented: $showCustomEditor) {
                CustomPatternEditorView(
                    pattern: nil,
                    onSave: { newPattern in
                        patternManager.addCustomPattern(newPattern)
                        patternManager.saveSelectedPattern(newPattern)
                    }
                )
            }
        }
        .tint(Color(hex: "e8d5c4"))
    }
}

struct CustomPatternEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let pattern: BreathingPattern?
    let onSave: (BreathingPattern) -> Void

    @State private var name: String = ""
    @State private var inhaleSeconds: Double = 4
    @State private var holdInSeconds: Double = 2
    @State private var exhaleSeconds: Double = 4
    @State private var holdOutSeconds: Double = 2
    @State private var showError = false
    @State private var errorMessage = ""

    private var isEditing: Bool { pattern != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050508")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Preview
                        let previewPattern = BreathingPattern(
                            id: UUID(),
                            name: name.isEmpty ? "My pattern" : name,
                            inhaleSeconds: inhaleSeconds,
                            holdInSeconds: holdInSeconds,
                            exhaleSeconds: exhaleSeconds,
                            holdOutSeconds: holdOutSeconds,
                            isBuiltIn: false
                        )

                        BreathingPatternVisualizerView(
                            pattern: previewPattern,
                            isActive: false,
                            currentPhase: .idle,
                            phaseProgress: 0
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pattern name")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))

                            TextField("e.g. Morning calm", text: $name)
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "e8d5c4"))
                                .padding(14)
                                .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
                                )
                        }
                        .padding(.horizontal, 24)

                        // Phase duration sliders
                        VStack(spacing: 20) {
                            phaseSlider(
                                title: "Inhale",
                                subtitle: "Breathe in",
                                value: $inhaleSeconds,
                                range: 1...12,
                                color: Color(hex: "e8d5c4")
                            )

                            phaseSlider(
                                title: "Hold (in)",
                                subtitle: "Retain breath",
                                value: $holdInSeconds,
                                range: 0...12,
                                color: Color(hex: "c4b5a0")
                            )

                            phaseSlider(
                                title: "Exhale",
                                subtitle: "Breathe out",
                                value: $exhaleSeconds,
                                range: 1...12,
                                color: Color(hex: "a09890")
                            )

                            phaseSlider(
                                title: "Hold (out)",
                                subtitle: "Pause before next breath",
                                value: $holdOutSeconds,
                                range: 0...12,
                                color: Color(hex: "7a7068")
                            )
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit pattern" : "New pattern")
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
                    Button("Save") {
                        savePattern()
                    }
                    .foregroundStyle(Color(hex: "e8d5c4"))
                    .font(.system(size: 15, weight: .medium))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Cannot save", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let pattern = pattern {
                    name = pattern.name
                    inhaleSeconds = pattern.inhaleSeconds
                    holdInSeconds = pattern.holdInSeconds
                    exhaleSeconds = pattern.exhaleSeconds
                    holdOutSeconds = pattern.holdOutSeconds
                }
            }
        }
        .tint(Color(hex: "e8d5c4"))
    }

    @ViewBuilder
    private func phaseSlider(
        title: String,
        subtitle: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "e8d5c4"))

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "6b6560"))
                }

                Spacer()

                Text(value.wrappedValue == 0 ? "skip" : "\(Int(value.wrappedValue))s")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(color)
                    .frame(width: 44)
            }

            Slider(value: value, in: range, step: 1)
                .tint(color)
        }
        .padding(14)
        .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "2a2a30"), lineWidth: 0.5)
        )
    }

    private func savePattern() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a name for your pattern."
            showError = true
            return
        }

        guard inhaleSeconds > 0 else {
            errorMessage = "Inhale duration must be at least 1 second."
            showError = true
            return
        }

        guard exhaleSeconds > 0 else {
            errorMessage = "Exhale duration must be at least 1 second."
            showError = true
            return
        }

        let newPattern = BreathingPattern(
            id: pattern?.id ?? UUID(),
            name: trimmedName,
            inhaleSeconds: inhaleSeconds,
            holdInSeconds: holdInSeconds,
            exhaleSeconds: exhaleSeconds,
            holdOutSeconds: holdOutSeconds,
            isBuiltIn: false
        )

        onSave(newPattern)
        dismiss()
    }
}

#Preview("Pattern Selection") {
    PatternSelectionView()
}
