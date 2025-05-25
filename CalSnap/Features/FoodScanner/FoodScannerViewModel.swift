import SwiftUI
import AVFoundation
import Observation

@Observable
final class FoodScannerViewModel {
    // MARK: - Properties
    var showCamera = false
    var capturedImage: UIImage?
    var isCameraAuthorized = false
    var showPermissionAlert = false
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    private(set) var allFoods: [Food] = []
    
    // Computed property: foods for selected date
    private(set) var foodsForSelectedDate: [Food] = []
    
    // Computed properties for macros and calories
    var totalCalories: Int {
        foodsForSelectedDate.reduce(0) { $0 + Int($1.totalCalories) }
    }
    var totalProtein: Int {
        foodsForSelectedDate.reduce(0) { $0 + Int($1.proteinGrams) }
    }
    var totalCarbs: Int {
        foodsForSelectedDate.reduce(0) { $0 + Int($1.carbsGrams) }
    }
    var totalFats: Int {
        foodsForSelectedDate.reduce(0) { $0 + Int($1.fatsGrams) }
    }
    
    // MARK: - Initialization
    init() {
        checkCameraPermission()
        updateFoodsForSelectedDate() // Initial update
    }
    
    // MARK: - Camera Permission
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.isCameraAuthorized = granted
                    self?.showPermissionAlert = !granted
                }
            }
        default:
            isCameraAuthorized = false
            showPermissionAlert = true
        }
    }
    
    // MARK: - Actions
    func startScanning() {
        if isCameraAuthorized {
            showCamera = true
        } else {
            showPermissionAlert = true
        }
    }
    
    func handleCapturedImage(_ image: UIImage?) {
        capturedImage = image
        showCamera = false
    }
    
    func retakePhoto() {
        capturedImage = nil
        showCamera = true
    }
    
    // MARK: - Debug
    func logCameraState() {
        print("📸 Camera State - Authorized: \(isCameraAuthorized), Showing: \(showCamera), Has Image: \(capturedImage != nil)")
    }
    
    // Fetch all foods from Core Data and update selected date foods
    func loadAllFoods() {
        print("[FoodScannerViewModel] Loading all foods from Core Data")
        allFoods = CoreDataManager.shared.fetchFoods()
        updateFoodsForSelectedDate()
    }
    
    // Update foods for selected date
    private func updateFoodsForSelectedDate() {
        let calendar = Calendar.current
        foodsForSelectedDate = allFoods.filter { food in
            guard let date = food.dateAdded else { return false }
            return calendar.isDate(date, inSameDayAs: selectedDate)
        }
        print("[FoodScannerViewModel] Updated foods for date: \(selectedDate), count: \(foodsForSelectedDate.count)")
    }
    
    // Called when selected date changes
    func dateSelected(_ date: Date) {
        selectedDate = date
        updateFoodsForSelectedDate()
    }
} 