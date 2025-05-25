import SwiftUI

struct ContentView: View {
    @State var foodScannerModel = FoodScannerViewModel()
    
    var body: some View {
        NavigationStack {
            FoodScannerView(model: foodScannerModel)
        }
    }
}

#Preview {
    ContentView()
} 