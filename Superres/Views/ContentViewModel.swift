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

        for index in imageStates.indices where imageStates[index].upscaledImage == nil {
            self.imageStates[index].isUpscaling = true
        }

        Task {
            let saveImageSuccess = await withTaskGroup(of: Bool.self) { group -> Bool in
                for index in self.imageStates.indices where self.imageStates[index].upscaledImage == nil {
                    group.addTask {
                        do {
                            let upscaledImageData = try await upscale(self.imageStates[index].originalImageUrl)
                            try await MainActor.run {
                                self.imageStates[index].isUpscaling = false
                                self.imageStates[index].upscaledImage = NSImage(data: upscaledImageData!)
                                if self.automaticallySave, let outputFolderUrl = self.outputFolderUrl {
                                    try self.imageStates[index].saveUpscaledImageToFolder(folderUrl: outputFolderUrl)
                                }
                            }
                            return true // Image was saved.

                        } catch {
                            await MainActor.run {
                                self.imageStates[index].isUpscaling = false
                                self.displayAlert(title: "Error", message: error.localizedDescription)
                            }
                        }
                        return false // Image was not saved.
                    }
                }
                return await group.contains(true)
            }

            if saveImageSuccess {
                await MainActor.run {
                    triggerSuccessMessage()
                }
            }

            await MainActor.run {
                self.isWorking = false
            }
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
    
    func handleDropOfImages(providers: [NSItemProvider]) -> Bool {
        var errorMessages = [String]()

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
                            errorMessages.append("Uknown file type: \(url.path())")
                            return
                        }
                        
                        if !ImageState.supportedImageTypes.contains(fileUTType) {
                            errorMessages.append("Unsupported image type: \(url.path())")
                            return
                        }
                        
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
            if !errorMessages.isEmpty {
                let message = errorMessages.joined(separator: "\n")
                self.displayAlert(title: "Error", message: message)
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
