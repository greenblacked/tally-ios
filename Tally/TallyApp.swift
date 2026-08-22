import SwiftUI

@main
struct TallyApp: App {
    @State private var store = BudgetStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
