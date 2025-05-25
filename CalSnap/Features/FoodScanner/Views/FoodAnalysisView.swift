import SwiftUI

struct FoodAnalysisView: View {
    let model: FoodAnalysisViewModel
    let capturedImage: UIImage // Kept for analysis and display
    var selectedDate: Date? = nil
    var isEditMode: Bool = false
    var foodToEdit: Food? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context // Inject Core Data context (Rule: Data & State)
    
    @State private var showSaveAlert = false // For save confirmation (Rule: UI Development)
    @State private var saveError: String? = nil // For error handling
    var onSave: (() -> Void)? = nil // Callback to notify parent to refresh and dismiss (Rule: UI Development)
    @State private var showEditMacro: Bool = false
    @State private var editMacroType: MacroType? = nil
    @State private var calories: Int = 0
    @State private var protein: Int = 0
    @State private var carbs: Int = 0
    @State private var fats: Int = 0
    
    var body: some View {
        VStack(spacing: 4) {
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
            // Date and Dish Title
            VStack(alignment: .leading, spacing: 4) {
                if let date = selectedDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(model.analysisResult?.properties.title ?? "Food Dish")
                    .font(.title3)
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 4)
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
            .padding(.vertical, 4)
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
            ScrollView {
                VStack(spacing: 4) {
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
                        NutritionSummaryView(
                            result: result,
                            onEdit: { macro in
                                switch macro {
                                case .calories: calories = result.properties.totalCalories
                                case .protein: protein = result.properties.proteinGrams
                                case .carbs: carbs = result.properties.carbsGrams
                                case .fats: fats = result.properties.fatsGrams
                                }
                                editMacroType = macro
                                showEditMacro = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 0)
                .padding(.bottom, 8)
            }
            // Action Buttons at the bottom
            HStack(spacing: 16) {
                Button(action: {
                    // Save or Edit to Core Data (Rule: Core Data, DebugLogs)
                    guard let result = model.analysisResult else {
                        print("[FoodAnalysisView] No analysis result to save/edit")
                        saveError = "No analysis result to save/edit."
                        showSaveAlert = true
                        return
                    }
                    let imageData = capturedImage.jpegData(compressionQuality: 0.8)
                    if isEditMode {
                        if let food = foodToEdit {
                            CoreDataManager.shared.updateFood(food, with: result.properties, imageData: imageData, date: selectedDate)
                            do {
                                try context.save()
                                print("[FoodAnalysisView] Food entry updated in Core Data: \(food.title ?? "(no title)")")
                                saveError = nil
                            } catch {
                                print("[FoodAnalysisView] Error saving context after update: \(error)")
                                saveError = error.localizedDescription
                            }
                        } else {
                            print("[FoodAnalysisView] No foodToEdit provided for update.")
                            saveError = "No food entry provided for update."
                        }
                        showSaveAlert = true
                    } else {
                        let food = CoreDataManager.shared.createFood(from: result.properties, imageData: imageData, date: selectedDate)
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
                    }
                }) {
                    Text(isEditMode ? "Edit Result" : "Save Result")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
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
        .sheet(isPresented: $showEditMacro) {
            if let macro = editMacroType {
                MacroEditorView(
                    macroType: macro,
                    value: binding(for: macro),
                    maxValue: nil,
                    onRevert: { showEditMacro = false },
                    onDone: {
                        updateMacroValue(macro, value: binding(for: macro).wrappedValue)
                        showEditMacro = false
                    }
                )
                .id(UUID().uuidString + macro.title)// Force new instance for each macro edit (Rule: UI Development, RuleEcho)
                .ignoresSafeArea()
                .presentationDetents([.large])
            }
        }
    }
    // Helper to get binding for macro
    private func binding(for macro: MacroType) -> Binding<Int> {
        switch macro {
        case .calories: return $calories
        case .protein: return $protein
        case .carbs: return $carbs
        case .fats: return $fats
        }
    }
    private func updateMacroValue(_ macro: MacroType, value: Int) {
        guard let result = model.analysisResult else { return }
        // FoodProperties is immutable, so create a new one with updated value
        let oldProps = result.properties
        let newProps: FoodProperties
        switch macro {
        case .calories:
            newProps = FoodProperties(title: oldProps.title, proteinGrams: oldProps.proteinGrams, carbsGrams: oldProps.carbsGrams, fatsGrams: oldProps.fatsGrams, healthScore: oldProps.healthScore, ingredients: oldProps.ingredients, dishCount: oldProps.dishCount, totalCalories: value)
        case .protein:
            newProps = FoodProperties(title: oldProps.title, proteinGrams: value, carbsGrams: oldProps.carbsGrams, fatsGrams: oldProps.fatsGrams, healthScore: oldProps.healthScore, ingredients: oldProps.ingredients, dishCount: oldProps.dishCount, totalCalories: oldProps.totalCalories)
        case .carbs:
            newProps = FoodProperties(title: oldProps.title, proteinGrams: oldProps.proteinGrams, carbsGrams: value, fatsGrams: oldProps.fatsGrams, healthScore: oldProps.healthScore, ingredients: oldProps.ingredients, dishCount: oldProps.dishCount, totalCalories: oldProps.totalCalories)
        case .fats:
            newProps = FoodProperties(title: oldProps.title, proteinGrams: oldProps.proteinGrams, carbsGrams: oldProps.carbsGrams, fatsGrams: value, healthScore: oldProps.healthScore, ingredients: oldProps.ingredients, dishCount: oldProps.dishCount, totalCalories: oldProps.totalCalories)
        }
        model.analysisResult = FoodAnalysisResponse(description: result.description, type: result.type, properties: newProps)
        print("[FoodAnalysisView] Updated \(macro.title) to \(value)") // DebugLogs
    }
}

private struct NutritionSummaryView: View {
    let result: FoodAnalysisResponse
    var onEdit: ((MacroType) -> Void)? = nil
    
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
                HStack(spacing: 12) {
                    NutritionMacroCard(title: "Calories", value: "\(result.properties.totalCalories)", unit: "", icon: "flame.fill", onEdit: { onEdit?(.calories) }, color: .accentColor)
                    NutritionMacroCard(title: "Protein", value: "\(result.properties.proteinGrams)", unit: "g", icon: "bolt.fill", onEdit: { onEdit?(.protein) }, color: .red)
                    NutritionMacroCard(title: "Carbs", value: "\(result.properties.carbsGrams)", unit: "g", icon: "leaf.fill", onEdit: { onEdit?(.carbs) }, color: .orange)
                    NutritionMacroCard(title: "Fats", value: "\(result.properties.fatsGrams)", unit: "g", icon: "drop.fill", onEdit: { onEdit?(.fats) }, color: .blue)
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
    var onEdit: (() -> Void)? = nil
    var color: Color = .accentColor
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Text(value)
                    .font(.body)
                    .bold()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 1)
                }
                Button(action: { onEdit?() }) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(color)
                }
                .buttonStyle(.plain)
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
    // Removed X (close) icon as per user request (Rule: UI Development, RuleEcho)
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
            // Removed Button with X icon
        }
        .frame(width: 150, height: fixedHeight, alignment: .center)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
