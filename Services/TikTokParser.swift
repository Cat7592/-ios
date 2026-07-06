import Foundation

final class TikTokParser: BaseParser, PlatformParser {
    let platform: PlatformType = .tiktok

    func canParse(_ url: String) -> Bool {
        platform.domains.contains { url.lowercased().contains($0) }
    }

    func extractContentId(_ url: String) -> String {
        let patterns = [#"/video/(\d+)"#, #"/v/(\d+)"#, #"/@[\w.]+/video/(\d+)"#]
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
        if url.contains("vm.tiktok.com") || url.contains("vt.tiktok.com") {
            finalURL = (try? await resolveShortURL(URL(string: url)!))?.absoluteString ?? url
        }

        guard let pageURL = URL(string: finalURL) else { throw ParseError.parseFailed("无效URL") }
        let html = try await fetchHTML(pageURL)

        var result = ParseResult(
            id: id(), originalUrl: url, platform: .tiktok,
            description: "", images: [], videos: [], tags: [], parsedAt: Date()
        )

        if let sigi = extractJSON(from: html, key: "SIGI_STATE") {
            parseSigiState(&result, sigi)
        } else {
            extractFromHTML(&result, html)
        }

        return result
    }

    private func parseSigiState(_ result: inout ParseResult, _ state: [String: Any]) {
        let itemModule: [String: Any]? = {
            if let m = state["ItemModule"] as? [String: Any] { return m }
            if let app = state["AppContext"] as? [String: Any],
               let m = app["ItemModule"] as? [String: Any] { return m }
            return nil
        }()

        if let firstKey = itemModule?.keys.first,
           let item = itemModule?[firstKey] as? [String: Any] {
            parseTikTokItem(&result, item)
            return
        }

        // 在 VideoPage 中查找
        if let videoPage = state["VideoPage"] as? [String: Any],
           let itemInfo = videoPage["itemInfo"] as? [String: Any],
           let item = itemInfo["itemStruct"] as? [String: Any] {
            parseTikTokItem(&result, item)
        }
    }

    private func parseTikTokItem(_ result: inout ParseResult, _ item: [String: Any]) {
        result.description = (item["desc"] as? String) ?? ""

        if let author = item["author"] as? [String: Any] {
            result.author = AuthorInfo(
                name: (author["nickname"] as? String) ?? (author["uniqueId"] as? String) ?? "",
                id: (author["id"] as? String) ?? (author["uid"] as? String) ?? "",
                avatar: (author["avatarThumb"] as? String) ?? (author["avatarMedium"] as? String)
            )
        }

        if let stats = item["stats"] as? [String: Any] ?? item["statsV2"] as? [String: Any] {
            result.stats = ContentStats(
                likes: stats["diggCount"] as? Int ?? 0,
                comments: stats["commentCount"] as? Int ?? 0,
                shares: stats["shareCount"] as? Int ?? 0,
                plays: stats["playCount"] as? Int ?? 0
            )
        }

        // 图集
        if let imagePost = item["imagePost"] as? [String: Any],
           let imgs = imagePost["images"] as? [[String: Any]] {
            result.images = imgs.enumerated().compactMap { idx, img in
                let url = (img["imageURL"] as? [String: Any])?["urlList"] as? [String]
                guard let u = url?.first else { return nil }
                return MediaItem(id: "\(id())-img-\(idx)", url: u, thumbnailUrl: u,
                                 width: nil, height: nil, duration: nil, resolutions: nil)
            }
        }

        // 视频
        if let video = item["video"] as? [String: Any] {
            let playAddr = (video["playAddr"] as? [String: Any]) ?? (video["downloadAddr"] as? [String: Any])
            if let urlList = playAddr?["urlList"] as? [String], let vurl = urlList.first {
                let resolutions = buildResolutions(from: video)
                let thumb = (video["cover"] as? [String: Any])?["urlList"] as? [String]
                result.videos = [MediaItem(
                    id: "\(id())-vid", url: vurl, thumbnailUrl: thumb?.first,
                    width: video["width"] as? Int, height: video["height"] as? Int,
                    duration: video["duration"] as? Double,
                    resolutions: resolutions
                )]
            }
        }

        if let music = item["music"] as? [String: Any] {
            result.music = MusicInfo(
                title: (music["title"] as? String) ?? "",
                author: (music["authorName"] as? String) ?? (music["ownerNickname"] as? String) ?? "",
                url: (music["playUrl"] as? [String: Any])?["urlList"] as? String
            )
        }

        if let challenges = item["challenges"] as? [[String: Any]] {
            result.tags = challenges.compactMap {
                ($0["title"] as? String) ?? ($0["id"] as? String)
            }.map { "#\($0)" }
        }

        if let ts = item["createTime"] as? String, let ti = Int(ts) {
            result.publishTime = Date(timeIntervalSince1970: TimeInterval(ti))
        }
    }

    private func buildResolutions(from video: [String: Any]) -> [VideoResolution] {
        guard let bitrates = video["bitrateInfo"] as? [[String: Any]], !bitrates.isEmpty
        else { return [] }
        return bitrates.compactMap { br in
            let addr = br["PlayAddr"] as? [String: Any]
            guard let urls = addr?["UrlList"] as? [String], let u = urls.first
            else { return nil }
            let h = (addr?["Height"] as? Int) ?? 0
            let label = h >= 1080 ? "高清 1080p" : h >= 720 ? "标清 720p" : "流畅"
            return VideoResolution(label: label, url: u,
                                   width: (addr?["Width"] as? Int) ?? 0,
                                   height: h, bitrate: br["Bitrate"] as? Int)
        }
    }

    private func extractFromHTML(_ result: inout ParseResult, _ html: String) {
        if let desc = extractMeta(html, key: "description") { result.description = desc }
        if let title = extractMeta(html, key: "title") {
            result.author = AuthorInfo(name: title, id: "", avatar: nil)
        }
    }

    private func extractMeta(_ html: String, key: String) -> String? {
        let pattern = #"<meta[^>]*name="\#(key)"[^>]*content="([^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: html)
        else { return nil }
        return String(html[range])
    }
}
