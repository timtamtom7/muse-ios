import SwiftUI

struct PricingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedTier: SubscriptionTier? = nil
    @State private var showPurchaseConfirmation = false

    var body: some View {
        ZStack {
            Color(hex: "050508")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose your practice")
                        .font(.system(size: 22, weight: .light, design: .rounded))
                        .foregroundStyle(Color(hex: "e8d5c4"))

                    Text("Start free. Grow when you're ready.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "6b6560"))
                }
                .padding(.top, 32)
                .padding(.bottom, 28)

                // Tier cards
                VStack(spacing: 12) {
                    ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                        TierCard(
                            tier: tier,
                            isSelected: subscriptionManager.currentTier == tier,
                            onSelect: { selectTier(tier) }
                        )
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Footer
                VStack(spacing: 8) {
                    Text("Cancel anytime. No refunds required.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6b6560").opacity(0.6))

                    Button {
                        dismiss()
                    } label: {
                        Text("Maybe later")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "6b6560"))
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func selectTier(_ tier: SubscriptionTier) {
        if tier == .free {
            subscriptionManager.currentTier = .free
            dismiss()
        } else {
            // Simulate purchase flow — in a real app this would use StoreKit
            selectedTier = tier
            showPurchaseConfirmation = true
        }
    }
}

struct TierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 0) {
                // Left: name + price
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tier.displayName)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(tierColor)

                        if tier == .master {
                            Text("Best")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: "050508"))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tierColor, in: Capsule())
                        }
                    }

                    Text(tier.price)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "6b6560"))

                    Text(tier.tagline)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "6b6560").opacity(0.7))
                        .padding(.top, 2)
                }

                Spacer()

                // Right: features
                VStack(alignment: .trailing, spacing: 5) {
                    ForEach(tier.features.prefix(4), id: \.self) { feature in
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(tierColor.opacity(0.8))

                            Text(feature)
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "6b6560"))
                        }
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .fill(Color(hex: "0f0f14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                            .stroke(
                                isSelected ? tierColor.opacity(0.4) : Color(hex: "2a2a30").opacity(0.5),
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var tierColor: Color {
        switch tier {
        case .free: return Color(hex: "8a8580")
        case .practice: return Color(hex: "c4b5a0")
        case .master: return Color(hex: "e8d5c4")
        }
    }
}

#Preview {
    PricingView()
}
