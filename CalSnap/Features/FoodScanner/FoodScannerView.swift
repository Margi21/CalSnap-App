import SwiftUI

struct FoodScannerView: View {
    @ObservedObject var model: FoodScannerViewModel
    @State private var showAnalysis = false
    @State private var selectedFoodForAnalysis: Food? = nil
    
    private let calendar = Calendar.current
    private let daysRange: [Date] = {
        let today = Calendar.current.startOfDay(for: Date())
        return (-3...3).map { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: today)!
        }
    }()
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Horizontal Date Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(daysRange, id: \.self) { date in
                                let isSelected = calendar.isDate(date, inSameDayAs: model.selectedDate)
                                VStack(spacing: 4) {
                                    Text(date, format: .dateTime.weekday(.narrow))
                                        .font(.caption)
                                        .foregroundColor(isSelected ? .accentColor : .secondary)
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.headline)
                                        .foregroundColor(isSelected ? .accentColor : .primary)
                                        .padding(8)
                                        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                                        .clipShape(Circle())
                                }
                                .onTapGesture {
                                    print("[FoodScannerView] Selected date: \(date)")
                                    model.selectedDate = date
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    // Calories Card
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(model.totalCalories)")
                                .font(.system(size: 40, weight: .bold))
                            Text("Calories consumed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    // Add vertical padding between calories and macros
                    Spacer().frame(height: 12)
                    // Macros Cards (with left/right padding to match calories card)
                    GeometryReader { geo in
                        HStack(spacing: 12) {
                            MacroCardView(title: "Protein", value: model.totalProtein, unit: "g", color: .red, icon: "bolt.fill", width: (geo.size.width - 32 - 24)/3)
                            MacroCardView(title: "Carbs", value: model.totalCarbs, unit: "g", color: .orange, icon: "leaf.fill", width: (geo.size.width - 32 - 24)/3)
                            MacroCardView(title: "Fats", value: model.totalFats, unit: "g", color: .blue, icon: "drop.fill", width: (geo.size.width - 32 - 24)/3)
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 90)
                    // Recently Eaten List
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recently eaten")
                            .font(.headline)
                            .padding(.horizontal)
                        if model.foodsForSelectedDate.isEmpty {
                            Text("No foods for this date.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(model.foodsForSelectedDate.compactMap { $0.id }, id: \.self) { foodId in
                                        if let food = model.foodsForSelectedDate.first(where: { $0.id == foodId }) {
                                            FoodListCardView(food: food)
                                                .onTapGesture {
                                                    print("[FoodScannerView] Tapped food card for analysis sheet.")
                                                    selectedFoodForAnalysis = food
                                                }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 16)
                        }
                    }
                    .padding(.top, 8)
                    Spacer()
                }
                // Floating + button at bottom right
                Button(action: {
                    print("[FoodScannerView] Floating + button tapped, starting scan.")
                    model.startScanning()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("CalSnap")
                            .font(.title2).bold()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $model.showCamera) {
                CameraView { image in
                    model.handleCapturedImage(image)
                    if image != nil {
                        showAnalysis = true
                    }
                }
                .ignoresSafeArea()
            }
            .alert("Camera Access Required",
                   isPresented: $model.showPermissionAlert) {
                Button("Open Settings", action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                })
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please allow camera access in Settings to scan food items.")
            }
            // Present FoodAnalysisView as a bottom sheet
            .sheet(isPresented: Binding<Bool>(
                get: { showAnalysis || selectedFoodForAnalysis != nil },
                set: { newValue in
                    if !newValue {
                        showAnalysis = false
                        selectedFoodForAnalysis = nil
                    }
                })
            ) {
                if let image = model.capturedImage, showAnalysis {
                    FoodAnalysisView(
                        model: FoodAnalysisViewModel(),
                        capturedImage: image,
                        onSave: {
                            print("[FoodScannerView] onSave callback received, dismissing analysis sheet and refreshing home screen.")
                            showAnalysis = false
                            model.loadAllFoods()
                        }
                    )
                } else if let food = selectedFoodForAnalysis, let imageData = food.imageData, let uiImage = UIImage(data: imageData) {
                    FoodAnalysisView(
                        model: FoodAnalysisViewModel(),
                        capturedImage: uiImage,
                        onSave: {
                            print("[FoodScannerView] onSave callback received from food card, dismissing analysis sheet.")
                            selectedFoodForAnalysis = nil
                        }
                    )
                }
            }
            .onAppear {
                model.logCameraState()
                model.loadAllFoods()
            }
        }
    }
}

// MacroCardView for displaying macros
private struct MacroCardView: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    let icon: String
    var width: CGFloat? = nil
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(.title3)
                    .bold()
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: width ?? 90, height: 90)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// FoodListCardView for improved food list card
private struct FoodListCardView: View {
    let food: Food
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let imageData = food.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(food.title ?? "Untitled")
                        .font(.headline)
                    Spacer()
                    if let date = food.dateAdded {
                        Text(date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Text("\(food.totalCalories) calories")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                HStack(spacing: 12) {
                    Label("\(food.proteinGrams)g", systemImage: "bolt.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Label("\(food.carbsGrams)g", systemImage: "leaf.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Label("\(food.fatsGrams)g", systemImage: "drop.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    FoodScannerView(model: FoodScannerViewModel())
} 