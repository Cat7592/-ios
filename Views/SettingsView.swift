import SwiftUI

struct SettingsView: View {
    @State private var videoQuality: VideoQuality = .high
    @State private var autoSave: Bool = true
    @State private var clipboardDetect: Bool = true
    @State private var maxConcurrent: Int = 3
    @EnvironmentObject var downloadVM: DownloadViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("视频下载画质") {
                    Picker("画质", selection: $videoQuality) {
                        ForEach(VideoQuality.allCases, id: \.self) { q in
                            Text(q.label).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("功能设置") {
                    Toggle("自动保存到相册", isOn: $autoSave)
                    Toggle("剪贴板自动检测", isOn: $clipboardDetect)
                }

                Section("最大同时下载数") {
                    Picker("并发数", selection: $maxConcurrent) {
                        Text("1").tag(1); Text("2").tag(2)
                        Text("3").tag(3); Text("5").tag(5)
                    }
                    .pickerStyle(.segmented)
                }

                Section("存储管理") {
                    HStack {
                        Text("已下载文件")
                        Spacer()
                        Text(formatBytes(downloadVM.totalSize)).foregroundColor(.secondary)
                    }
                    Button("清理缓存", role: .destructive) { downloadVM.clearAll() }
                }

                Section("关于") {
                    LabeledContent("应用名称", value: "猫老大解析助手")
                    LabeledContent("版本", value: "1.0.0")
                    LabeledContent("支持平台", value: "抖音·快手·TikTok·小红书")
                    LabeledContent("安装方式", value: "TrollStore 自签")
                }

                Section {
                    Text("本应用不会收集或上传任何用户个人信息。所有数据仅保存在您设备本地。下载任务和文件完全由您控制。")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
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
