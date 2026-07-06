import SwiftUI
import UIKit

struct ParserResultView: View {
    let result: ParseResult
    @EnvironmentObject var downloadVM: DownloadViewModel
    @State private var expandedDesc = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 平台头
                platformHeader

                // 描述
                if !result.description.isEmpty {
                    descSection.padding(.horizontal).padding(.top, 12)
                }

                // 作者
                if let author = result.author {
                    authorSection(author).padding(.horizontal).padding(.top, 12)
                }

                // 统计
                if let stats = result.stats {
                    statsRow(stats).padding(.horizontal).padding(.top, 12)
                }

                // 音乐
                if let music = result.music {
                    musicSection(music).padding(.horizontal).padding(.top, 12)
                }

                // 标签
                if !result.tags.isEmpty {
                    tagsRow.padding(.horizontal).padding(.top, 12)
                }

                // 媒体
                if !result.images.isEmpty || !result.videos.isEmpty {
                    mediaGridSection.padding(.top, 16)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("解析结果")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var platformHeader: some View {
        VStack(spacing: 6) {
            Text(PlatformType.allCases.first { $0.displayName == result.platformName }?.icon ?? "🔗")
                .font(.largeTitle)
            Text(result.platformName).font(.title3).fontWeight(.bold).foregroundColor(.orange)
            Text("\(result.images.count + result.videos.count) 个媒体").font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    private var descSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("📝 文案").font(.subheadline).fontWeight(.semibold)
                Spacer()
                Button("复制") { UIPasteboard.general.string = result.description }
                    .font(.caption).foregroundColor(.orange)
            }
            Text(result.description)
                .font(.body).foregroundColor(.primary)
                .lineLimit(expandedDesc ? nil : 6)
                .padding(10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            if result.description.count > 300 {
                Button(expandedDesc ? "收起" : "展开全部") { expandedDesc.toggle() }
                    .font(.caption).foregroundColor(.orange)
            }
        }
    }

    private func authorSection(_ author: AuthorInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("👤 作者").font(.subheadline).fontWeight(.semibold)
            Text(author.name).font(.headline)
            if !author.id.isEmpty {
                Text("ID: \(author.id)").font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private func statsRow(_ stats: ContentStats) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📊 数据").font(.subheadline).fontWeight(.semibold)
            HStack(spacing: 20) {
                if stats.plays > 0 { StatBadge(icon: "▶️", value: formatCount(stats.plays), label: "播放") }
                if stats.likes > 0 { StatBadge(icon: "❤️", value: formatCount(stats.likes), label: "点赞") }
                if stats.comments > 0 { StatBadge(icon: "💬", value: formatCount(stats.comments), label: "评论") }
                if stats.shares > 0 { StatBadge(icon: "🔄", value: formatCount(stats.shares), label: "分享") }
            }
        }
    }

    private func musicSection(_ music: MusicInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🎵 音乐").font(.subheadline).fontWeight(.semibold)
            Text("\(music.title)\(music.author.isEmpty ? "" : " - \(music.author)")")
                .font(.body).foregroundColor(.secondary)
        }
    }

    private var tagsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🏷️ 标签").font(.subheadline).fontWeight(.semibold)
            LazyVGrid(columns: [.init(.adaptive(minimum: 80))], spacing: 6) {
                ForEach(result.tags, id: \.self) { tag in
                    Text(tag).font(.caption).foregroundColor(.orange)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var mediaGridSection: some View {
        MediaGridView(
            images: result.images,
            videos: result.videos,
            onDownloadImage: { downloadVM.downloadImage($0) },
            onDownloadVideo: { downloadVM.downloadVideo($0) }
        )
    }

    private func formatCount(_ n: Int) -> String {
        n >= 10000 ? String(format: "%.1f万", Double(n)/10000) : "\(n)"
    }
}

struct StatBadge: View {
    let icon: String; let value: String; let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(icon).font(.caption)
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }
}
