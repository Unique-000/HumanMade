import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    var body: some View {
            LoginRegisterOnboardingPage(onAuthenticated: onFinish)
    }
}


struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onFinish: {})
    }
}
