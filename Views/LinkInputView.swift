import SwiftUI

struct LinkInputView: View {
    @Binding var inputURL: String
    var isLoading: Bool
    var onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("请粘贴或输入分享链接...", text: $inputURL)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .disabled(isLoading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)

                if !inputURL.isEmpty && !isLoading {
                    Button { inputURL = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary).font(.body)
                    }
                    .padding(.trailing, 8)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isLoading ? Color.clear : Color.orange.opacity(0.3), lineWidth: 1)
            )

            Button(action: onSubmit) {
                HStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(isLoading ? "解析中..." : "解析")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(inputURL.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                    ? Color.gray.opacity(0.3) : Color.orange)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(inputURL.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)

            // 支持平台
            HStack(spacing: 12) {
                ForEach([PlatformType.douyin, .kuaishou, .tiktok, .xiaohongshu], id: \.self) { p in
                    HStack(spacing: 3) {
                        Text(p.icon).font(.caption2)
                        Text(p.displayName).font(.caption2).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
            }
        }
    }
}
