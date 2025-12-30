import SwiftUI

struct ResultCard: View {
    @StateObject private var languageService = LanguageService.shared
    let result: AnalysisResult
    
    var body: some View {
        switch result {
        case .part(let partResult):
            PartView(result: partResult)
        case .error(let errorResult):
            ErrorView(result: errorResult)
        }
    }
    
    struct PartView: View {
        @StateObject private var languageService = LanguageService.shared
        let result: PartIdentificationResult
        
        var body: some View {
            VStack(spacing: 20) {
                // Confidence Banner
                HStack {
                    Spacer()
                    Text(result.confidence.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(6)
                        .foregroundColor(.white)
                        .background(confidenceColor(for: result.confidence))
                        .cornerRadius(8)
                }
            
            // Part Name
            Text(result.partName)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            Divider()
            
            // Models
            if !result.likelyModels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(languageService.localizedString(.compatibleModels))
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ForEach(result.likelyModels, id: \.self) { model in
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(model)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            
            // Price
            VStack(spacing: 5) {
                Text(languageService.localizedString(.estimatedPrice))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(result.estimatedPriceRange)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
            
            // Action Button
            Button(action: {
                if let url = URL(string: "https://www.google.com/search?tbm=shop&q=\(result.searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "cart.fill")
                    Text(languageService.localizedString(.startPriceCompare))
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [.blue, .indigo]), startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(14)
                .shadow(color: .indigo.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            // Community Button
            Button(action: {
                let query = "site:reddit.com OR site:kaffee-netz.de \(result.partName) problem"
                if let url = URL(string: "https://www.google.com/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text(languageService.localizedString(.communityHelp))
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(14)
            }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding()
        }
    }
    

}

struct ErrorView: View {
    @StateObject private var languageService = LanguageService.shared
    let result: ErrorCodeResult
    
    var body: some View {
        VStack(spacing: 20) {
            // Confidence
            HStack {
                Spacer()
                Text(result.confidence.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(6)
                    .foregroundColor(.white)
                    .background(confidenceColor(for: result.confidence))
                    .cornerRadius(8)
            }
            
            // Error Code
            Text(result.errorCode)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(.red)
                .shadow(color: .red.opacity(0.3), radius: 2)
            
            // Description
            Text(result.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
            
            // Causes & Fixes
            VStack(alignment: .leading, spacing: 15) {
                if !result.possibleCauses.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Ursachen", systemImage: "exclamationmark.triangle.fill") // Todo: Localize
                            .font(.headline)
                            .foregroundColor(.orange)
                        ForEach(result.possibleCauses, id: \.self) { cause in
                            Text("• \(cause)")
                                .font(.subheadline)
                        }
                    }
                }
                
                if !result.suggestedFixes.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                         Label("Lösungen", systemImage: "wrench.fill") // Todo: Localize
                            .font(.headline)
                            .foregroundColor(.green)
                        ForEach(result.suggestedFixes, id: \.self) { fix in
                            Text("• \(fix)")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Community Button
            Button(action: {
                let query = "site:reddit.com OR site:kaffee-netz.de \(result.errorCode) \(result.description)"
                if let url = URL(string: "https://www.google.com/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text(languageService.localizedString(.communityHelp))
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(14)
            }
            
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding()
    }
    
}

private func confidenceColor(for confidence: String) -> Color {
    switch confidence.lowercased() {
    case "hoch", "high": return .green
    case "mittel", "medium": return .orange
    default: return .red
    }
}
