import AppKit
import Vision

enum UpscaleError: Error {
    case generic(String)
}

extension UpscaleError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .generic(message):
            return NSLocalizedString(message, comment: "")
        }
    }
}

func roundUpToNextMultiple(_ number: Int, multipleOf: Int) -> Int {
    if number % multipleOf == 0 {
        return number
    } else {
        return ((number / multipleOf) + 1) * multipleOf
    }
}

func padImageToTile(_ image: CGImage, tileSize: Int) throws -> CGImage {
    let originalWidth = image.width
    let originalHeight = image.height

    let paddedWidth = roundUpToNextMultiple(originalWidth, multipleOf: tileSize)
    let paddedHeight = roundUpToNextMultiple(originalHeight, multipleOf: tileSize)

    // Create a new context with desired dimensions
    guard let context = CGContext(data: nil,
                                  width: paddedWidth,
                                  height: paddedHeight,
                                  bitsPerComponent: image.bitsPerComponent,
                                  bytesPerRow: 0, // auto calculation
                                  space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else {
        throw UpscaleError.generic("Error creating context for padded image.")
    }

    // Draw the original image at the origin, leaving any padding on the top and right
    context.draw(image, in: CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight))

    // Extract the new image from the context
    guard let paddedImage = context.makeImage() else {
        throw UpscaleError.generic("Error creating padded image.")
    }
    return paddedImage
}

func tileUpscaleImage(image: CGImage) throws -> CGImage {
    guard let visionModel = try? VNCoreMLModel(for: RealESRGAN(configuration: MLModelConfiguration()).model) else {
        throw UpscaleError.generic("Error loading model.")
    }

    let tileSize = 512
    let scaleFactor = 4

    let upscaledTileSize = tileSize * scaleFactor

    let originalWidth = image.width
    let originalHeight = image.height

    let upscaledWidth = originalWidth * scaleFactor
    let upscaledHeight = originalHeight * scaleFactor

    let paddedImage = try padImageToTile(image, tileSize: tileSize)

    let paddedWidth = paddedImage.width
    let paddedHeight = paddedImage.height

    let paddedUpscaledWidth = paddedWidth * scaleFactor
    let paddedUpscaledHeight = paddedHeight * scaleFactor

    let horizontalTiles = paddedWidth / tileSize
    let verticalTiles = paddedHeight / tileSize

    // Create a context for the upscaled padded image
    let context = CGContext(data: nil,
                            width: paddedUpscaledWidth,
                            height: paddedUpscaledHeight,
                            bitsPerComponent: image.bitsPerComponent,
                            bytesPerRow: 0,
                            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

    for horizontalTile in 0 ..< horizontalTiles {
        for verticalTile in 0 ..< verticalTiles {
            let request = VNCoreMLRequest(model: visionModel) { request, _ in
                if let observations = request.results as? [VNPixelBufferObservation] {
                    if let pixelBuffer = observations.first?.pixelBuffer {
                        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
                        if let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) {
                            // Draw the upscaled tile into the context
                            context?.draw(cgImage, in: CGRect(x: horizontalTile * upscaledTileSize,
                                                              y: verticalTile * upscaledTileSize,
                                                              width: cgImage.width,
                                                              height: cgImage.height))
                        }
                    }
                }
            }

            // Normalize the region of interest to the dimensions of the image
            let regionX = Double(horizontalTile * tileSize) / Double(paddedWidth)
            let regionY = Double(verticalTile * tileSize) / Double(paddedHeight)
            let regionWidth = Double(tileSize) / Double(paddedWidth)
            let regionHeight = Double(tileSize) / Double(paddedHeight)
            request.regionOfInterest = CGRect(x: regionX, y: regionY, width: regionWidth, height: regionHeight)

            let handler = VNImageRequestHandler(cgImage: paddedImage)
            try? handler.perform([request])
        }
    }

    let upscaledPaddedImage = context?.makeImage()

    // Crop the padded upscaled image to get the final upscaled image
    guard let upscaledImage = upscaledPaddedImage?.cropping(to: CGRect(x: 0,
                                                                       y: paddedUpscaledHeight - upscaledHeight,
                                                                       width: upscaledWidth,
                                                                       height: upscaledHeight))
    else {
        throw UpscaleError.generic("Error cropping padded upscaled image.")
    }

    return upscaledImage
}

func upscale(_ imageURL: URL) async throws -> Data? {
    guard let nsImage = NSImage(contentsOfFile: imageURL.path),
          let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
        throw UpscaleError.generic("Error loading image: \(imageURL.path)")
    }
    let cgImageUpscaled = try tileUpscaleImage(image: cgImage)
    let upscaledNsImage = NSImage(
        cgImage: cgImageUpscaled,
        size: NSSize(width: cgImageUpscaled.width, height: cgImageUpscaled.height)
    )

    return upscaledNsImage.tiffRepresentation
}
