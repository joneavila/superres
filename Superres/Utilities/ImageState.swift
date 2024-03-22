import AppKit
import UniformTypeIdentifiers

enum ImageStateError: Error {
    case generic(String)
}

extension ImageStateError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .generic(message):
            return NSLocalizedString(message, comment: "")
        }
    }
}

struct ImageState: Identifiable {
    let id = UUID()
    let originalImage: NSImage
    let originalImageUrl: URL
    var upscaledImage: NSImage?
    var isUpscaling: Bool = false

    static let supportedImageTypes: [UTType] = [.bmp, .gif, .jpeg, .png, .tiff]

    func appendToFilename(url: URL, toAppend: String = "-upscaled") -> String {
        let filenameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension
        return "\(filenameWithoutExtension)\(toAppend).\(fileExtension)"
    }

    func saveUpscaledImageToFolder(folderUrl: URL) throws {
        let upscaledImageFilename = appendToFilename(url: originalImageUrl)
        let upscaledImageUrl = folderUrl.appendingPathComponent(upscaledImageFilename)
        try saveUpscaledImage(to: upscaledImageUrl)
    }

    func saveUpscaledImageToLocation() throws {
        let upscaledImageFilename = appendToFilename(url: originalImageUrl)

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = ImageState.supportedImageTypes
        savePanel.isExtensionHidden = false
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = upscaledImageFilename
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try saveUpscaledImage(to: url)
        }
    }

    func saveUpscaledImage(to url: URL) throws {
        guard let upscaledImage = upscaledImage else {
            return
        }

        guard let imageData = upscaledImage.tiffRepresentation, let bitmapRep = NSBitmapImageRep(data: imageData) else {
            throw ImageStateError.generic("Error creating bitmap representation.")
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
            throw ImageStateError.generic("Error formatting bitmap representation's image data.")
        }

        try newImageData.write(to: url)
    }
}
