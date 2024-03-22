import SwiftUI
import UniformTypeIdentifiers

final class ContentViewModel: ObservableObject {
    @Published var imageStates: [ImageState] = [] {
        didSet {
            imagesNeedUpscaling = imageStates.contains { $0.upscaledImage == nil }
        }
    }

    @Published var outputFolderDisplayPath = ""
    @Published var alertIsPresented = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var automaticallySave = false
    @Published var showSuccessMessage = false
    @Published var isWorking = false
    @Published var imagesNeedUpscaling: Bool = false
    private var outputFolderUrl: URL?

    init() {
        // Set the default output folder to the Downloads directory
        outputFolderUrl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        if let outputFolderUrl = outputFolderUrl {
            outputFolderDisplayPath = urlToDisplayPath(outputFolderUrl)
        }
    }

    func urlToDisplayPath(_ url: URL) -> String {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        return url.path.replacingOccurrences(of: homeDirectory, with: "~")
    }

    func upscaleImages() {
        isWorking = true
        for index in imageStates.indices {
            if imageStates[index].upscaledImage != nil {
                continue
            }

            imageStates[index].isUpscaling = true
            Task {
                do {
                    let upscaledImageData = try await upscale(self.imageStates[index].originalImageUrl)
                    try await MainActor.run {
                        self.imageStates[index].isUpscaling = false
                        let upscaledImage = NSImage(data: upscaledImageData!)
                        self.imageStates[index].upscaledImage = upscaledImage

                        if self.automaticallySave, let outputFolderUrl = outputFolderUrl {
                            try self.imageStates[index].saveUpscaledImageToFolder(folderUrl: outputFolderUrl)
                            triggerSuccessMessage()
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.imageStates[index].isUpscaling = false
                        displayAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
        isWorking = false
    }

    private func displayAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        alertIsPresented = true
    }

    func triggerSuccessMessage() {
        DispatchQueue.main.async {
            self.showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showSuccessMessage = false
            }
        }
    }

    func handleDropOfImages(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    DispatchQueue.main.async {
                        guard let url = url else {
                            return
                        }

                        guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                              let fileUTType = UTType(typeIdentifier)
                        else {
                            self.displayAlert(title: "Uknown file type", message: url.path())
                            return
                        }

                        if !ImageState.supportedImageTypes.contains(fileUTType) {
                            self.displayAlert(title: "Unsupported image type", message: url.path())
                            return
                        }

                        guard let nsImage = NSImage(contentsOf: url) else {
                            self.displayAlert(title: "Unable to load image", message: url.path())
                            return
                        }

                        let droppedImage = ImageState(originalImage: nsImage, originalImageUrl: url)
                        self.imageStates.append(droppedImage)
                    }
                }
            }
        }
        return true
    }

    func selectImages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = ImageState.supportedImageTypes
        panel.allowsMultipleSelection = true
        if panel.runModal() != .OK {
            return
        }
        for url in panel.urls {
            if let nsImage = NSImage(contentsOfFile: url.path) {
                let image = ImageState(originalImage: nsImage, originalImageUrl: url)
                imageStates.append(image)
            }
        }
    }

    func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.prompt = "Select"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            outputFolderUrl = url
            outputFolderDisplayPath = urlToDisplayPath(url)
        }
    }
}
