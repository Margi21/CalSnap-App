import SwiftUI
import CoreData

@main
struct CalSnapApp: App {
    @State private var showingSplash = true
    @State private var splashViewModel = SplashViewModel()
    
    // Initialize Core Data
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            if showingSplash {
                SplashView(model: splashViewModel)
                    .onChange(of: splashViewModel.isLoading) { _, isLoading in
                        if !isLoading {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showingSplash = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .transition(.opacity)
                    .environment(\.managedObjectContext, coreDataManager.viewContext)
            }
        }
    }
} 