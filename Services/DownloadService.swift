import Foundation
import UIKit

/// 下载服务
final class DownloadService: NSObject, ObservableObject {
    @Published var tasks: [DownloadTask] = []
    @Published var downloadedFiles: [DownloadedFile] = []

    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    private let downloadDir: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("downloads")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: - 下载

    func download(_ url: String, type: MediaType, fileName: String? = nil) -> DownloadTask {
        let ext = URL(string: url)?.pathExtension ?? (type == .video ? "mp4" : "jpg")
        let name = fileName ?? "\(type.rawValue)_\(Int(Date().timeIntervalSince1970)).\(ext)"
        let task = DownloadTask(
            id: UUID().uuidString, url: url, type: type, fileName: name,
            progress: 0, status: .pending, createdAt: Date()
        )
        tasks.append(task)

        guard let requestURL = URL(string: url) else {
            markFailed(task.id, "无效URL"); return task
        }

        let downloadTask = session.downloadTask(with: requestURL)
        activeTasks[task.id] = downloadTask
        downloadTask.resume()

        updateStatus(task.id, .downloading)
        return task
    }

    func saveToGallery(_ taskId: String) {
        guard let t = tasks.first(where: { $0.id == taskId }),
              let path = t.localPath,
              let image = UIImage(contentsOfFile: path) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    func cancel(_ taskId: String) {
        activeTasks[taskId]?.cancel()
        updateStatus(taskId, .cancelled)
    }

    func refreshFiles() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: downloadDir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])
        else { return }
        downloadedFiles = files.compactMap { url in
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            else { return nil }
            return DownloadedFile(
                name: url.lastPathComponent,
                url: url,
                size: (attrs[.size] as? Int64) ?? 0,
                date: attrs[.modificationDate] as? Date
            )
        }.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    func deleteFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        refreshFiles()
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: downloadDir)
        try? FileManager.default.createDirectory(at: downloadDir, withIntermediateDirectories: true)
        tasks.removeAll()
        downloadedFiles.removeAll()
    }

    var totalSize: Int64 {
        downloadedFiles.reduce(0) { $0 + $1.size }
    }

    // MARK: - 内部

    private func updateStatus(_ id: String, _ status: DownloadStatus) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].status = status
        }
    }

    private func markFailed(_ id: String, _ msg: String) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].status = .failed
            tasks[i].errorMessage = msg
        }
    }

    private func completeTask(_ id: String, localPath: String) {
        if let i = tasks.firstIndex(where: { $0.id == id }) {
            tasks[i].status = .completed
            tasks[i].progress = 1.0
            tasks[i].localPath = localPath
            if let attrs = try? FileManager.default.attributesOfItem(atPath: localPath) {
                tasks[i].fileSize = (attrs[.size] as? Int64)
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let taskId = activeTasks.first(where: { $0.value == downloadTask })?.key,
              let t = tasks.first(where: { $0.id == taskId }) else { return }

        let dest = downloadDir.appendingPathComponent(t.fileName)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            completeTask(taskId, localPath: dest.path)
            refreshFiles()
        } catch {
            markFailed(taskId, "保存失败: \(error.localizedDescription)")
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {}

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let taskId = activeTasks.first(where: { $0.value == downloadTask })?.key,
              let i = tasks.firstIndex(where: { $0.id == taskId }),
              totalBytesExpectedToWrite > 0 else { return }
        tasks[i].progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskId = activeTasks.first(where: { $0.value == task })?.key else { return }
        if let err = error {
            markFailed(taskId, err.localizedDescription)
        }
    }
}

struct DownloadedFile: Identifiable {
    var id: String { url.absoluteString }
    let name: String
    let url: URL
    let size: Int64
    let date: Date?
}
