import Foundation

final class XiaohongshuParser: BaseParser, PlatformParser {
    let platform: PlatformType = .xiaohongshu

    func canParse(_ url: String) -> Bool {
        platform.domains.contains { url.lowercased().contains($0) }
    }

    func extractContentId(_ url: String) -> String {
        let patterns = [#"/explore/([a-zA-Z0-9]+)"#, #"/discovery/item/([a-zA-Z0-9]+)"#, #"/([a-zA-Z0-9]{24})"#]
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
        if url.contains("xhslink.com") || url.contains("xhs.com") {
            finalURL = (try? await resolveShortURL(URL(string: url)!))?.absoluteString ?? url
        }

        guard let pageURL = URL(string: finalURL) else { throw ParseError.parseFailed("无效URL") }
        let html = try await fetchHTML(pageURL)

        var result = ParseResult(
            id: id(), originalUrl: url, platform: .xiaohongshu,
            description: "", images: [], videos: [], tags: [], parsedAt: Date()
        )

        if let state = extractInitialState(html) {
            parseState(&result, state)
        }

        if result.description.isEmpty {
            parseHTML(&result, html)
        }

        return result
    }

    private func extractInitialState(_ html: String) -> [String: Any]? {
        guard let regex = try? NSRegularExpression(
            pattern: #"window\.__INITIAL_STATE__\s*=\s*(\{[\s\S]*?\})\s*</script>"#,
            options: []
        ), let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: html)
        else { return nil }

        let sanitized = String(html[range]).replacingOccurrences(of: "undefined", with: "null")
        guard let data = sanitized.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let dict = obj as? [String: Any]
        else { return nil }
        return dict
    }

    private func parseState(_ result: inout ParseResult, _ state: [String: Any]) {
        // 查找笔记数据
        var noteData: [String: Any]?

        if let noteMap: [String: Any] = value(in: state, path: "note.noteDetailMap") {
            for (_, detail) in noteMap {
                if let d = detail as? [String: Any], let note = d["note"] as? [String: Any] {
                    noteData = note; break
                }
            }
        }

        if noteData == nil, let noteList: [[String: Any]] = value(in: state, path: "note.noteList") {
            noteData = noteList.first
        }

        if let note = noteData { parseNote(&result, note) }
    }

    private func parseNote(_ result: inout ParseResult, _ note: [String: Any]) {
        result.description = (note["title"] as? String) ?? (note["desc"] as? String) ?? ""

        if let user = (note["user"] as? [String: Any]) ?? (note["author"] as? [String: Any]) {
            result.author = AuthorInfo(
                name: (user["nickname"] as? String) ?? (user["nickName"] as? String) ?? "",
                id: (user["userId"] as? String) ?? (user["id"] as? String) ?? "",
                avatar: (user["avatar"] as? String) ?? (user["images"] as? String)
            )
        }

        if let interact = note["interactInfo"] as? [String: Any] {
            result.stats = ContentStats(
                likes: Int(interact["likedCount"] as? String ?? "0") ?? 0,
                comments: Int(interact["commentCount"] as? String ?? "0") ?? 0,
                shares: Int(interact["shareCount"] as? String ?? "0") ?? 0,
                plays: 0
            )
        }

        // 图片
        let imageSources: [[String: Any]]? = {
            if let list = note["imageList"] as? [[String: Any]] { return list }
            if let list = note["images_list"] as? [[String: Any]] { return list }
            if let list = note["image_list"] as? [[String: Any]] { return list }
            return nil
        }()

        if let images = imageSources {
            result.images = images.enumerated().compactMap { idx, img in
                let u = (img["url"] as? String) ?? (img["urlDefault"] as? String) ?? ""
                return u.isEmpty ? nil : MediaItem(id: "\(id())-img-\(idx)", url: u, thumbnailUrl: u,
                                                    width: nil, height: nil, duration: nil, resolutions: nil)
            }
        }

        // 视频
        if let video = note["video"] as? [String: Any] {
            let vurl: String = {
                if let media = video["media"] as? [String: Any],
                   let stream = media["stream"] as? [String: Any],
                   let h264 = (stream["h264"] as? [[String: Any]]) ?? (stream["h265"] as? [[String: Any]]),
                   let first = h264.first,
                   let url = first["masterUrl"] as? String {
                    return url
                }
                return (video["url"] as? String) ?? ""
            }()

            if !vurl.isEmpty {
                let thumb = (video["image"] as? [String: Any])?["thumbnail"] as? [String]
                result.videos = [MediaItem(
                    id: "\(id())-vid", url: vurl, thumbnailUrl: thumb?.first,
                    width: video["width"] as? Int, height: video["height"] as? Int,
                    duration: video["duration"] as? Double,
                    resolutions: [VideoResolution(label: "高清", url: vurl, width: 0, height: 0, bitrate: nil)]
                )]
            }
        }

        // 标签
        if let tags = note["tagList"] as? [[String: Any]] {
            result.tags = tags.compactMap {
                ($0["name"] as? String) ?? ($0["tagName"] as? String)
            }.map { "#\($0)" }
        }

        if let ts = note["time"] as? TimeInterval {
            let sec = ts > 9999999999 ? ts / 1000 : ts
            result.publishTime = Date(timeIntervalSince1970: sec)
        }
    }

    private func parseHTML(_ result: inout ParseResult, _ html: String) {
        if let desc = extractMeta(html, key: "description") { result.description = desc }
        if let title = extractMeta(html, key: "title") {
            let clean = title.replacingOccurrences(of: #"\s*[-–—|]\s*小红书.*$"#, with: "", options: .regularExpression)
            result.description = result.description.isEmpty ? clean : result.description
            result.author = AuthorInfo(name: clean, id: "", avatar: nil)
        }
    }

    private func extractMeta(_ html: String, key: String) -> String? {
        let pattern = #"<meta[^>]*(?:name|property)="\#(key)"[^>]*content="([^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: html)
        else { return nil }
        return String(html[range])
    }
}
