import SwiftUI

struct ImageView: View {
    var imageState: ImageState

    @State private var isHovered = false

    var body: some View {
        ZStack {
            Image(nsImage: imageState.upscaledImage ?? imageState.originalImage)
                .resizable()
                .scaledToFit()
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

#Preview("ImageView (Before Upscale)") {
    ImageView(
        imageState: ImageState(
            originalImage: NSImage(named: "Butterfly256x171")!,
            originalImageUrl: URL(string: "image")!
        )
    )
}

// #Preview("ImageView (After Upscale)") {
//    ImageView(
//        imageState: ImageState(
//            originalImage: NSImage(named: "Butterfly256x171")!,
//            originalImageUrl: URL(string: "image")!,
//            upscaledImage: NSImage(named: "Butterfly4096x2731")!)
//    )
// }
