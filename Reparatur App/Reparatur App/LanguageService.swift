import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable {
    case german = "de"
    case english = "en"
    
    var flag: String {
        switch self {
        case .german: return "🇩🇪"
        case .english: return "🇺🇸"
        }
    }
    
    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        }
    }
}

class LanguageService: ObservableObject {
    static let shared = LanguageService()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
        }
    }
    
    init() {
        if let stored = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let lang = AppLanguage(rawValue: stored) {
            self.currentLanguage = lang
        } else {
            // Auto-detect using preferred languages
            let preferredLanguage = Locale.preferredLanguages.first ?? Locale.current.identifier
            if preferredLanguage.hasPrefix("de") {
                self.currentLanguage = .german
            } else {
                self.currentLanguage = .english
            }
        }
    }
    
    func setLanguage(_ language: AppLanguage) {
        self.currentLanguage = language
    }
    
    // MARK: - Translations
    
    func localizedString(_ key: StringKey) -> String {
        let isGerman = currentLanguage == .german
        
        switch key {
        case .appName:
            return isGerman ? "Reparatur Helfer" : "Repair Helper"
        case .analyzePart:
            return isGerman ? "Analysiere Bauteil..." : "Analyzing Part..."
        case .newPhoto:
            return isGerman ? "Neues Foto" : "New Photo"
        case .takePhotoInstruction:
            return isGerman ? "Fotografiere das defekte Teil" : "Take a photo of the broken part"
        case .takePhotoButton:
            return isGerman ? "Foto aufnehmen" : "Take Photo"
        case .compatibleModels:
            return isGerman ? "Kompatible Modelle:" : "Compatible Models:"
        case .estimatedPrice:
            return isGerman ? "Geschätzter Preis" : "Estimated Price"
        case .startPriceCompare:
            return isGerman ? "Preisvergleich starten" : "Start Price Comparison"
        case .errorPrefix:
            return isGerman ? "Fehler bei der Analyse: " : "Analysis Error: "
        case .unknownError:
            return isGerman ? "Unbekannter Fehler" : "Unknown Error"
        case .cancel:
            return isGerman ? "Abbrechen" : "Cancel"
        case .communityHelp:
            return isGerman ? "Community fragen" : "Ask Community"
        case .backToMenu:
            return isGerman ? "Zurück zum Menü" : "Back to Menu"
        case .disclaimerTitle:
            return isGerman ? "Wichtiger Sicherheitshinweis" : "Important Safety Warning"
        case .disclaimerText:
            return isGerman ? """
            Bitte beachte, dass dies eine KI-gestützte Anwendung ist. Die Analysen können fehlerhaft sein.
            
            Reparaturen an elektrischen Geräten bergen Risiken, insbesondere durch Stromschlag und Brandgefahr.
            
            • Trenne das Gerät immer vom Stromnetz, bevor du es öffnest.
            • Führe Reparaturen nur durch, wenn du über das nötige Fachwissen verfügst.
            • Wir übernehmen keine Haftung für Schäden an Gerät oder Person.
            """ : """
            Please note that this is an AI-powered application. Analyses may be incorrect.
            
            Repairing electrical appliances involves risks, especially from electric shock and fire hazards.
            
            • Always disconnect the appliance from the mains before opening it.
            • Only perform repairs if you have the necessary expertise.
            • We assume no liability for damage to the device or personal injury.
            """
        case .acceptDisclaimer:
            return isGerman ? "Verstanden & Akzeptieren" : "Understand & Accept"
        }
    }
    
    enum StringKey {
        case appName
        case analyzePart
        case newPhoto
        case takePhotoInstruction
        case takePhotoButton
        case compatibleModels
        case estimatedPrice
        case startPriceCompare
        case errorPrefix
        case unknownError
        case cancel
        case communityHelp
        case backToMenu
        case disclaimerTitle
        case disclaimerText
        case acceptDisclaimer
    }
}
