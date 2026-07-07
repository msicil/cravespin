import SwiftUI

struct RootView: View {
    @State private var showSplash = !WidgetSpinRequest.isPending

    var body: some View {
        ZStack {
            ContentView()

            if showSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    .zIndex(1)
            }
        }
        .onOpenURL { url in
            WidgetSpinRequest.handle(url: url)
            withAnimation(.easeInOut(duration: 0.35)) {
                showSplash = false
            }
        }
        .onAppear {
            guard showSplash else { return }
            Task {
                try? await Task.sleep(for: .seconds(2.4))
                withAnimation(.easeInOut(duration: 0.55)) {
                    showSplash = false
                }
            }
        }
    }
}
