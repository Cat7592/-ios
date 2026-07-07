import Foundation
import WebKit
import UIKit

/// 基于 WKWebView 的解析器 —— 加载页面后用 JS 提取渲染后的数据
@MainActor
final class WebViewParser: NSObject {
    private var webView: WKWebView?
    private var window: UIWindow?
    private var continuation: CheckedContinuation<ParseResult, any Error>?
    private let platform: PlatformType
    private let originalURL: String

    init(platform: PlatformType, url: String) {
        self.platform = platform
        self.originalURL = url
        super.init()
    }

    func parse() async throws -> ParseResult {
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            let config = WKWebViewConfiguration()
            config.websiteDataStore = .nonPersistent()
            let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 844), configuration: config)
            wv.navigationDelegate = self
            wv.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
            wv.isHidden = true
            self.webView = wv

            // 必须挂到 window 上否则 JS 可能不执行
            let win = UIWindow(frame: UIScreen.main.bounds)
            win.windowLevel = .alert - 1
            win.isHidden = false
            win.rootViewController = UIViewController()
            win.rootViewController?.view.addSubview(wv)
            self.window = win

            guard let url = URL(string: originalURL) else {
                cont.resume(throwing: ParseError.parseFailed("无效URL"))
                return
            }
            let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            wv.load(req)
        }
    }

    private func cleanup() {
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
        window?.isHidden = true
        window = nil
    }

    private func resume(with result: ParseResult) {
        continuation?.resume(returning: result)
        continuation = nil
        cleanup()
    }

    private func resume(error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        cleanup()
    }
}

// MARK: - WKNavigationDelegate

