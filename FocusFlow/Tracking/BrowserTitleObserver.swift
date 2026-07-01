import Foundation

class BrowserTitleObserver {
    static let shared = BrowserTitleObserver()
    
    private init() {}
    
    func cleanBrowserTitle(bundleID: String, windowTitle: String) -> String {
        var title = windowTitle
        
        switch bundleID {
        case "com.apple.Safari":
            if title.hasSuffix(" — Safari") {
                title = String(title.dropLast(9))
            }
        case "com.google.Chrome":
            if title.hasSuffix(" - Google Chrome") {
                title = String(title.dropLast(16))
            }
        case "org.mozilla.firefox":
            if title.hasSuffix(" — Mozilla Firefox") {
                title = String(title.dropLast(18))
            }
        default:
            break
        }
        
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
