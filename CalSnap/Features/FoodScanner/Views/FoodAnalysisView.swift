import SwiftUI

struct FoodAnalysisView: View {
    let model: FoodAnalysisViewModel
    let capturedImage: UIImage // Kept for analysis and display
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context // Inject Core Data context (Rule: Data & State)
    
    @State private var showSaveAlert = false // For save confirmation (Rule: UI Development)
    @State private var saveError: String? = nil // For error handling
    var onSave: (() -> Void)? = nil // Callback to notify parent to refresh and dismiss (Rule: UI Development)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with back button, time, and title
            HStack(alignment: .center) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                Text("Nutrition")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // Food image (fixed to 25% of full screen height)
            Image(uiImage: capturedImage)
                .resizable()
                .scaledToFill()
                .frame(height: UIScreen.main.bounds.height * 0.25)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .onAppear { print("[FoodAnalysisView] Displaying food image at 25% height") }
            
            // Time and Dish Title
            VStack(alignment: .leading, spacing: 4) {
                Text("09:28 PM") // TODO: Replace with actual time if available
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(model.analysisResult?.properties.title ?? "Food Dish")
                    .font(.title3)
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Quantity stepper (optional, as in screenshot)
            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Button(action: { /* TODO: Decrement quantity */ }) {
                        Image(systemName: "minus")
                            .font(.title3)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.bordered)
                    Text("1") // TODO: Bind to quantity
                        .font(.title3)
                        .frame(width: 32)
                    Button(action: { /* TODO: Increment quantity */ }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.bordered)
                }
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 20) {
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
                                model.analyzeImage(
                                    capturedImage.jpegData(compressionQuality: 0.8) ?? Data())
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    } else if let result = model.analysisResult {
                        NutritionSummaryView(result: result)
                    }
                }
                .padding(.horizontal, 0)
                .padding(.bottom, 16)
            }
            
            // Action Buttons at the bottom
            HStack(spacing: 16) {
                Button(action: {
                    // Save to Core Data (Rule: Core Data, DebugLogs)
                    guard let result = model.analysisResult else {
                        print("[FoodAnalysisView] No analysis result to save")
                        saveError = "No analysis result to save."
                        showSaveAlert = true
                        return
                    }
                    let imageData = capturedImage.jpegData(compressionQuality: 0.8)
                    let food = CoreDataManager.shared.createFood(from: result.properties, imageData: imageData)
                    if context.hasChanges {
                        do {
                            try context.save()
                            print("[FoodAnalysisView] Food entry saved to Core Data: \(food.title ?? "(no title)")")
                            saveError = nil
                        } catch {
                            print("[FoodAnalysisView] Error saving context: \(error)")
                            saveError = error.localizedDescription
                        }
                    } else {
                        print("[FoodAnalysisView] No changes to save in context.")
                        saveError = nil
                    }
                    showSaveAlert = true
                }) {
                    Text("Save Result")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .alert(isPresented: $showSaveAlert) {
                if let error = saveError {
                    return Alert(title: Text("Save Failed"), message: Text(error), dismissButton: .default(Text("OK")))
                } else {
                    return Alert(title: Text("Saved!"), message: Text("Food analysis result saved."), dismissButton: .default(Text("OK"), action: {
                        print("[FoodAnalysisView] Save OK tapped, navigating to home screen.")
                        onSave?() // Notify parent to refresh and dismiss
                        dismiss()
                    }))
                }
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // Debug log
            print("[FoodAnalysisView] Appeared, starting analysis if needed.")
            if let imageData = capturedImage.jpegData(compressionQuality: 0.8) {
                model.analyzeImage(imageData)
            }
        }
    }
}

private struct NutritionSummaryView: View {
    let result: FoodAnalysisResponse
    
    // Calculate the max height needed for ingredient cards
    private func maxIngredientCardHeight(proxy: GeometryProxy) -> CGFloat {
        // Estimate a reasonable max height for the cards (e.g., 60)
        // For more dynamic sizing, you could measure text, but for now, use a fixed value
        return 60
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Calories & Macros with icons, value and unit side by side, left padding, horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    NutritionMacroCard(title: "Calories", value: "\(result.properties.totalCalories)", unit: "", icon: "flame.fill")
                    NutritionMacroCard(title: "Protein", value: "\(result.properties.proteinGrams)", unit: "g", icon: "bolt.fill")
                    NutritionMacroCard(title: "Carbs", value: "\(result.properties.carbsGrams)", unit: "g", icon: "leaf.fill")
                    NutritionMacroCard(title: "Fats", value: "\(result.properties.fatsGrams)", unit: "g", icon: "drop.fill")
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 0)
            
            // Health Score (with 20pt horizontal padding on both sides)
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                        Text("Health score")
                            .font(.headline)
                        Spacer()
                        Text("\(result.properties.healthScore)/10")
                            .font(.headline)
                    }
                    ProgressView(value: Double(result.properties.healthScore), total: 10)
                        .accentColor(.green)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(minHeight: 80)
            }
            .padding(.horizontal, 20)
            
            // Ingredients horizontal scroll with X icon (with 20pt horizontal padding)
            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients")
                    .font(.headline)
                GeometryReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(result.properties.ingredients, id: \.name) { item in
                                IngredientRowWithClose(item: item, fixedHeight: maxIngredientCardHeight(proxy: proxy))
                            }
                        }
                    }
                }
                .frame(height: 60) // Match the fixed height used in maxIngredientCardHeight
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 0)
    }
}

private struct NutritionMacroCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .bold()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 1)
                }
            }
        }
        .frame(width: 80, height: 90)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.leading, 8)
    }
}

private struct IngredientRowWithClose: View {
    let item: Ingredient
    var fixedHeight: CGFloat = 60
    // TODO: Add remove action if needed
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .bold()
                Text("\(item.calories) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }.padding(.horizontal, 5)
            .frame(maxHeight: .infinity, alignment: .center)
            Spacer(minLength: 8)
            Button(action: { /* TODO: Remove ingredient action */ }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 150, height: fixedHeight, alignment: .center)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}