import SwiftUI

struct ContentView: View {
    @State private var showCamera = false
    @State private var inputImage: UIImage?
    @State private var identificationResult: AnalysisResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    @State private var analysisMode: AnalysisMode = .part
    
    // Disclaimer State
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    
    @State private var pulseStart = false
    
    @StateObject private var languageService = LanguageService.shared
    @StateObject private var audioRecorder = AudioRecorder.shared
    
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
                                .font(.system(size: 24)) // Small Flag
                                .shadow(radius: 1)
                        }
                        .padding(.top, 50) // Adjust for status bar
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                .zIndex(100) // Ensure it's on top
                
                VStack(spacing: 30) {
                    
                    // Mode Switcher
                    if !isAnalyzing && identificationResult == nil {
                        Picker("Mode", selection: $analysisMode) {
                            Text(languageService.currentLanguage == .german ? "Ersatzteil" : "Spare Part").tag(AnalysisMode.part)
                            Text(languageService.currentLanguage == .german ? "Fehlercode" : "Error Code").tag(AnalysisMode.error)
                            Text("Audio").tag(AnalysisMode.audio)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
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
                            Text(analysisMode == .part ? languageService.localizedString(.analyzePart) : (languageService.currentLanguage == .german ? "Analysiere Fehler..." : "Analyzing Error..."))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let result = identificationResult {
                        ScrollView {
                            ResultCard(result: result)
                        }
                        
                        // Styled Back Button
                        // Styled Back Button
                        Button(action: {
                            withAnimation {
                                inputImage = nil
                                identificationResult = nil
                                errorMessage = nil
                                audioRecorder.deleteRecording()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text(languageService.localizedString(.backToMenu))
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
                        // Main State (Waiting for Photo or Audio)
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text(instructionText)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                if analysisMode == .audio {
                                    toggleRecording()
                                } else {
                                    showCamera = true
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(gradient: Gradient(colors: actionButtonColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .frame(width: 160, height: 160)
                                        .shadow(color: actionButtonShadowColor, radius: 20, x: 0, y: 10)
                                    
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                        .frame(width: 150, height: 150)
                                    
                                    VStack {
                                        Image(systemName: actionButtonIcon)
                                            .font(.system(size: 44))
                                        Text(actionButtonLabel)
                                            .fontWeight(.bold)
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                            .scaleEffect(isAnalyzing || audioRecorder.isRecording ? 0.9 : 1.0)
                            .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnalyzing || audioRecorder.isRecording) // Subtle pulse hint
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
            .sheet(isPresented: $showCamera, onDismiss: analyzeMedia) {
                CameraManager(selectedImage: $inputImage)
            }
            .overlay(
                Group {
                    if showDisclaimer {
                        DisclaimerView(showDisclaimer: $showDisclaimer)
                    }
                }
            )
            .onAppear {
                if !hasAcceptedDisclaimer {
                    showDisclaimer = true
                }
            }
        }
    }
    
    var instructionText: String {
        switch analysisMode {
        case .part: return languageService.localizedString(.takePhotoInstruction)
        case .error: return languageService.currentLanguage == .german ? "Fotografiere den Fehlercode" : "Photograph the error code"
        case .audio: return audioRecorder.isRecording ? (languageService.currentLanguage == .german ? "Aufnahme läuft..." : "Recording...") : (languageService.currentLanguage == .german ? "Nimm das Geräusch auf" : "Record the sound")
        }
    }
    
    var actionButtonColors: [Color] {
        if analysisMode == .audio && audioRecorder.isRecording {
            return [.red, .orange]
        }
        return [.blue, .purple]
    }
    
    var actionButtonShadowColor: Color {
        if analysisMode == .audio && audioRecorder.isRecording {
            return .red.opacity(0.4)
        }
        return .blue.opacity(0.4)
    }
    
    var actionButtonIcon: String {
        switch analysisMode {
        case .audio: return audioRecorder.isRecording ? "stop.fill" : "mic.fill"
        default: return "camera.fill"
        }
    }
    
    var actionButtonLabel: String {
        switch analysisMode {
        case .audio: return audioRecorder.isRecording ? (languageService.currentLanguage == .german ? "Stopp" : "Stop") : (languageService.currentLanguage == .german ? "Aufnahme" : "Record")
        case .part, .error: return languageService.localizedString(.takePhotoButton)
        }
    }
    
    func toggleRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            // Wait a bit for file to save then analyze
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                analyzeMedia()
            }
        } else {
            audioRecorder.startRecording()
        }
    }
    
    func analyzeMedia() {
        if analysisMode == .audio {
            guard let url = audioRecorder.recordingURL else { return }
             withAnimation {
                isAnalyzing = true
                errorMessage = nil
                identificationResult = nil
            }
             Task {
                do {
                    let result = try await AIService.shared.analyzeAudio(audioURL: url, language: languageService.currentLanguage)
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
                        }
                    }
                }
            }
            return
        }
        
        guard let image = inputImage else { return }
        
        withAnimation {
            isAnalyzing = true
            errorMessage = nil
            identificationResult = nil
        }
        
        Task {
            do {
                let result = try await AIService.shared.analyzeImage(image: image, mode: analysisMode, language: languageService.currentLanguage)
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
