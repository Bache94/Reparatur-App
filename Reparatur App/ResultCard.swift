import SwiftUI

struct ResultCard: View {
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
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Divider()
            
            // Models
            if !result.likelyModels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kompatible Modelle:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ForEach(result.likelyModels, id: \.self) { model in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(model)
                                .font(.body)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Price
            VStack {
                Text("Geschätzter Preis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(result.estimatedPriceRange)
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            // Action Button
            Button(action: {
                if let url = URL(string: "https://www.google.com/search?tbm=shop&q=\(result.searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "cart.fill")
                    Text("Preisvergleich starten")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(14)
                .shadow(radius: 5)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
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
