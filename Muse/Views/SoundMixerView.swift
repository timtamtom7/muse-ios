import SwiftUI

struct SoundMixerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var soundscapeManager = SoundscapeManager.shared
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showUpgradeAlert = false
    @State private var upgradeTier: SubscriptionTier = .master

    private var availableSounds: [SoundscapeType] {
        soundscapeManager.availableSoundscapes(for: subscriptionManager.currentTier)
    }

    private var lockedSounds: [SoundscapeType] {
        SoundscapeType.allCases.filter { availableSounds.contains($0) == false }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "050508")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Current soundscape
                        if let active = soundscapeManager.activeSoundscape {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: active.icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color(hex: "e8d5c4"))
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(active.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color(hex: "e8d5c4"))

                                        Text(active.description)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color(hex: "6b6560"))
                                    }

                                    Spacer()

                                    Button {
                                        soundscapeManager.stop()
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(Color(hex: "6b6560"))
                                            .padding(8)
                                            .background(Color(hex: "1e1e24"), in: Circle())
                                    }
                                }

                                // Volume slider
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "speaker.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color(hex: "6b6560"))
                                        Slider(
                                            value: Binding(
                                                get: { soundscapeManager.activePreset?.volume ?? 0.5 },
                                                set: { soundscapeManager.updateVolume($0) }
                                            ),
                                            in: 0...1
                                        )
                                        .tint(Color(hex: "e8d5c4"))
                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color(hex: "6b6560"))
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: 16))
                        }

                        // Soundscape grid
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Soundscapes")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(hex: "6b6560"))

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(availableSounds) { sound in
                                    SoundscapeCard(
                                        soundscape: sound,
                                        isSelected: soundscapeManager.activeSoundscape == sound,
                                        isLocked: false,
                                        onTap: {
                                            soundscapeManager.selectSoundscape(sound)
                                        }
                                    )
                                }

                                ForEach(lockedSounds) { sound in
                                    SoundscapeCard(
                                        soundscape: sound,
                                        isSelected: false,
                                        isLocked: true,
                                        onTap: {
                                            upgradeTier = sound.tier
                                            showUpgradeAlert = true
                                        }
                                    )
                                }
                            }
                        }

                        // Master volume
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Master Volume")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color(hex: "6b6560"))
                                Spacer()
                                Text("\(Int(soundscapeManager.masterVolume * 100))%")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: "6b6560"))
                            }

                            Slider(
                                value: Binding(
                                    get: { soundscapeManager.masterVolume },
                                    set: { soundscapeManager.masterVolume = $0 }
                                ),
                                in: 0...1
                            )
                            .tint(Color(hex: "e8d5c4"))
                        }
                        .padding(16)
                        .background(Color(hex: "141418"), in: RoundedRectangle(cornerRadius: 12))

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Soundscapes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color(hex: "6b6560"))
                    .font(.system(size: 15, weight: .medium))
                }
            }
            .alert("Unlock \(upgradeTier.displayName) tier", isPresented: $showUpgradeAlert) {
                Button("Upgrade") {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Soundscapes like \(upgradeTier.displayName.lowercased()) ones are available with the \(upgradeTier.displayName) subscription.")
            }
        }
        .tint(Color(hex: "e8d5c4"))
    }
}

struct SoundscapeCard: View {
    let soundscape: SoundscapeType
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected
                            ? Color(hex: "e8d5c4").opacity(0.12)
                            : Color(hex: "141418"))
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isSelected
                                        ? Color(hex: "e8d5c4").opacity(0.3)
                                        : Color(hex: "2a2a30").opacity(0.5),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        )

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "6b6560").opacity(0.5))
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: soundscape.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(isSelected
                                    ? Color(hex: "e8d5c4")
                                    : Color(hex: "6b6560"))

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "e8d5c4"))
                            }
                        }
                    }
                }

                Text(soundscape.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isLocked
                        ? Color(hex: "6b6560").opacity(0.5)
                        : isSelected
                            ? Color(hex: "e8d5c4")
                            : Color(hex: "6b6560"))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLocked)
    }
}

#Preview {
    SoundMixerView()
}
