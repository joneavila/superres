import SwiftUI

@main
struct SuperresApp: App {
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Acknowledgements") {
                    openWindow(id: "acknowledgements")
                }
            }
        }

        Window("Acknowledgements", id: "acknowledgements") {
            AcknowledgementsView()
        }
        .windowResizability(.contentSize)
    }
}
