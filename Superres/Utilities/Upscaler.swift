import AppKit
import CoreGraphics
import CoreML

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

func upscaleImage(image: CGImage, model: RealESRGAN) throws -> CGImage {
    guard let pixelBuffer = image.pixelBuffer() else {
        throw UpscaleError.generic("Error converting CGImage to CVPixelBuffer.")
    }

    guard let prediction = try? model.prediction(input: pixelBuffer) else {
        throw UpscaleError.generic("Error making model prediction.")
    }

    guard let cgImageUpscaled = CGImage.create(pixelBuffer: prediction.activation_out) else {
        throw UpscaleError.generic("Error converting CVPixelBuffer to CGImage.")
    }

    return cgImageUpscaled
}

func roundUpToNextMultiple(_ n: Int, multipleOf: Int) -> Int {
    if n % multipleOf == 0 {
        return n
    } else {
        return ((n / multipleOf) + 1) * multipleOf
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
    let modelConfig = MLModelConfiguration()
    guard let model = try? RealESRGAN(configuration: modelConfig) else {
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

    for x in 0 ..< horizontalTiles {
        for y in 0 ..< verticalTiles {
            let tileRect = CGRect(x: x * tileSize, y: y * tileSize, width: tileSize, height: tileSize)
            guard let tile = paddedImage.cropping(to: tileRect) else {
                throw UpscaleError.generic("Error cropping image to tile.")
            }
            let tileUpscaled = try upscaleImage(image: tile, model: model)

            // The y-coordinate is calculated as if the origin if at the top-left
            context?.draw(tileUpscaled, in: CGRect(x: x * upscaledTileSize,
                                                   y: (verticalTiles - y - 1) * upscaledTileSize,
                                                   width: tileUpscaled.width,
                                                   height: tileUpscaled.height))
        }
    }

    // Combine processed tiles into a single image
    let upscaledPaddedImage = context?.makeImage()

    // Crop the padding to get the final upscaled image
    guard let upscaledImage = upscaledPaddedImage?.cropping(to: CGRect(x: 0,
                                                                       y: paddedUpscaledHeight - upscaledHeight,
                                                                       width: upscaledWidth,
                                                                       height: upscaledHeight)
    ) else {
        throw UpscaleError.generic("Error cropping padded upscaled image.")
    }

    return upscaledImage
}

func upscale(_ imageURL: URL) async throws -> Data? {
    guard let nsImage = NSImage(contentsOfFile: imageURL.path), let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        throw UpscaleError.generic("Error loading image: \(imageURL.path)")
    }
    let cgImageUpscaled = try tileUpscaleImage(image: cgImage)
    let upscaledNsImage = NSImage(cgImage: cgImageUpscaled, size: NSSize(width: cgImageUpscaled.width, height: cgImageUpscaled.height))

    return upscaledNsImage.tiffRepresentation
}
