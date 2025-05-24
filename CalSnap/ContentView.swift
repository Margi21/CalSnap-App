import SwiftUI

struct ContentView: View {
    @StateObject private var foodScannerModel = FoodScannerViewModel()
    
    var body: some View {
        NavigationStack {
            FoodScannerView(model: foodScannerModel)
                .navigationTitle("CalSnap")
        }
    }
}

#Preview {
    ContentView()
} 