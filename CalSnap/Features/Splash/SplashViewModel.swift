import SwiftUI

@Observable final class SplashViewModel {
    // MARK: - Properties
    var isLoading = true
    var healthQuote: String?
    
    // MARK: - Constants
    private let quotes = [
        "Let food be thy medicine, and medicine be thy food.",
        "You are what you eat, so don't be fast, cheap, easy, or fake.",
        "A healthy outside starts from the inside.",
        "Your diet is a bank account. Good food choices are good investments."
    ]
    
    // MARK: - Initialization
    init() {
        // Select a random health quote
        healthQuote = quotes.randomElement()
        
        // Simulate minimum splash duration
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000) // 1.5 seconds
            await MainActor.run {
                isLoading = false
            }
        }
    }
} 
