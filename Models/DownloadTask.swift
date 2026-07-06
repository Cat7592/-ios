import Foundation

enum MediaType: String, Codable {
    case image = "image"
    case video = "video"
}

enum DownloadStatus: String, Codable {
    case pending    = "pending"
    case downloading = "downloading"
    case completed  = "completed"
    case failed     = "failed"
    case cancelled  = "cancelled"
}

struct DownloadTask: Identifiable, Codable {
    let id: String
    let url: String
    let type: MediaType
    let fileName: String
    var progress: Double
    var status: DownloadStatus
    var localPath: String?
    var errorMessage: String?
    var fileSize: Int64?
    let createdAt: Date

    var progressPercent: Int {
        Int(progress * 100)
    }
}
