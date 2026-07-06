import Foundation

final class DouyinParser: BaseParser, PlatformParser {
    let platform: PlatformType = .douyin

    func canParse(_ url: String) -> Bool {
        platform.domains.contains { url.lowercased().contains($0) }
    }

    func extractContentId(_ url: String) -> String {
        let patterns = [#"/video/(\d+)"#, #"/note/(\d+)"#, #"/(\d{15,})/?"#]
        for p in patterns {
            if let m = url.range(of: p, options: .regularExpression),
               let id = url[m].split(separator: "/").last {
                return String(id)
            }
        }
        return ""
    }

    func parse(_ url: String) async throws -> ParseResult {
        var finalURL = url
        if url.contains("v.douyin.com") || url.contains("t.douyin.com") {
            if let shortURL = URL(string: url) {
                finalURL = (try? await resolveShortURL(shortURL))?.absoluteString ?? url
            }
        }

        guard let pageURL = URL(string: finalURL) else { throw ParseError.parseFailed("无效URL") }
        let html = try await fetchHTML(pageURL)

        var result = ParseResult(
            id: id(), originalUrl: url, platform: .douyin,
            description: "", images: [], videos: [], tags: [], parsedAt: Date()
        )

        // 从 RENDER_DATA 提取
        if let renderRaw = extractJSON(from: html, key: "RENDER_DATA") {
            extractFromRenderData(&result, renderRaw)
        }

        // 降级：从页面 meta 提取
        if result.description.isEmpty {
            extractFromHTML(&result, html)
        }

        // API 补充
        let cid = extractContentId(finalURL)
        if !cid.isEmpty, let apiData = try? await fetchDouyinAPI(cid) {
            mergeAPI(&result, apiData)
        }

        return result
    }

    private func extractFromRenderData(_ result: inout ParseResult, _ data: [String: Any]) {
        guard let item = findItemData(data) else { return }

        result.description = (item["desc"] as? String) ?? ""

        if let author = item["author"] as? [String: Any] {
            result.author = AuthorInfo(
                name: (author["nickname"] as? String) ?? "",
                id: (author["uid"] as? String) ?? "",
                avatar: (author["avatar_thumb"] as? [String: Any])?["url_list"] as? String
            )
        }

        if let stats = item["statistics"] as? [String: Any] {
            result.stats = ContentStats(
                likes: Int(stats["digg_count"] as? String ?? "0") ?? 0,
                comments: Int(stats["comment_count"] as? String ?? "0") ?? 0,
                shares: Int(stats["share_count"] as? String ?? "0") ?? 0,
                plays: Int(stats["play_count"] as? String ?? "0") ?? 0
            )
        }

        if let images = item["images"] as? [[String: Any]], !images.isEmpty {
            result.images = images.enumerated().compactMap { idx, img in
                let urlList = img["url_list"] as? [String]
                guard let u = urlList?.first else { return nil }
                return MediaItem(id: "\(id())-img-\(idx)", url: u, thumbnailUrl: u,
                                 width: nil, height: nil, duration: nil, resolutions: nil)
            }
        }

        if let video = item["video"] as? [String: Any],
           let playAddr = video["play_addr"] as? [String: Any],
           let urlList = playAddr["url_list"] as? [String],
           let videoURL = urlList.first {
            let resolutions = buildResolutions(from: video, playAddr)
            let thumb = (video["cover"] as? [String: Any])?["url_list"] as? String
            result.videos = [MediaItem(
                id: "\(id())-vid", url: videoURL, thumbnailUrl: thumb,
                width: video["width"] as? Int, height: video["height"] as? Int,
                duration: (video["duration"] as? Double).map { $0 / 1000 },
                resolutions: resolutions
            )]
        }

        if let music = item["music"] as? [String: Any] {
            result.music = MusicInfo(
                title: (music["title"] as? String) ?? "",
                author: (music["author"] as? String) ?? "",
                url: (music["play_url"] as? [String: Any])?["url_list"] as? String
            )
        }

        if let extras = item["text_extra"] as? [[String: Any]] {
            result.tags = extras.compactMap { ($0["hashtag_name"] as? String).map { "#\($0)" } }
        }

        if let ts = item["create_time"] as? TimeInterval, ts > 0 {
            result.publishTime = Date(timeIntervalSince1970: ts)
        }
    }

    private func findItemData(_ obj: Any, depth: Int = 0) -> [String: Any]? {
        guard depth < 8, let dict = obj as? [String: Any] else { return nil }
        if dict["desc"] != nil && (dict["video"] != nil || dict["images"] != nil) { return dict }
        for (_, v) in dict {
            if let arr = v as? [[String: Any]] {
                for item in arr { if let found = findItemData(item, depth: depth + 1) { return found } }
            } else if let found = findItemData(v, depth: depth + 1) { return found }
        }
        return nil
    }

    private func buildResolutions(from video: [String: Any], _ playAddr: [String: Any]) -> [VideoResolution] {
        guard let rates = (video["bit_rate"] as? [[String: Any]]) ?? (playAddr["bit_rate"] as? [[String: Any]]),
              !rates.isEmpty else {
            return [VideoResolution(label: "默认", url: (playAddr["url_list"] as? [String])?.first ?? "",
                                    width: 0, height: 0, bitrate: nil)]
        }
        return rates.compactMap { br in
            guard let addr = br["play_addr"] as? [String: Any],
                  let urls = addr["url_list"] as? [String], let u = urls.first
            else { return nil }
            let h = addr["height"] as? Int ?? 0
            let label: String = h >= 1080 ? "高清 1080p" : h >= 720 ? "标清 720p" : "流畅 540p"
            return VideoResolution(label: label, url: u, width: addr["width"] as? Int ?? 0,
                                   height: h, bitrate: br["bit_rate"] as? Int)
        }
    }

    private func extractFromHTML(_ result: inout ParseResult, _ html: String) {
        if let desc = extractMeta(html, property: "description") { result.description = desc }
        if let title = extractMeta(html, property: "title") {
            result.author = AuthorInfo(name: title, id: "", avatar: nil)
        }
    }

    private func extractMeta(_ html: String, property: String) -> String? {
        let pattern = #"<meta[^>]*(?:property="og:\#(property)"|name="\#(property)")[^>]*content="([^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges > 2, let range = Range(match.range(at: 2), in: html)
        else { return nil }
        return String(html[range])
    }

    private func fetchDouyinAPI(_ cid: String) async throws -> [String: Any] {
        guard let url = URL(string: "https://www.iesdouyin.com/web/api/v2/aweme/iteminfo/?item_ids=\(cid)")
        else { throw ParseError.parseFailed("API URL") }
        let data = try await fetchJSON(url)
        if let items = data["item_list"] as? [[String: Any]], let first = items.first { return first }
        throw ParseError.parseFailed("API 返回空")
    }

    private func mergeAPI(_ result: inout ParseResult, _ api: [String: Any]) {
        if result.description.isEmpty, let desc = api["desc"] as? String { result.description = desc }
        if let author = api["author"] as? [String: Any], result.author == nil {
            result.author = AuthorInfo(
                name: (author["nickname"] as? String) ?? "",
                id: (author["uid"] as? String) ?? "",
                avatar: (author["avatar_thumb"] as? [String: Any])?["url_list"] as? String
            )
        }
    }
}
