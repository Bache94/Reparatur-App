import SwiftUI

struct ResultCard: View {
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
                    .background(confidenceColor)
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
    
    var confidenceColor: Color {
        switch result.confidence.lowercased() {
        case "hoch", "high": return .green
        case "mittel", "medium": return .orange
        default: return .red
        }
    }
}
