import SwiftUI

struct DisclaimerView: View {
    @Binding var showDisclaimer: Bool
    @StateObject private var languageService = LanguageService.shared
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .padding(.top, 10)
                
                Text(languageService.localizedString(.disclaimerTitle))
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(languageService.localizedString(.disclaimerText))
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                
                Button(action: {
                    withAnimation {
                        hasAcceptedDisclaimer = true
                        showDisclaimer = false
                    }
                }) {
                    Text(languageService.localizedString(.acceptDisclaimer))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(20)
        }
    }
}
