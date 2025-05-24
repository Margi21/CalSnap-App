import SwiftUI

struct FoodAnalysisView: View {
    let model: FoodAnalysisViewModel
    let capturedImage: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if model.isAnalyzing {
                    ProgressView("Analyzing your food...")
                        .progressViewStyle(.circular)
                } else if let error = model.error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Analysis Failed")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            model.analyzeImage(capturedImage.jpegData(compressionQuality: 0.8) ?? Data())
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if let result = model.analysisResult {
                    ResultView(result: result)
                }
            }
            .padding()
        }
        .navigationTitle("Food Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !model.isAnalyzing {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let imageData = capturedImage.jpegData(compressionQuality: 0.8) {
                model.analyzeImage(imageData)
            }
        }
    }
}

private struct ResultView: View {
    let result: FoodAnalysisResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Food Analysis Results")
                .font(.title2)
                .bold()
            
            if result.properties.ingredients.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    Text("No Food Items Detected")
                        .font(.headline)
                    Text("Please make sure your image contains visible food items and try again.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Food Items")
                        .font(.headline)
                    
                    ForEach(result.properties.ingredients, id: \.name) { item in
                        FoodItemRow(item: item)
                    }
                }
                
                TotalCaloriesView(calories: Int(result.properties.proteinGrams + result.properties.carbsGrams + result.properties.fatsGrams))
            }
        }
    }
}

private struct FoodItemRow: View {
    let item: Ingredient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.headline)
            
            HStack {
                Text("\(item.calories) calories")
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Text(item.name)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct TotalCaloriesView: View {
    let calories: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Calories")
                .font(.headline)
            
            HStack {
                Text("\(calories)")
                    .font(.title)
                    .bold()
                Text("calories")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
} 