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
    @Published var isUpscaling = false
    @Published var imagesNeedUpscaling: Bool = false
    private var outputFolderUrl: URL
    private let supportedImageTypes: [UTType] = [.bmp, .gif, .jpeg, .png, .tiff]

    init() {
        // Set the default output folder to the Downloads directory
        outputFolderUrl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        outputFolderDisplayPath = urlToDisplayPath(outputFolderUrl)
    }

    func urlToDisplayPath(_ url: URL) -> String {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        return url.path.replacingOccurrences(of: homeDirectory, with: "~")
    }

    /// Upscale images asynchronously.
    @MainActor
    func upscaleImages() async {
        isUpscaling = true

        var taskResults: [(String?, Bool)] = []

        // Create a task group to execute upscaling tasks concurrently. The task result is a tuple of an optional string (an error description if upscaling fails) and a boolean (whether the upscaled image was automatically saved).
        await withTaskGroup(of: (String?, Bool).self) { group in

            // Process images that have not been upscaled.
            for index in imageStates.indices where imageStates[index].upscaledImage == nil {
                group.addTask {
                    do {
                        await MainActor.run {
                            self.imageStates[index].isUpscaling = true
                        }

                        let upscaledImageData = try await upscale(self.imageStates[index].originalImageUrl)

                        await MainActor.run {
                            self.imageStates[index].upscaledImage = NSImage(data: upscaledImageData!)
                            self.imageStates[index].isUpscaling = false
                        }

                        if self.automaticallySave {
                            let upscaledImageUrl = self.outputFolderUrl.appendingPathComponent(self.imageStates[index].upscaledImageFilename)
                            let upscaledImage = NSImage(data: upscaledImageData!)
                            try self.saveImage(nsImage: upscaledImage!, to: upscaledImageUrl)
                            return (nil, true)
                        }

                        return (nil, false)
                    } catch {
                        await MainActor.run {
                            self.imageStates[index].isUpscaling = false
                        }
                        return ("Error upscaling image \(self.imageStates[index].originalImageUrl): \(error.localizedDescription)", false)
                    }
                }
            }

            // Collect results once all tasks have completed.
            for await result in group {
                taskResults.append(result)
            }
        }

        isUpscaling = false

        // Display any error messages in a single alert.
        let errorMessages = taskResults.compactMap { $0.0 }
        if !errorMessages.isEmpty {
            let message = errorMessages.joined(separator: "\n")
            displayAlert(title: "Error", message: message)
        }

        // Display success message if any upscaled images where saved.
        let imageWasSaved = taskResults.contains { $0.1 }
        if imageWasSaved {
            triggerSuccessMessage()
        }
    }

    private func displayAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        alertIsPresented = true
    }

    func triggerSuccessMessage() {
        let messageDuration = 3.0
        DispatchQueue.main.async {
            self.showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + messageDuration) {
                self.showSuccessMessage = false
            }
        }
    }

    /// Handles the drop of images onto the application.
    /// - Parameter providers: An array of `NSItemProvider` objects representing the dropped items.
    /// - Returns: `true` if the drop was handled successfully, `false` otherwise.
    func handleDropOfImages(providers: [NSItemProvider]) -> Bool {
        var errorMessages = [String]()

        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in

                    DispatchQueue.main.async {
                        if let error = error {
                            errorMessages.append("Error loading URL: \(error.localizedDescription)")
                            return
                        }

                        guard let url = url else {
                            return
                        }

                        // Get the UTType from the URL.
                        guard let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                              let fileUTType = UTType(typeIdentifier)
                        else {
                            errorMessages.append("Uknown file type: \(url.path())")
                            return
                        }

                        // Check if the file type is supported.
                        if !self.supportedImageTypes.contains(fileUTType) {
                            errorMessages.append("Unsupported file type: \(url.path())")
                            return
                        }

                        // Load the image from the URL.
                        guard let nsImage = NSImage(contentsOf: url) else {
                            errorMessages.append("Unable to load image: \(url.path())")
                            return
                        }

                        let droppedImage = ImageState(originalImage: nsImage, originalImageUrl: url)
                        self.imageStates.append(droppedImage)
                    }
                }
            }
        }

        DispatchQueue.main.async {
            // Display any error messages in a single alert.
            if !errorMessages.isEmpty {
                let title = "Error loading image\(errorMessages.count > 1 ? "s" : "")"
                let message = errorMessages.joined(separator: "\n")
                self.displayAlert(title: title, message: message)
            }
        }

        return true
    }

    func selectImages() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = supportedImageTypes
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

    func saveUpscaledImageToLocation(imageState: ImageState) {
        guard let upscaledImage = imageState.upscaledImage else {
            return
        }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = supportedImageTypes
        savePanel.isExtensionHidden = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = imageState.upscaledImageFilename
        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return
        }
        do {
            try saveImage(nsImage: upscaledImage, to: url)
        } catch {
            displayAlert(title: "Error", message: "Error saving image: \(error.localizedDescription)")
        }
    }

    private func saveImage(nsImage: NSImage, to url: URL) throws {
        guard let imageData = nsImage.tiffRepresentation else {
            throw ImageDataError.generic("Error obtaining TIFF data.")
        }

        guard let bitmapRep = NSBitmapImageRep(data: imageData) else {
            throw ImageDataError.generic("Error obtaining bitmap representation.")
        }

        let pathExtension = url.pathExtension.lowercased()
        let bitmapType: NSBitmapImageRep.FileType = {
            switch pathExtension {
            case "bmp", "dib":
                return .bmp
            case "gif":
                return .gif
            case "jpg", "jpeg", "jpe", "jif", "jfif", "jfi":
                return .jpeg
            case "png":
                return .png
            case "tiff", "tif":
                return .tiff
            default:
                return .png
            }
        }()

        guard let newImageData = bitmapRep.representation(using: bitmapType, properties: [:]) else {
            throw ImageDataError.generic("Error formatting bitmap representation's image data.")
        }

        try newImageData.write(to: url)
    }
}

enum ImageDataError: Error {
    case generic(String)
}

extension ImageDataError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .generic(message):
            return NSLocalizedString(message, comment: "")
        }
    }
}
