import Foundation

struct AppSettings {
    var videoQuality: VideoQuality = .high
    var autoSaveToGallery: Bool = true
    var maxConcurrentDownloads: Int = 3
    var clipboardAutoDetect: Bool = true
}

enum VideoQuality: String, CaseIterable {
    case high   = "high"
    case medium = "medium"
    case low    = "low"

    var label: String {
        switch self {
        case .high:   return "高清 1080p"
        case .medium: return "标清 720p"
        case .low:    return "流畅 540p"
        }
    }
}
