import Foundation

/// 支持平台
enum PlatformType: String, CaseIterable, Codable {
    case douyin = "douyin"
    case kuaishou = "kuaishou"
    case tiktok = "tiktok"
    case xiaohongshu = "xiaohongshu"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .douyin:   return "抖音"
        case .kuaishou: return "快手"
        case .tiktok:   return "TikTok"
        case .xiaohongshu: return "小红书"
        case .unknown:  return "未知"
        }
    }

    var icon: String {
        switch self {
        case .douyin:   return "🎵"
        case .kuaishou: return "📷"
        case .tiktok:   return "🎬"
        case .xiaohongshu: return "📕"
        case .unknown:  return "❓"
        }
    }

    var color: String {
        switch self {
        case .douyin:   return "#FF0050"
        case .kuaishou: return "#FF4906"
        case .tiktok:   return "#000000"
        case .xiaohongshu: return "#FE2C55"
        case .unknown:  return "#999999"
        }
    }

    var domains: [String] {
        switch self {
        case .douyin:
            return ["douyin.com", "iesdouyin.com", "v.douyin.com"]
        case .kuaishou:
            return ["kuaishou.com", "v.kuaishou.com", "gifshow.com", "chenzhongtech.com"]
        case .tiktok:
            return ["tiktok.com", "vm.tiktok.com", "vt.tiktok.com"]
        case .xiaohongshu:
            return ["xiaohongshu.com", "xhslink.com", "xhs.com"]
        case .unknown:
            return []
        }
    }
}
