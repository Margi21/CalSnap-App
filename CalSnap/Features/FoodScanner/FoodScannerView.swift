import SwiftUI

struct FoodScannerView: View {
    @ObservedObject var model: FoodScannerViewModel
    
    var body: some View {
        VStack {
            if let capturedImage = model.capturedImage {
                // Image Preview
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: model.retakePhoto) {
                        Label("Retake", systemImage: "camera.rotate")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        // TODO: Proceed to analysis
                        print("Proceeding to analysis...")
                    }) {
                        Label("Analyze", systemImage: "arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                // Scan Button
                Button(action: model.startScanning) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                        Text("Scan Food")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $model.showCamera) {
            CameraView { image in
                model.handleCapturedImage(image)
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
        .onAppear {
            model.logCameraState()
        }
    }
}

#Preview {
    FoodScannerView(model: FoodScannerViewModel())
} 