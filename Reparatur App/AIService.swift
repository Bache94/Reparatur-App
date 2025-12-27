import Foundation
import UIKit

class AIService {
    static let shared = AIService()
    private init() {}
    
    private let apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func identifyPart(image: UIImage) async throws -> PartIdentificationResult {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not process image"])
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        Du bist en Experten-KI für Kaffeemaschinen-Ersatzteile. Analysiere das Bild und identifiziere das Ersatzteil.
        Gib NUR valides JSON zurück, ohne Markdown-Formatierung, in exakt diesem Format:
        {
            "partName": "Präziser deutscher Name des Teils",
            "likelyModels": ["Modell A", "Modell B"],
            "searchQuery": "Optimierter Suchstring für Google Shopping",
            "estimatedPriceRange": "XX€ - YY€",
            "confidence": "Hoch/Mittel/Niedrig"
        }
        Wenn es kein Ersatzteil ist, setze partName auf "Unbekannt".
        """
        
        let filePart = [
            "inline_data": [
                "mime_type": "image/jpeg",
                "data": base64Image
            ]
        ]
        
        let textPart = [
            "text": prompt
        ]
        
        let contents = [
            "parts": [textPart, filePart]
        ]
        
        let requestBody: [String: Any] = [
            "contents": [contents],
            "generationConfig": [
                "response_mime_type": "application/json"
            ]
        ]
        
        guard let url = URL(string: "\(apiUrl)?key=\(Secrets.geminiApiKey)") else {
            throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
        }
        
        // Gemini might return the JSON inside a "candidates" -> "content" -> "parts" -> "text" structure
        // We need to decode that wrapper first, or handle the raw JSON if we used generationConfig correctly to force generic JSON?
        // Actually, gemini-1.5-flash with generationConfig response_mime_type "application/json" returns the JSON string inside the text field.
        
        struct GeminiResponse: Decodable {
            struct Candidate: Decodable {
                struct Content: Decodable {
                    struct Part: Decodable {
                        let text: String
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let jsonString = geminiResponse.candidates.first?.content.parts.first?.text else {
             throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        // Clean up markdown if present (e.g. ```json ... ```)
        let cleanJson = jsonString.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanJson.data(using: .utf8) else {
             throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create data from JSON string"])
        }
        
        return try JSONDecoder().decode(PartIdentificationResult.self, from: jsonData)
    }
}
