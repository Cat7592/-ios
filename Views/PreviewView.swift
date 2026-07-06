import SwiftUI

struct PreviewView: View {
    let mediaURL: String
    let isVideo: Bool

    var body: some View {
        Group {
            if isVideo {
                VStack {
                    AsyncImage(url: URL(string: mediaURL)) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                }
                .background(.black)
            } else {
                AsyncImage(url: URL(string: mediaURL)) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFit()
                    } else {
                        ProgressView()
                    }
                }
                .background(.black)
            }
        }
        .navigationTitle(isVideo ? "视频预览" : "图片预览")
        .navigationBarTitleDisplayMode(.inline)
    }
}
