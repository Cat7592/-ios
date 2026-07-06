import Foundation
import Combine

@MainActor
final class ParserViewModel: ObservableObject {
    @Published var inputURL: String = ""
    @Published var isLoading: Bool = false
    @Published var result: ParseResult?
    @Published var errorMessage: String?

    private let service = ParserService()

    func parse() {
        guard !inputURL.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "请输入分享链接"
            return
        }
        isLoading = true; result = nil; errorMessage = nil
        Task {
            do {
                let r = try await service.parse(inputURL)
                result = r; isLoading = false
            } catch {
                errorMessage = error.localizedDescription; isLoading = false
            }
        }
    }

    func parseURL(_ url: String) {
        inputURL = url; parse()
    }

    func reset() {
        inputURL = ""; result = nil; errorMessage = nil; isLoading = false
    }
}
