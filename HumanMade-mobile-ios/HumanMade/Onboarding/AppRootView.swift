import SwiftUI

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false

    var body: some View {
        Group {
            if hasCompletedOnboarding && isAuthenticated {
                ContentView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                    isAuthenticated = true
                }
            }
        }
    }
}
