import SwiftUI

struct HomeView: View {
    @EnvironmentObject var parserVM: ParserViewModel
    @EnvironmentObject var downloadVM: DownloadViewModel
    @State private var showParser = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部
                    headerSection

                    // 输入区域
                    LinkInputView(inputURL: $parserVM.inputURL, isLoading: parserVM.isLoading) {
                        parserVM.parse()
                    }
                    .padding(.horizontal)

                    if let err = parserVM.errorMessage {
                        Text(err)
                            .font(.caption).foregroundColor(.red)
                            .padding(.horizontal).padding(.top, 4)
                    }

                    // 统计卡片
                    statsSection
                        .padding(.horizontal).padding(.top, 20)

                    // 使用说明
                    tipsSection
                        .padding(.top, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("猫老大解析助手")
            .navigationDestination(isPresented: $showParser) {
                if let result = parserVM.result {
                    ParserResultView(result: result)
                }
            }
            .onChange(of: parserVM.result) { _, newVal in
                if newVal != nil { showParser = true }
            }
            .onAppear { downloadVM.refresh() }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("🐱").font(.system(size: 48))
            Text("猫老大解析助手").font(.title2).fontWeight(.bold).foregroundColor(.orange)
            Text("抖音 · 快手 · TikTok · 小红书")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(icon: "📥", value: "\(downloadVM.files.count)", label: "已下载")
            StatCard(icon: "💾", value: formatBytes(downloadVM.totalSize), label: "存储")
            StatCard(icon: "🔗", value: "4", label: "支持平台")
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用说明").font(.headline).padding(.horizontal)
            TipRow(step: "1️⃣", title: "复制分享链接", desc: "在抖音/快手/TikTok/小红书 App 中点击分享复制链接")
            TipRow(step: "2️⃣", title: "粘贴到输入框", desc: "将链接粘贴到上方输入框，或手动输入")
            TipRow(step: "3️⃣", title: "解析并下载", desc: "解析完成后选择图片或视频下载保存")
        }
    }

    private func formatBytes(_ b: Int64) -> String {
        if b < 1024 { return "\(b) B" }
        let kb = Double(b) / 1024
        if kb < 1024 { return String(format: "%.0f KB", kb) }
        return String(format: "%.1f MB", kb / 1024)
    }
}

struct StatCard: View {
    let icon: String; let value: String; let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(icon).font(.title3)
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TipRow: View {
    let step: String; let title: String; let desc: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Text(desc).font(.caption).foregroundColor(.secondary).lineLimit(2)
            }
        }
        .padding(.horizontal)
    }
}
