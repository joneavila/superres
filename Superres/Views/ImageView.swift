import SwiftUI

/// Displays an image. Responds to `imageState` by:
/// - Displaying the original image if the upscaled image is not available.
/// - Darkening the image and displaying a spinner if the image is being upscaled.
/// - Displaying the upscaled image if it is available, with a checkmark overlay.
struct ImageView: View {
    var imageState: ImageState

    @State private var isHovered = false

    var body: some View {
        ZStack {
            Image(nsImage: imageState.upscaledImage ?? imageState.originalImage)
                .resizable()
                .scaledToFit()
                .brightness(imageState.isUpscaling ? -0.2 : 0)
                .animation(.easeInOut(duration: 0.4), value: imageState.isUpscaling)
                .overlay(
                    Image(systemName: "checkmark.circle.fill")
                        .padding([.top, .trailing], 4)
                        .opacity(imageState.upscaledImage == nil ? 0 : 1),
                    alignment: .topTrailing
                )
                .cornerRadius(6)

            SpinnerView()
                .opacity(imageState.isUpscaling ? 1 : 0)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct SpinnerView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .frame(width: 50, height: 50)
            ProgressView()
        }
    }
}

#Preview("ImageView (Before Upscale)") {
    ImageView(
        imageState: ImageState(
            originalImage: NSImage(named: "Butterfly256x171")!,
            originalImageUrl: URL(string: "empty")!
        )
    )
}

#Preview("ImageView (During Upscale)") {
    var imageState = ImageState(
        originalImage: NSImage(named: "Butterfly256x171")!,
        originalImageUrl: URL(string: "empty")!
    )
    imageState.isUpscaling = true
    return ImageView(
        imageState: imageState
    )
}

#Preview("ImageView (After Upscale)") {
    var imageState = ImageState(
        originalImage: NSImage(named: "Butterfly256x171")!,
        originalImageUrl: URL(string: "image")!
    )
    imageState.upscaledImage = NSImage(named: "Butterfly4096x2731")!
    return ImageView(imageState: imageState)
}
