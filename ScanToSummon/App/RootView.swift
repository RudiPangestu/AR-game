import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selection: Tab = .scan

    enum Tab: Hashable {
        case scan
        case codex
        case battle
    }

    var body: some View {
        TabView(selection: $selection) {
            ScanScreen()
                .tabItem { Label("tab.scan", systemImage: "camera.viewfinder") }
                .tag(Tab.scan)

            CodexScreen()
                .tabItem { Label("tab.codex", systemImage: "square.grid.2x2") }
                .tag(Tab.codex)
                .badge(appModel.codex.count)

            BattleHomeScreen()
                .tabItem { Label("tab.battle", systemImage: "bolt.fill") }
                .tag(Tab.battle)
        }
        .tint(Theme.accent)
    }
}

enum Theme {
    static let accent = Color(red: 0.42, green: 0.85, blue: 0.78)
    static let background = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let panel = Color(red: 0.12, green: 0.13, blue: 0.17)

    static func color(_ rgb: ColorRGB) -> Color {
        Color(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}