extension WebViewParser: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 页面加载完成后等 3 秒让 JS 渲染完毕
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await extractData()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        resume(error: ParseError.parseFailed("页面加载失败: \(error.localizedDescription)"))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        resume(error: ParseError.parseFailed("无法访问: \(error.localizedDescription)"))
    }

    // MARK: - 数据提取

    private func extractData() async {
        guard let wv = webView else { return }
        let js = buildExtractionJS()

        do {
            let jsonStr = try await wv.evaluateJavaScript(js) as? String ?? ""
            guard let data = jsonStr.data(using: .utf8),
                  let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                // JS 提取失败，用基础 meta 降级
                let fallback = try? await wv.evaluateJavaScript(basicMetaJS()) as? String ?? ""
                if let fb = fallback, let fbData = fb.data(using: .utf8),
                   let fbDict = try JSONSerialization.jsonObject(with: fbData) as? [String: Any] {
                    resume(with: buildResult(from: fbDict))
                } else {
                    resume(error: ParseError.parseFailed("无法从页面提取内容"))
                }
                return
            }
            resume(with: buildResult(from: dict))
        } catch {
            resume(error: ParseError.parseFailed("JS 执行失败: \(error.localizedDescription)"))
        }
    }

    // MARK: - JS 脚本

    /// 平台特定 JS 提取脚本
    private func buildExtractionJS() -> String {
        switch platform {
        case .douyin:
            return douyinJS()
        case .kuaishou:
            return kuaishouJS()
        case .tiktok:
            return tiktokJS()
        case .xiaohongshu:
            return xiaohongshuJS()
        case .unknown:
            return basicMetaJS()
        }
    }

    /// 通用 meta 提取（降级方案）
    private func basicMetaJS() -> String {
        """
        JSON.stringify({
            title: document.title || '',
            description: (document.querySelector('meta[property="og:description"]')?.content || document.querySelector('meta[name="description"]')?.content || ''),
            images: Array.from(document.querySelectorAll('img')).filter(i => i.naturalWidth > 200).map(i => i.src).slice(0, 20),
            videos: Array.from(document.querySelectorAll('video source, video')).map(v => v.src || v.currentSrc).filter(s => s),
            author: (document.querySelector('meta[property="og:title"]')?.content || document.querySelector('meta[name="author"]')?.content || '')
        })
        """
    }

    private func douyinJS() -> String {
        """
        (function() {
            var d = { title: document.title || '', description: '', images: [], videos: [], author: '', tags: [], music: '' };
            var t = document.title || '';
            if (t) { d.description = t; d.author = t.split(' - ')[0] || t; }
            try {
                var s = document.getElementById('RENDER_DATA');
                if (s && s.textContent) {
                    var raw = decodeURIComponent(s.textContent);
                    try { var obj = JSON.parse(raw); if (obj) { window.__parsed = obj; } } catch(e) {}
                }
            } catch(e) {}
            try {
                if (window.__parsed) {
                    var item = null;
                    var p = window.__parsed;
                    function find(obj, d) { if (!obj || d>8) return null; if (typeof obj==='object' && obj.desc && (obj.video||obj.images)) return obj; for(var k in obj) { var v=obj[k]; if (Array.isArray(v)) { for(var i=0;i<v.length;i++) { var f=find(v[i],d+1); if(f) return f; } } else if (typeof v==='object') { var f=find(v,d+1); if(f) return f; } } return null; }
                    item = find(p, 0);
                    if (item) {
                        d.description = item.desc || d.description;
                        if (item.author) { d.author = item.author.nickname || d.author; }
                        if (item.video && item.video.play_addr && item.video.play_addr.url_list) {
                            d.videos = [item.video.play_addr.url_list[0]];
                        }
                        if (item.images && Array.isArray(item.images)) {
                            d.images = item.images.map(function(i) { return (i.url_list||[])[0] || ''; }).filter(Boolean);
                        }
                        if (item.music) { d.music = item.music.title || ''; }
                        if (item.text_extra) { d.tags = item.text_extra.map(function(t){ return t.hashtag_name||''; }).filter(Boolean); }
                    }
                }
            } catch(e) {}
            return JSON.stringify(d);
        })()
        """
    }

    private func kuaishouJS() -> String {
        """
        (function() {
            var d = { title: document.title, description: '', images: [], videos: [], author: '' };
            try {
                var state = window.__INITIAL_STATE__;
                if (state) {
                    var feed = (state.feed||{}).feeds || (state.shortVideo||{}).feeds || (state.photo||{}).feeds || [];
                    var item = feed[0] || state.videoDetail || {};
                    d.description = item.caption || item.description || d.description;
                    d.author = (item.author||{}).name || (item.user||{}).user_name || '';
                    if (item.photo_info && item.photo_info.urls) { d.images = item.photo_info.urls; }
                    if (item.main_mv_url) { d.videos = [item.main_mv_url]; }
                    else if (item.video_url) { d.videos = [item.video_url]; }
                    if (item.images) { d.images = item.images.map(function(i){ return i.url||i.src||''; }).filter(Boolean); }
                }
            } catch(e) {}
            return JSON.stringify(d);
        })()
        """
    }

    private func tiktokJS() -> String {
        """
        (function() {
            var d = { title: document.title, description: '', images: [], videos: [], author: '', music: '' };
            try {
                var s = document.getElementById('SIGI_STATE');
                if (s && s.textContent) {
                    var state = JSON.parse(s.textContent);
                    var items = state.ItemModule || (state.AppContext||{}).ItemModule || {};
                    var keys = Object.keys(items);
                    if (keys.length) {
                        var item = items[keys[0]];
                        d.description = item.desc || '';
                        d.author = (item.author||{}).nickname || (item.author||{}).uniqueId || '';
                        if (item.video && item.video.playAddr) {
                            d.videos = [(item.video.playAddr.urlList||[])[0]];
                        }
                        if (item.video && item.video.cover) {
                            d.images = [(item.video.cover.urlList||[])[0]];
                        }
                        if (item.imagePost && item.imagePost.images) {
                            d.images = item.imagePost.images.map(function(i){ return (i.imageURL||{}).urlList&&(i.imageURL.urlList[0])||''; }).filter(Boolean);
                        }
                        if (item.music) { d.music = item.music.title || ''; }
                    }
                }
            } catch(e) {}
            return JSON.stringify(d);
        })()
        """
    }

    private func xiaohongshuJS() -> String {
        """
        (function() {
            var d = { title: document.title, description: '', images: [], videos: [], author: '' };
            try {
                var state = window.__INITIAL_STATE__;
                if (state && state.note) {
                    var noteMap = state.note.noteDetailMap || {};
                    for (var k in noteMap) {
                        var note = (noteMap[k]||{}).note || noteMap[k];
                        if (note) {
                            d.description = note.title || note.desc || '';
                            d.author = (note.user||{}).nickname || (note.user||{}).nickName || '';
                            var imgs = note.imageList || note.images_list || [];
                            d.images = imgs.map(function(i){ return i.url||i.urlDefault||''; }).filter(Boolean);
                            if (note.video && note.video.media && note.video.media.stream) {
                                var s = note.video.media.stream;
                                var h264 = (s.h264||s.h265||[])[0];
                                if (h264) d.videos = [h264.masterUrl || ''];
                            }
                            break;
                        }
                    }
                }
            } catch(e) {}
            return JSON.stringify(d);
        })()
        """
    }

    // MARK: - 结果组装

    private func buildResult(from dict: [String: Any]) -> ParseResult {
        let desc = (dict["description"] as? String) ?? (dict["title"] as? String) ?? ""
        let authorName = (dict["author"] as? String) ?? ""
        let imageURLs = (dict["images"] as? [String]) ?? []
        let videoURLs = (dict["videos"] as? [String]) ?? []
        let tags = (dict["tags"] as? [String])?.map { $0.hasPrefix("#") ? $0 : "#\($0)" } ?? []
        let music = dict["music"] as? String

        let id = "\(Int(Date().timeIntervalSince1970 * 1000))-\(Int.random(in: 1000...9999))"

        let images: [MediaItem] = imageURLs.enumerated().compactMap { idx, url in
            url.isEmpty ? nil : MediaItem(id: "\(id)-img-\(idx)", url: url, thumbnailUrl: url,
                                          width: nil, height: nil, duration: nil, resolutions: nil)
        }
        let videos: [MediaItem] = videoURLs.enumerated().compactMap { idx, url in
            url.isEmpty ? nil : MediaItem(
                id: "\(id)-vid-\(idx)", url: url, thumbnailUrl: nil,
                width: nil, height: nil, duration: nil,
                resolutions: [VideoResolution(label: "默认", url: url, width: 0, height: 0, bitrate: nil)]
            )
        }

        return ParseResult(
            id: id, originalUrl: originalURL, platform: platform,
            description: desc, author: AuthorInfo(name: authorName, id: "", avatar: nil),
            images: images, videos: videos,
            stats: nil,
            music: music.map { MusicInfo(title: $0, author: "", url: nil) },
            tags: tags, publishTime: nil, parsedAt: Date()
        )
    }
}
