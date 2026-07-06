import Foundation

/// 统一解析服务 —— WebView JS 提取为主，HTML 抓取为辅
final class ParserService {
    private let fallbackParsers: [PlatformParser] = [
        DouyinParser(), KuaishouParser(), TikTokParser(), XiaohongshuParser()
    ]

    func parse(_ url: String) async throws -> ParseResult {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        let platform = URLDetector.detectPlatform(trimmed)

        guard platform != .unknown else {
            throw ParseError.unsupportedPlatform
        }

        // 主路径：WKWebView JS 提取
        let webParser = await WebViewParser(platform: platform, url: trimmed)
        if let result = try? await webParser.parse(),
           !result.description.isEmpty || !result.images.isEmpty || !result.videos.isEmpty {
            var r = result
            r.platform = platform
            return r
        }

        // 降级：传统 HTML 抓取
        guard let parser = fallbackParsers.first(where: { $0.platform == platform })
        else { throw ParseError.parseFailed("解析器未就绪") }

        var result = try await parser.parse(trimmed)
        result.platform = platform
        return result
    }
}
