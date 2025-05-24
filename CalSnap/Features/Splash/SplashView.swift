import SwiftUI

struct SplashView: View {
    let model: SplashViewModel
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Logo
                Image(systemName: "apple.logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.red)
                
                Text("CalSnap")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.primary)
                
                // Health Quote
                if let quote = model.healthQuote {
                    Text(quote)
                        .font(.system(size: 16, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                }
                
                // Loading Indicator
                if model.isLoading {
                    ProgressView()
                        .controlSize(.regular)
                }
            }
        }
    }
}

#Preview {
    SplashView(model: SplashViewModel())
} 
