import Foundation

final class KuaishouParser: BaseParser, PlatformParser {
    let platform: PlatformType = .kuaishou

    func canParse(_ url: String) -> Bool {
        platform.domains.contains { url.lowercased().contains($0) }
    }

    func extractContentId(_ url: String) -> String {
        let patterns = [#"/short-video/([a-zA-Z0-9]+)"#, #"/fw/video/([a-zA-Z0-9]+)"#, #"/photo/([a-zA-Z0-9]+)"#]
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
        if url.contains("v.kuaishou.com") {
            if let shortURL = URL(string: url) {
                finalURL = (try? await resolveShortURL(shortURL))?.absoluteString ?? url
            }
        }

        guard let pageURL = URL(string: finalURL) else { throw ParseError.parseFailed("无效URL") }
        let html = try await fetchHTML(pageURL)

        var result = ParseResult(
            id: id(), originalUrl: url, platform: .kuaishou,
            description: "", images: [], videos: [], tags: [], parsedAt: Date()
        )

        if let state = extractJSON(from: html, key: "__INITIAL_STATE__") {
            parseState(&result, state)
        }

        if result.description.isEmpty {
            extractFromHTML(&result, html)
        }

        return result
    }

    private func parseState(_ result: inout ParseResult, _ state: [String: Any]) {
        let feeds = (state["feed"] as? [String: Any])?["feeds"] as? [[String: Any]]
            ?? (state["shortVideo"] as? [String: Any])?["feeds"] as? [[String: Any]]
            ?? (state["photo"] as? [String: Any])?["feeds"] as? [[String: Any]]

        if let item = feeds?.first {
            parseItem(&result, item)
        } else if let detail = state["videoDetail"] as? [String: Any] {
            parseItem(&result, detail)
        } else {
            searchItem(&result, state)
        }
    }

    private func parseItem(_ result: inout ParseResult, _ item: [String: Any]) {
        result.description = (item["caption"] as? String) ?? (item["description"] as? String) ?? ""
        result.description = result.description.isEmpty
            ? ((item["share_info"] as? [String: Any])?["title"] as? String) ?? ""
            : result.description

        if let author = (item["author"] as? [String: Any]) ?? (item["user"] as? [String: Any]) {
            result.author = AuthorInfo(
                name: (author["name"] as? String) ?? (author["user_name"] as? String) ?? "",
                id: (author["id"] as? String) ?? (author["eid"] as? String) ?? "",
                avatar: (author["headurl"] as? String) ?? (author["avatar"] as? String)
            )
        }

        result.stats = ContentStats(
            likes: Int(item["like_count"] as? String ?? "0") ?? 0,
            comments: Int(item["comment_count"] as? String ?? "0") ?? 0,
            shares: Int(item["share_count"] as? String ?? "0") ?? 0,
            plays: Int(item["view_count"] as? String ?? "0") ?? 0
        )

        if let photos = item["photo_info"] as? [String: Any],
           let urls = photos["urls"] as? [String] {
            result.images = urls.enumerated().map { idx, u in
                MediaItem(id: "\(id())-img-\(idx)", url: u, thumbnailUrl: u,
                          width: nil, height: nil, duration: nil, resolutions: nil)
            }
        } else if let images = item["images"] as? [[String: Any]] {
            result.images = images.enumerated().compactMap { idx, img in
                let u = (img["url"] as? String) ?? (img["src"] as? String) ?? ""
                return u.isEmpty ? nil : MediaItem(id: "\(id())-img-\(idx)", url: u, thumbnailUrl: u,
                                                    width: nil, height: nil, duration: nil, resolutions: nil)
            }
        }

        let videoURL = (item["main_mv_url"] as? String) ?? (item["video_url"] as? String)
            ?? (item["photo"] as? [String: Any])?["video_url"] as? String

        if let vurl = videoURL, !vurl.isEmpty {
            let thumb = (item["cover_thumbnail_url"] as? String)
                ?? (item["thumbnail_url"] as? String) ?? (item["poster"] as? String)
            result.videos = [MediaItem(
                id: "\(id())-vid", url: vurl, thumbnailUrl: thumb,
                width: item["width"] as? Int, height: item["height"] as? Int,
                duration: item["duration"] as? Double,
                resolutions: [VideoResolution(label: "默认", url: vurl, width: 0, height: 0, bitrate: nil)]
            )]
        }

        if let bgm = item["bgm"] as? [String: Any] ?? item["music"] as? [String: Any] {
            result.music = MusicInfo(
                title: (bgm["name"] as? String) ?? (bgm["title"] as? String) ?? "",
                author: (bgm["author"] as? String) ?? (bgm["singer"] as? String) ?? "",
                url: (bgm["url"] as? String) ?? (bgm["playUrl"] as? String)
            )
        }

        if let tags = item["tags"] as? [[String: Any]] {
            result.tags = tags.compactMap {
                ($0["name"] as? String) ?? ($0["tag"] as? String)
            }.map { "#\($0)" }
        }
    }

    private func searchItem(_ result: inout ParseResult, _ obj: Any) {
        guard let dict = obj as? [String: Any] else { return }
        if dict["main_mv_url"] != nil || dict["video_url"] != nil,
           dict["caption"] != nil || dict["user"] != nil || dict["author"] != nil {
            parseItem(&result, dict)
            return
        }
        for (_, v) in dict {
            if let arr = v as? [[String: Any]] {
                for item in arr { searchItem(&result, item); if !result.description.isEmpty { return } }
            } else {
                searchItem(&result, v); if !result.description.isEmpty { return }
            }
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
