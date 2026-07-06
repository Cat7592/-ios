import Foundation

/// 统一解析服务
final class ParserService {
    private let parsers: [PlatformParser] = [
        DouyinParser(), KuaishouParser(), TikTokParser(), XiaohongshuParser()
    ]

    func parse(_ url: String) async throws -> ParseResult {
        let platform = URLDetector.detectPlatform(url)
        guard platform != .unknown else { throw ParseError.unsupportedPlatform }
        guard let parser = parsers.first(where: { $0.platform == platform })
        else { throw ParseError.parseFailed("解析器未就绪") }

        var result = try await parser.parse(url.trimmingCharacters(in: .whitespaces))
        result.platform = platform
        return result
    }
}
