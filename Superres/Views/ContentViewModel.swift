import SwiftUI

final class ContentViewModel: ObservableObject {
    @Published var upscaledImage: NSImage? = nil
    @Published var originalImage: NSImage? = nil
    @Published var originalImageUrl: URL?
    @Published var outputFolderUrl: URL?
    @Published var outputFolderDisplayPath = ""
    @Published var isUpscaling = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var automaticallySave = false
    @Published var showSuccessMessage = false

    init() {
        outputFolderUrl = getDownloadsFolder()
        if let outputFolderUrl = outputFolderUrl {
            outputFolderDisplayPath = urlToDisplayPath(url: outputFolderUrl)
        }
    }

    func getDownloadsFolder() -> URL? {
        if let downloadsUrl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            return downloadsUrl
        }
        return nil
    }

    func urlToDisplayPath(url: URL) -> String {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        return url.path.replacingOccurrences(of: homeDirectory, with: "~")
    }

    func upscaleImage() {
        guard let originalImageUrl = originalImageUrl else {
            return
        }
        upscaledImage = nil
        isUpscaling = true
        Task {
            do {
                let upscaledImageData = try await upscale(originalImageUrl)
                await MainActor.run {
                    self.isUpscaling = false
                    if let upscaledImageData = upscaledImageData {
                        self.upscaledImage = NSImage(data: upscaledImageData)
                    }
                    if self.automaticallySave {
                        self.saveUpscaledImageToOutputFolder()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isUpscaling = false
                    showError(error)
                }
            }
        }
    }

    private func showError(_ error: Error) {
        alertMessage = error.localizedDescription
        showAlert = true
    }

    func saveUpscaledImageToOutputFolder() {
        guard let originalImageUrl = originalImageUrl, let outputFolderUrl = outputFolderUrl else {
            return
        }
        Task {
            // Create the upscaled image URL from `originalImageUrl` and `outputFolderUrl`
            let upscaledImageFilename = appendToFilename(originalUrl: originalImageUrl)
            let upscaledImageUrl = outputFolderUrl.appendingPathComponent(upscaledImageFilename)

            do {
                try saveUpscaledImage(to: upscaledImageUrl)
                triggerSuccessMessage()
            } catch {
                showError(error)
            }
        }
    }

    func triggerSuccessMessage() {
        DispatchQueue.main.async {
            self.showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showSuccessMessage = false
            }
        }
    }

    func saveUpscaledImageToLocation() {
        var defaultFilename = ""

        if let originalImageUrl = originalImageUrl {
            let upscaledImageFilename = appendToFilename(originalUrl: originalImageUrl)
            defaultFilename = upscaledImageFilename
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.isExtensionHidden = false
        savePanel.canCreateDirectories = true
        savePanel.message = "Save upscaled image"
        savePanel.nameFieldStringValue = defaultFilename
        if savePanel.runModal() != .OK {
            return
        }
        if let url = savePanel.url {
            do {
                try saveUpscaledImage(to: url)
            } catch {
                showError(error)
            }
        }
    }

    func saveUpscaledImage(to url: URL) throws {
        guard let upscaledImage = upscaledImage, let imageData = upscaledImage.tiffRepresentation else {
            return
        }

        // Determine the file extension from the URL
        let fileExtension = url.pathExtension.lowercased()

        guard let bitmapImage = NSBitmapImageRep(data: imageData) else {
            throw UpscaleError.generic("Error reading image data.")
        }

        var data: Data?
        switch fileExtension {
        case "jpg", "jpeg":
            data = bitmapImage.representation(using: .jpeg, properties: [:])
        case "png":
            data = bitmapImage.representation(using: .png, properties: [:])
        default:
            throw UpscaleError.generic("Unsupported file format: \(fileExtension)")
        }

        guard let data = data else {
            throw UpscaleError.generic("Error reading image data as \(fileExtension) format.")
        }

        do {
            try data.write(to: url)
        } catch {
            throw UpscaleError.generic("Error saving image to \(url.path): \(error)")
        }
    }

    func handleDropOfImage(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: URL.self) }) else {
            return false
        }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            DispatchQueue.main.async {
                guard let fileUrl = url, fileUrl.isFileURL else {
                    return
                }
                let fileExtension = fileUrl.pathExtension.lowercased()

                guard fileExtension == "png" || fileExtension == "jpg" || fileExtension == "jpeg" else {
                    self.alertMessage = "Unsupported file type."
                    self.showAlert = true
                    return
                }

                guard let nsImage = NSImage(contentsOf: fileUrl) else {
                    return
                }
                self.originalImage = nsImage
                self.originalImageUrl = fileUrl
            }
        }
        upscaledImage = nil
        return true
    }

    func selectImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg]
        if panel.runModal() != .OK {
            return
        }
        if let imageUrl = panel.url, let nsImage = NSImage(contentsOfFile: imageUrl.path) {
            originalImageUrl = imageUrl
            originalImage = nsImage
            upscaledImage = nil
        }
    }

    func selectOutputFolder() {
        let panel = NSOpenPanel()
        panel.message = "Select output folder"
        panel.prompt = "Select"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            outputFolderUrl = url
        }
    }

    func appendToFilename(originalUrl: URL, toAppend: String = "-upscaled") -> String {
        let filenameWithoutExtension = originalUrl.deletingPathExtension().lastPathComponent
        let fileExtension = originalUrl.pathExtension
        let newFilename = "\(filenameWithoutExtension)\(toAppend).\(fileExtension)"
        return newFilename
    }
}
