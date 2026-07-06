import SwiftUI

struct MediaGridView: View {
    let images: [MediaItem]
    let videos: [MediaItem]
    var onDownloadImage: ((String) -> Void)?
    var onDownloadVideo: ((String) -> Void)?

    var body: some View {
        let allItems: [(type: String, item: MediaItem)] =
            images.map { ("image", $0) } + videos.map { ("video", $0) }

        LazyVGrid(columns: [.init(.flexible(), spacing: 10), .init(.flexible(), spacing: 10)],
                  spacing: 10) {
            ForEach(allItems.indices, id: \.self) { idx in
                let entry = allItems[idx]
                MediaCardView(
                    url: entry.item.url,
                    thumbnail: entry.item.thumbnailUrl,
                    isVideo: entry.type == "video",
                    duration: entry.item.duration,
                    resolutions: entry.item.resolutions
                ) {
                    if entry.type == "video" {
                        onDownloadVideo?(entry.item.url)
                    } else {
                        onDownloadImage?(entry.item.url)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

struct MediaCardView: View {
    let url: String
    var thumbnail: String?
    var isVideo: Bool = false
    var duration: Double?
    var resolutions: [VideoResolution]?
    var onDownload: (() -> Void)?

    @EnvironmentObject var downloadVM: DownloadViewModel

    private var task: DownloadTask? {
        downloadVM.tasks.first { $0.url == url }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 缩略图
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: thumbnail ?? url)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Rectangle().fill(Color(.systemGray5))
                            .overlay(Text(isVideo ? "🎬" : "🖼️").font(.title))
                    }
                }
                .frame(height: 120)
                .clipped()

                if isVideo {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill").font(.caption2)
                        if let d = duration {
                            Text(formatDuration(d)).font(.caption2)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(6)
                }
            }

            // 下载按钮 / 进度
            VStack(spacing: 4) {
                if let t = task {
                    switch t.status {
                    case .downloading:
                        ProgressView(value: t.progress)
                            .tint(.orange).padding(.horizontal, 8)
                        Text("\(Int(t.progress * 100))%")
                            .font(.caption2).foregroundColor(.secondary)
                    case .completed:
                        Label("已完成", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundColor(.green)
                    case .failed:
                        Button("重试") { onDownload?() }
                            .font(.caption).foregroundColor(.red)
                    default:
                        downloadButton
                    }
                } else {
                    downloadButton
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var downloadButton: some View {
        Button(action: { onDownload?() }) {
            Label(isVideo ? "下载视频" : "下载图片", systemImage: "arrow.down.to.line")
                .font(.caption).fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 6)
        }
    }

    private func formatDuration(_ sec: Double) -> String {
        let m = Int(sec) / 60, s = Int(sec) % 60
        return "\(m):\(String(format: "%02d", s))"
    }
}
