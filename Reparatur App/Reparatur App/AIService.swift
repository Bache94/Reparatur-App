import Foundation
import UIKit

class AIService {
    static let shared = AIService()
    private init() {}
    
    private let apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    func analyzeImage(image: UIImage, mode: AnalysisMode, language: AppLanguage) async throws -> AnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not process image"])
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt: String
        
        if mode == .part {
            if language == .german {
                prompt = """
                Du bist eine Experten-KI für Kaffeemaschinen-Ersatzteile. Analysiere das Bild und identifiziere das Ersatzteil.
                Gib NUR valides JSON zurück, ohne Markdown-Formatierung, in exakt diesem Format:
                {
                    "type": "part",
                    "partName": "Präziser deutscher Name des Teils",
                    "likelyModels": ["Modell A", "Modell B"],
                    "searchQuery": "Optimierter Suchstring für Google Shopping",
                    "estimatedPriceRange": "XX€ - YY€",
                    "confidence": "Hoch/Mittel/Niedrig"
                }
                Wenn es kein Ersatzteil ist, setze partName auf "Unbekannt".
                """
            } else {
                prompt = """
                You are an expert AI for coffee machine spare parts. Analyze the image and identify the spare part.
                Return ONLY valid JSON, without markdown formatting, in exactly this format:
                {
                    "type": "part",
                    "partName": "Precise English name of the part",
                    "likelyModels": ["Model A", "Model B"],
                    "searchQuery": "Optimized search string for Google Shopping USA",
                    "estimatedPriceRange": "$XX - $YY",
                    "confidence": "High/Medium/Low"
                }
                If it is not a spare part, set partName to "Unknown".
                """
            }
        } else {
            // Error Code Mode
            if language == .german {
                prompt = """
                Du bist eine Experten-KI für Kaffeemaschinen-Fehlercodes. Analysiere das Bild vom Display oder der Fehlermeldung.
                Gib NUR valides JSON zurück, ohne Markdown-Formatierung, in exakt diesem Format:
                {
                    "type": "error",
                    "errorCode": "Der Fehlercode (z.B. Error 8)",
                    "description": "Kurze Erklärung des Fehlers",
                    "possibleCauses": ["Ursache 1", "Ursache 2"],
                    "suggestedFixes": ["Lösungsschritt 1", "Lösungsschritt 2"],
                    "confidence": "Hoch/Mittel/Niedrig"
                }
                Wenn kein Fehler erkennbar ist, setze errorCode auf "Unbekannt".
                """
            } else {
                prompt = """
                You are an expert AI for coffee machine error codes. Analyze the image of the display or error message.
                Return ONLY valid JSON, without markdown formatting, in exactly this format:
                {
                    "type": "error",
                    "errorCode": "The error code (e.g. Error 8)",
                    "description": "Brief explanation of the error",
                    "possibleCauses": ["Cause 1", "Cause 2"],
                    "suggestedFixes": ["Fix step 1", "Fix step 2"],
                    "confidence": "High/Medium/Low"
                }
                If no error is visible, set errorCode to "Unknown".
                """
            }
        }
        
        return try await sendRequest(prompt: prompt, mimeType: "image/jpeg", data: base64Image, defaultToError: mode == .error)
    }
    
    func analyzeAudio(audioURL: URL, language: AppLanguage) async throws -> AnalysisResult {
        let audioData = try Data(contentsOf: audioURL)
        let base64Audio = audioData.base64EncodedString()
        
        let prompt: String
        if language == .german {
            prompt = """
            Du bist eine Experten-KI für Kaffeemaschinen-Diagnose. Analysiere das Audio (Geräusch der Maschine) und identifiziere Probleme.
            Gib NUR valides JSON zurück, ohne Markdown-Formatierung, in exakt diesem Format:
            {
                "type": "error",
                "errorCode": "Audio Diagnose",
                "description": "Beschreibung des Geräusches und was es bedeutet (z.B. Pumpe läuft trocken, Mahlwerk blockiert)",
                "possibleCauses": ["Ursache 1", "Ursache 2"],
                "suggestedFixes": ["Lösungsschritt 1", "Lösungsschritt 2"],
                "confidence": "Hoch/Mittel/Niedrig"
            }
            """
        } else {
            prompt = """
            You are an expert AI for coffee machine diagnosis. Analyze the audio (machine sound) and identify problems.
            Return ONLY valid JSON, without markdown formatting, in exactly this format:
            {
                "type": "error",
                "errorCode": "Audio Diagnosis",
                "description": "Description of the sound and what it means (e.g. pump running dry, grinder blocked)",
                "possibleCauses": ["Cause 1", "Cause 2"],
                "suggestedFixes": ["Fix step 1", "Fix step 2"],
                "confidence": "High/Medium/Low"
            }
            """
        }
        
        return try await sendRequest(prompt: prompt, mimeType: "audio/mpeg", data: base64Audio, defaultToError: true)
    }

    private func sendRequest(prompt: String, mimeType: String, data: String, defaultToError: Bool = false) async throws -> AnalysisResult {
        let filePart = [
            "inline_data": [
                "mime_type": mimeType == "audio/mpeg" ? "audio/mp3" : (mimeType == "image/jpeg" ? "image/jpeg" : "audio/mp4"),
                "data": data
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
        
        let (dataResponse, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: dataResponse, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
        }
        
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
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: dataResponse)
        guard let jsonString = geminiResponse.candidates.first?.content.parts.first?.text else {
             throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No content in response"])
        }
        
        let cleanJson = jsonString.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        guard let jsonData = cleanJson.data(using: String.Encoding.utf8) else {
             throw NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create data from JSON string"])
        }
        
        // Decode based on type field? Or just try decoding one then the other?
        // Let's decode into a specific wrapper or the AnalysisResult enum directly if we custom decode.
        // Easier: Decode to a struct that has all fields optional, then map to Enum.
        
        struct RawResult: Decodable {
            let type: String?
            // Part fields
            let partName: String?
            let likelyModels: [String]?
            let searchQuery: String?
            let estimatedPriceRange: String?
            
            // Error fields
            let errorCode: String?
            let description: String?
            let possibleCauses: [String]?
            let suggestedFixes: [String]?
            
            let confidence: String
        }
        
        let raw = try JSONDecoder().decode(RawResult.self, from: jsonData)
        
        if raw.type == "error" || defaultToError { // Fallback if type missing
            return .error(ErrorCodeResult(
                errorCode: raw.errorCode ?? "Unknown Error",
                description: raw.description ?? "No description available",
                possibleCauses: raw.possibleCauses ?? [],
                suggestedFixes: raw.suggestedFixes ?? [],
                confidence: raw.confidence
            ))
        } else {
            return .part(PartIdentificationResult(
                partName: raw.partName ?? "Unknown Part",
                likelyModels: raw.likelyModels ?? [],
                searchQuery: raw.searchQuery ?? "",
                estimatedPriceRange: raw.estimatedPriceRange ?? "N/A",
                confidence: raw.confidence
            ))
        }
    }
}

enum AnalysisMode {
    case part
    case error
    case audio
}

enum AnalysisResult {
    case part(PartIdentificationResult)
    case error(ErrorCodeResult)
}

struct ErrorCodeResult: Codable {
    let errorCode: String
    let description: String
    let possibleCauses: [String]
    let suggestedFixes: [String]
    let confidence: String
}
