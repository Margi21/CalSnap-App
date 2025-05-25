import SwiftUI
import AVFoundation

class FoodScannerViewModel: ObservableObject {
    // MARK: - Properties
    @Published var showCamera = false
    @Published var capturedImage: UIImage?
    @Published var isCameraAuthorized = false
    @Published var showPermissionAlert = false
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @Published var allFoods: [Food] = []
    
    // Computed property: foods for selected date
    var foodsForSelectedDate: [Food] {
        let calendar = Calendar.current
        return allFoods.filter { food in
            guard let date = food.dateAdded else { return false }
            return calendar.isDate(date, inSameDayAs: selectedDate)
        }
    }
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
    
    // Fetch all foods from Core Data
    func loadAllFoods() {
        print("[FoodScannerViewModel] Loading all foods from Core Data")
        allFoods = CoreDataManager.shared.fetchFoods()
    }
} 