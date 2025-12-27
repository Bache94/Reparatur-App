import SwiftUI

struct ContentView: View {
    @State private var showCamera = false
    @State private var inputImage: UIImage?
    @State private var identificationResult: PartIdentificationResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    // Animation States
    @State private var showSplash = true
    @State private var wrenchRotation = 0.0
    @State private var opacity = 0.0
    @State private var scale = 0.5
    
    var body: some View {
        if showSplash {
            SplashScreen
        } else {
            MainContent
        }
    }
    
    var SplashScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(wrenchRotation))
                
                Text("Reparatur Helfer")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                wrenchRotation = 20
            }
            
            // Dismiss Splash after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
    
    var MainContent: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    
                    // Header
                    if !isAnalyzing && identificationResult == nil {
                        VStack(spacing: 10) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            Text("Reparatur Helfer")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if let image = inputImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .padding()
                    }
                    
                    if isAnalyzing {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Analysiere Bauteil...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let result = identificationResult {
                        ScrollView {
                            ResultCard(result: result)
                        }
                        
                        // Styled Back Button
                        Button(action: {
                            withAnimation {
                                inputImage = nil
                                identificationResult = nil
                                errorMessage = nil
                            }
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Neues Foto")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary)
                            .cornerRadius(14)
                            .shadow(radius: 3)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        
                    } else {
                        // Main State (Waiting for Photo)
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text("Fotografiere das defekte Teil")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showCamera = true
                            }) {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                    Text("Foto aufnehmen")
                                        .fontWeight(.semibold)
                                }
                                .frame(width: 150, height: 150)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 10)
                            }
                        }
                        .padding()
                        
                        // Error State
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCamera, onDismiss: analyzeImage) {
                CameraManager(selectedImage: $inputImage)
            }
        }
    }
    
    func analyzeImage() {
        guard let image = inputImage else { return }
        
        withAnimation {
            isAnalyzing = true
            errorMessage = nil
            identificationResult = nil
        }
        
        Task {
            do {
                let result = try await AIService.shared.identifyPart(image: image)
                DispatchQueue.main.async {
                    withAnimation {
                        self.identificationResult = result
                        self.isAnalyzing = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    withAnimation {
                        self.errorMessage = "Fehler bei der Analyse: \(error.localizedDescription)"
                        self.isAnalyzing = false
                        // Reset image on error so user can try again easily
                        if self.identificationResult == nil {
                            // self.inputImage = nil // Optional: Keep image or reset? Keeping it is better UX usually, or showing retry.
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
