import AppKit
import UniformTypeIdentifiers

struct ImageState: Identifiable {
    let id = UUID()
    let originalImage: NSImage
    let originalImageUrl: URL
    let upscaledImageFilename: String
    var upscaledImage: NSImage?
    var isUpscaling: Bool = false

    init(originalImage: NSImage, originalImageUrl: URL) {
        self.originalImage = originalImage
        self.originalImageUrl = originalImageUrl

        // Create upscaled image filename by appending "-upscaled" to original filename.
        let filenameWithoutExtension = originalImageUrl.deletingPathExtension().lastPathComponent
        let fileExtension = originalImageUrl.pathExtension
        upscaledImageFilename = "\(filenameWithoutExtension)-upscaled.\(fileExtension)"
    }
}
