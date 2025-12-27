import Foundation

struct PartIdentificationResult: Codable {
    let partName: String
    let likelyModels: [String]
    let searchQuery: String
    let estimatedPriceRange: String
    let confidence: String
}
