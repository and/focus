import Foundation

class AppCategorizer {
    static let shared = AppCategorizer()
    
    private var defaultMappings: [AppCategory: [String]] = [:]
    private var customMappings: [String: AppCategory] = [:]
    
    // Custom keyword rules for browser titles
    private(set) var browserKeywordRules: [String: AppCategory] = [
        "github": .productive,
        "stack overflow": .productive,
        "stackoverflow": .productive,
        "docs": .productive,
        "google docs": .productive,
        "figma": .productive,
        "notion": .productive,
        "youtube": .distracting,
        "reddit": .distracting,
        "twitter": .distracting,
        "facebook": .distracting,
        "netflix": .distracting
    ]
    
    private init() {
        loadDefaultMappings()
        loadCustomMappings()
        loadBrowserKeywordRules()
    }
    
    private func loadDefaultMappings() {
        if let url = Bundle.main.url(forResource: "DefaultCategories", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] {
            for (key, values) in json {
                if let category = AppCategory(rawValue: key) {
                    defaultMappings[category] = values
                }
            }
        } else {
            // Fallback hardcoded defaults if JSON fails to load
            defaultMappings = [
                .productive: [
                    "com.apple.dt.Xcode", "com.microsoft.VSCode", "com.sublimetext.3",
                    "com.figma.Desktop", "com.linear", "com.notion.id", "com.obsidian"
                ],
                .communication: [
                    "com.tinyspeck.slackmacgap", "com.apple.mail", "com.microsoft.Outlook", "us.zoom.xos"
                ],
                .distracting: [
                    "com.spotify.client", "com.apple.Music", "tv.twitch.studio"
                ],
                .neutral: [
                    "com.apple.finder", "com.apple.systempreferences", "com.apple.calculator", "com.apple.Preview"
                ]
            ]
        }
    }
    
    private func loadCustomMappings() {
        if let data = UserDefaults.standard.data(forKey: "FocusFlowCustomMappings"),
           let decoded = try? JSONDecoder().decode([String: AppCategory].self, from: data) {
            customMappings = decoded
        }
    }
    
    private func saveCustomMappings() {
        if let encoded = try? JSONEncoder().encode(customMappings) {
            UserDefaults.standard.set(encoded, forKey: "FocusFlowCustomMappings")
        }
    }
    
    private func loadBrowserKeywordRules() {
        if let data = UserDefaults.standard.data(forKey: "FocusFlowBrowserRules"),
           let decoded = try? JSONDecoder().decode([String: AppCategory].self, from: data) {
            browserKeywordRules = decoded
        }
    }
    
    private func saveBrowserKeywordRules() {
        if let encoded = try? JSONEncoder().encode(browserKeywordRules) {
            UserDefaults.standard.set(encoded, forKey: "FocusFlowBrowserRules")
        }
    }
    
    func setCategory(for bundleID: String, category: AppCategory) {
        customMappings[bundleID] = category
        saveCustomMappings()
    }
    
    func removeCategoryOverride(for bundleID: String) {
        customMappings.removeValue(forKey: bundleID)
        saveCustomMappings()
    }
    
    func addBrowserKeywordRule(keyword: String, category: AppCategory) {
        browserKeywordRules[keyword.lowercased()] = category
        saveBrowserKeywordRules()
    }
    
    func removeBrowserKeywordRule(keyword: String) {
        browserKeywordRules.removeValue(forKey: keyword.lowercased())
        saveBrowserKeywordRules()
    }
    
    func isBrowser(bundleID: String) -> Bool {
        let browsers = ["com.apple.Safari", "com.google.Chrome", "company.thebrowser.Browser", "org.mozilla.firefox"]
        return browsers.contains(bundleID)
    }
    
    func getCustomMappings() -> [String: AppCategory] {
        return customMappings
    }
    
    func categorize(bundleID: String, windowTitle: String? = nil) -> AppCategory {
        // 1. Check custom overrides
        if let custom = customMappings[bundleID] {
            return custom
        }
        
        // 2. Check browsers with window titles
        if isBrowser(bundleID: bundleID), let title = windowTitle?.lowercased() {
            for (keyword, category) in browserKeywordRules {
                if title.contains(keyword) {
                    return category
                }
            }
            return .neutral // Default browser fallback if no keywords match
        }
        
        // 3. Check default mappings (supporting wildcards like com.jetbrains.*)
        for (category, bundleIDs) in defaultMappings {
            for pattern in bundleIDs {
                if pattern.contains("*") {
                    let prefix = pattern.replacingOccurrences(of: "*", with: "")
                    if bundleID.hasPrefix(prefix) {
                        return category
                    }
                } else if bundleID == pattern {
                    return category
                }
            }
        }
        
        return .neutral // Default fallback
    }
}
