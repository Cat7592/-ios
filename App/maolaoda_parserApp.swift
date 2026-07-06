import SwiftUI

@main
struct maolaoda_parserApp: App {
    @StateObject private var parserVM = ParserViewModel()
    @StateObject private var downloadVM = DownloadViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(parserVM)
                .environmentObject(downloadVM)
        }
    }
}
