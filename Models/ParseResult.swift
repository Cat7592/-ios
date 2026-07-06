import Foundation

/// 媒体项
struct MediaItem: Identifiable, Codable {
    let id: String
    let url: String
    let thumbnailUrl: String?
    let width: Int?
    let height: Int?
    let duration: Double?
    let resolutions: [VideoResolution]?
}

/// 视频分辨率
struct VideoResolution: Identifiable, Codable {
    var id: String { label }
    let label: String
    let url: String
    let width: Int
    let height: Int
    let bitrate: Int?
}

/// 解析结果
struct ParseResult: Identifiable, Codable {
    let id: String
    let originalUrl: String
    var platform: PlatformType
    var platformName: String { platform.displayName }
    var description: String
    var author: AuthorInfo?
    var images: [MediaItem]
    var videos: [MediaItem]
    var stats: ContentStats?
    var music: MusicInfo?
    var tags: [String]
    var publishTime: Date?
    let parsedAt: Date
}

/// 作者信息
struct AuthorInfo: Codable {
    let name: String
    let id: String
    let avatar: String?
}

/// 统计
struct ContentStats: Codable {
    let likes: Int
    let comments: Int
    let shares: Int
    let plays: Int
}

/// 音乐信息
struct MusicInfo: Codable {
    let title: String
    let author: String
    let url: String?
}
