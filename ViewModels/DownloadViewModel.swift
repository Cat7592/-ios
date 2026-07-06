import Foundation

@MainActor
final class DownloadViewModel: ObservableObject {
    @Published var downloadService = DownloadService()

    func download(url: String, type: MediaType, name: String? = nil) -> DownloadTask {
        downloadService.download(url, type: type, fileName: name)
    }

    func downloadImage(_ url: String) -> DownloadTask {
        downloadService.download(url, type: .image)
    }

    func downloadVideo(_ url: String, fileName: String? = nil) -> DownloadTask {
        downloadService.download(url, type: .video, fileName: fileName)
    }

    func cancel(_ id: String) { downloadService.cancel(id) }
    func delete(_ url: URL) { downloadService.deleteFile(url) }
    func clearAll() { downloadService.clearAll() }
    func refresh() { downloadService.refreshFiles() }

    var tasks: [DownloadTask] { downloadService.tasks }
    var files: [DownloadedFile] { downloadService.downloadedFiles }
    var totalSize: Int64 { downloadService.totalSize }
}
