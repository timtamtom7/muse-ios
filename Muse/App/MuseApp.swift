import SwiftUI

@main
struct MuseApp: App {
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingComplete {
                    BreatheView()
                } else {
                    OnboardingContainer(onComplete: {
                        withAnimation {
                            onboardingComplete = true
                        }
                    })
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct OnboardingContainer: View {
    let onComplete: () -> Void
    @State private var isComplete = true

    var body: some View {
        OnboardingView(isComplete: $isComplete)
            .onChange(of: isComplete) { _, newValue in
                if !newValue {
                    onComplete()
                }
            }
    }
}
