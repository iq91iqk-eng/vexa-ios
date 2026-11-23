import SwiftUI

@main
struct VexaApp: App {
    var body: some Scene {
        WindowGroup {
            WebHost()
                .ignoresSafeArea()
                .preferredColorScheme(.dark)
        }
    }
}
