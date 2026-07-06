import Foundation

/// 解析器协议
protocol PlatformParser {
    var platform: PlatformType { get }
    func canParse(_ url: String) -> Bool
    func extractContentId(_ url: String) -> String
    func parse(_ url: String) async throws -> ParseResult
}

/// 解析器基类 — 提供通用 HTML 抓取和解析工具
class BaseParser {
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8"
        ]
        return URLSession(configuration: config)
    }()

    func fetchHTML(_ url: URL) async throws -> String {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...399).contains(http.statusCode)
        else { throw ParseError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0) }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func fetchJSON(_ url: URL) async throws -> [String: Any] {
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await session.data(for: req)
        let obj = try JSONSerialization.jsonObject(with: data)
        guard let dict = obj as? [String: Any] else { throw ParseError.invalidJSON }
        return dict
    }

    /// 解析短链接重定向
    func resolveShortURL(_ url: URL) async throws -> URL {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        let (_, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse,
           let location = http.value(forHTTPHeaderField: "Location"),
           let redirect = URL(string: location) {
            return redirect
        }
        // 降级 GET
        let (_, getResp) = try await session.data(from: url)
        return getResp.url ?? url
    }

    /// 从 HTML 脚本标签提取 JSON
    func extractJSON(from html: String, key: String) -> [String: Any]? {
        let patterns = [
            #"window\.\#(key)\s*=\s*(\{[\s\S]*?\});"#,
            #"<script[^>]*id="\#(key)"[^>]*>([\s\S]*?)</script>"#,
            #""\#(key)"\s*:\s*(\{[\s\S]*?\})\s*[,}]"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: html)
            else { continue }
            let jsonStr = String(html[range])
            if let data = jsonStr.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data),
               let dict = obj as? [String: Any] {
                return dict
            }
        }
        return nil
    }

    /// 安全读取嵌套字典
    func value<T>(in dict: [String: Any], path: String) -> T? {
        let keys = path.split(separator: ".")
        var current: Any = dict
        for key in keys {
            guard let d = current as? [String: Any], let val = d[String(key)]
            else { return nil }
            current = val
        }
        return current as? T
    }

    func id() -> String {
        "\(Int(Date().timeIntervalSince1970 * 1000))-\(Int.random(in: 1000...9999))"
    }
}

enum ParseError: Error, LocalizedError {
    case httpError(Int)
    case invalidJSON
    case unsupportedPlatform
    case parseFailed(String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "HTTP 错误 (\(code))"
        case .invalidJSON:         return "数据格式错误"
        case .unsupportedPlatform: return "不支持的平台链接"
        case .parseFailed(let msg): return "解析失败: \(msg)"
        }
    }
}
