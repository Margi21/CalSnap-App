import Foundation
import SwiftUI

@Observable
final class FoodAnalysisViewModel {
    private let analysisService: FoodAnalysisService
    
    var analysisResult: FoodAnalysisResponse?
    var isAnalyzing = false
    var error: String?
    
    init(analysisService: FoodAnalysisService = FoodAnalysisService()) {
        self.analysisService = analysisService
    }
    
    func analyzeImage(_ imageData: Data) {
        isAnalyzing = true
        error = nil
        
        print("Debug: Starting image analysis in ViewModel")
        
        Task {
            do {
                let result = try await analysisService.analyzeFood(image: imageData)
                await MainActor.run {
                    self.analysisResult = result
                    self.isAnalyzing = false
                }
                print("Debug: Analysis completed successfully")
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isAnalyzing = false
                }
                print("Debug: Analysis failed with error: \(error)")
            }
        }
    }
    
    func reset() {
        analysisResult = nil
        error = nil
        isAnalyzing = false
    }
} 