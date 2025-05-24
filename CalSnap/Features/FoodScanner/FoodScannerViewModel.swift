import SwiftUI
import AVFoundation

class FoodScannerViewModel: ObservableObject {
    // MARK: - Properties
    @Published var showCamera = false
    @Published var capturedImage: UIImage?
    @Published var isCameraAuthorized = false
    @Published var showPermissionAlert = false
    
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
} 