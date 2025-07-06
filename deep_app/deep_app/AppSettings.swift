import Foundation

// Define the available models
struct AppSettings {
    // Use constants for model names to avoid typos
    static let gpt4oMini = "gpt-4o-mini"
    static let gpt4o = "gpt-4o"
    static let o3 = "o3"
    
    static let availableModels = [gpt4oMini, gpt4o, o3]
    
    // Key for UserDefaults
    static let selectedModelKey = "selectedApiModel"
    static let debugLogEnabledKey = "debugLogEnabled"
    static let demonstrationModeEnabledKey = "demonstrationModeEnabled"
    // --- ADDED Key ---
    static let enableCategoriesKey = "enableCategories"
    // --- NEW Key: toggle for future on-device model ---
    static let useLocalModelKey = "useLocalModel"
    // --- NEW Keys: Advanced Manual Editing ---
    static let showDurationEditorKey = "showDurationEditor"
    static let showDifficultyEditorKey = "showDifficultyEditor"
    static let advancedRoadmapEditingKey = "advancedRoadmapEditing"
    // --- NEW Key: Glass strength settings ---
    static let glassStrengthKey = "glassStrength"
    // --------------------------------------------------
}

// Glass strength options
enum GlassStrength: String, CaseIterable {
    case regular = "Regular"
    case clear = "Clear"
    case off = "Off"
    
    var description: String {
        switch self {
        case .regular:
            return "Standard glass effect with adaptive tinting"
        case .clear:
            return "Ultra-transparent glass for media-rich content"
        case .off:
            return "Traditional material design without glass effects"
        }
    }
} 