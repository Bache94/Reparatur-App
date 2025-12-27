import SwiftUI

struct ContentView: View {
    @State private var showCamera = false
    @State private var inputImage: UIImage?
    @State private var identificationResult: PartIdentificationResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    @State private var pulseStart = false
    
    @StateObject private var languageService = LanguageService.shared
    
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
                
                Text(languageService.localizedString(.appName))
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
            
            
            // Dismiss Splash after 3.5 seconds (1 second longer)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
    
    var MainContent: some View {
        NavigationView {
            ZStack {
                // Professional Gradient Background
                LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemGray6)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                // Fine Pattern Overlay (optional for texture)
                Rectangle()
                    .fill(
                        LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.05), .clear]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .ignoresSafeArea()
                
                // MadeByBache Footer
                VStack {
                    Spacer()
                    Text("MadeByBache")
                        .font(.custom("Futura", size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.bottom, 5)
                }
                .ignoresSafeArea(.keyboard)
                
                // Language Toggle (Top Right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                let newLang: AppLanguage = (languageService.currentLanguage == .german) ? .english : .german
                                languageService.setLanguage(newLang)
                            }
                        }) {
                            Text(languageService.currentLanguage.flag)
                                .font(.system(size: 40)) // Big Flag
                                .shadow(radius: 2)
                        }
                        .padding(.top, 50) // Adjust for status bar
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .zIndex(100) // Ensure it's on top
                
                VStack(spacing: 30) {
                    
                    // Header
                    if !isAnalyzing && identificationResult == nil {
                        VStack(spacing: 10) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            Text(languageService.localizedString(.appName))
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
                            Text(languageService.localizedString(.analyzePart))
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
                                Text(languageService.localizedString(.newPhoto))
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
                            Text(languageService.localizedString(.takePhotoInstruction))
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showCamera = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .frame(width: 160, height: 160)
                                        .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
                                    
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                        .frame(width: 150, height: 150)
                                    
                                    VStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 44))
                                        Text(languageService.localizedString(.takePhotoButton))
                                            .fontWeight(.bold)
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .scaleEffect(isAnalyzing ? 0.9 : 1.0)
                            .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnalyzing) // Subtle pulse hint
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
                let result = try await AIService.shared.identifyPart(image: image, language: languageService.currentLanguage)
                DispatchQueue.main.async {
                    withAnimation {
                        self.identificationResult = result
                        self.isAnalyzing = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    withAnimation {
                        self.errorMessage = "\(self.languageService.localizedString(.errorPrefix))\(error.localizedDescription)"
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
