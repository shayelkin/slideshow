import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var images: [URL] = []
    @State private var currentIndex = 0
    @State private var folderSelected = false
    @FocusState private var hasFocus

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if folderSelected && !images.isEmpty {
                AsyncImage(url: images[currentIndex]) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Text("Failed to load image")
                            .foregroundColor(.white)
                            .font(.title)
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if !folderSelected {
                Text("Press ↵ to open a folder")
                    .foregroundColor(.white)
                    .font(.title)
            } else {
                Text("No images found in folder")
                    .foregroundColor(.white)
                    .font(.title)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable()
        .focused($hasFocus)
        .onKeyPress { press in
            handleKeyPress(press)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.hasFocus = true
                if !folderSelected {
                    selectFolder()
                }
            }
        }
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .delete:
            fallthrough
        case .leftArrow:
            if currentIndex > 0 {
                currentIndex -= 1
            } else {
                currentIndex = images.count - 1
            }
            return .handled
        case .space:
            fallthrough
        case .rightArrow:
            if currentIndex < images.count - 1 {
                currentIndex += 1
            } else {
                currentIndex = 0
            }
            return .handled
        case .escape:
            NSApplication.shared.terminate(nil)
            return .handled
        case .return:
            if !folderSelected || press.modifiers.contains(.command) {
                selectFolder()
            }
            return .handled
        default:
            return .ignored
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadImages(from: url)
            folderSelected = true
        }
    }

    private func loadImages(from folder: URL) {
        let fileManager = FileManager.default
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: [.nameKey],
                options: [.skipsHiddenFiles]
            )

            images = contents
                .filter { url in
                    imageExtensions.contains(url.pathExtension.lowercased())
                }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

            currentIndex = 0
        } catch {
            print("Error loading folder: \(error)")
            images = []
        }
    }
}

#Preview {
    ContentView()
}
