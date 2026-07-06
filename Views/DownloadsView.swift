import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var downloadVM: DownloadViewModel

    var body: some View {
        NavigationStack {
            Group {
                if downloadVM.files.isEmpty {
                    VStack(spacing: 12) {
                        Text("📭").font(.system(size: 48))
                        Text("暂无下载文件").font(.headline).foregroundColor(.secondary)
                        Text("解析并下载内容后，文件将显示在这里")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(downloadVM.files) { file in
                            HStack(spacing: 12) {
                                Image(systemName: file.name.hasSuffix(".mp4") ? "film" : "photo")
                                    .font(.title3).foregroundColor(.orange)
                                    .frame(width: 36, height: 36)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.name).font(.subheadline).lineLimit(1)
                                    Text(formatBytes(file.size)).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { downloadVM.delete(file.url) }
                                    label: { Image(systemName: "trash") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("下载管理")
            .toolbar {
                if !downloadVM.files.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("清空") { downloadVM.clearAll() }
                            .font(.subheadline).foregroundColor(.red)
                    }
                }
            }
            .onAppear { downloadVM.refresh() }
        }
    }

    private func formatBytes(_ b: Int64) -> String {
        if b < 1024 { return "\(b) B" }
        let kb = Double(b) / 1024
        if kb < 1024 { return String(format: "%.0f KB", kb) }
        return String(format: "%.1f MB", kb / 1024)
    }
}
