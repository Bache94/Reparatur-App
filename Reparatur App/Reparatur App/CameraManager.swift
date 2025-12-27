import SwiftUI
import AVFoundation
import Combine

struct CameraManager: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var languageService = LanguageService.shared
    @StateObject private var model = CameraModel()
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: model.session)
                .ignoresSafeArea()
            
            VStack {
                // Top Bar with Cancel
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(languageService.localizedString(.cancel))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Bottom Bar with Shutter
                HStack {
                    Button(action: {
                        model.capturePhoto()
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 5)
                            .frame(width: 75, height: 75)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                            )
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            model.checkPermissions()
        }
        .onChange(of: model.capturedImage) { image in
            if let image = image {
                self.selectedImage = image
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var capturedImage: UIImage?
    
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "camera_queue")
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setup()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status { self.setup() }
            }
        case .denied:
            self.alert = true
            return
        default:
            return
        }
    }
    
    func setup() {
        do {
            self.session.beginConfiguration()
            
            // Default to back camera
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            let input = try AVCaptureDeviceInput(device: device)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
            
            queue.async {
                self.session.startRunning()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func capturePhoto() {
        DispatchQueue.global(qos: .background).async {
             self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil { return }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let image = UIImage(data: imageData) else { return }
        
        DispatchQueue.main.async {
            // Fix orientation
            self.capturedImage = self.fixOrientation(img: image)
        }
    }
    
    // Simple orientation fix
    func fixOrientation(img: UIImage) -> UIImage {
        if img.imageOrientation == .up { return img }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? img
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
