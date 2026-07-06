import Foundation

struct URLDetector {
    /// 从文本中提取 URL
    static func extractURLs(from text: String) -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else { return [] }
        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { $0.url?.absoluteString }
    }

    /// 检测平台
    static func detectPlatform(_ url: String) -> PlatformType {
        let lower = url.lowercased()
        for platform in PlatformType.allCases where platform != .unknown {
            if platform.domains.contains(where: { lower.contains($0) }) {
                return platform
            }
        }
        return .unknown
    }

    /// 是否是支持的链接
    static func isSupported(_ url: String) -> Bool {
        detectPlatform(url) != .unknown
    }

    /// 标准化 URL（去追踪参数）
    static func normalize(_ url: String) -> String {
        guard var comps = URLComponents(string: url.trimmingCharacters(in: .whitespaces))
        else { return url }
        let tracking = ["utm_source","utm_medium","utm_campaign","spm","scm","share_id","track_id"]
        comps.queryItems = comps.queryItems?.filter { !tracking.contains($0.name) }
        return comps.string ?? url
    }
}
