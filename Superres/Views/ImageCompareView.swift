import SwiftUI

struct ImageCompareView: View {
    let beforeImage: NSImage
    let afterImage: NSImage

    @State private var sliderPosition = 0.0
    @State private var proxyWidth = 0.0

    var sliderPositionMin: CGFloat {
        return -proxyWidth / 2
    }

    var sliderPositionMax: CGFloat {
        return proxyWidth / 2
    }

    let sliderWidth = 40.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(nsImage: afterImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(6)

                Image(nsImage: beforeImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(6)
                    .frame(
                        width: proxy.frame(in: .global).width,
                        height: proxy.frame(in: .global).height
                    )
                    .clipShape(Rectangle().offset(x: sliderPosition + proxy.size.width / 2))

                SliderView(width: sliderWidth)
                    .offset(x: sliderPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                sliderPosition = calculateSliderPosition(value.location.x)
                            }
                    )
            }
            .frame(
                width: proxy.frame(in: .global).width,
                height: proxy.frame(in: .global).height
            )
            .onChange(of: proxy.size, initial: true) {
                // Update geometry info when size changes
                proxyWidth = proxy.frame(in: .global).width
                sliderPosition = calculateSliderPosition(sliderPosition)
            }
            .onAppear {
                let animation = Animation.easeInOut(duration: 1.25)
                sliderPosition = sliderPositionMin
                withAnimation(animation) {
                    sliderPosition = sliderPositionMax
                }
            }
        }
    }

    func calculateSliderPosition(_ proposedPosition: CGFloat) -> CGFloat {
        return min(max(proposedPosition, sliderPositionMin), sliderPositionMax)
    }
}

struct SliderView: View {
    @State private var isHovered = false

    var width: CGFloat

    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(Color("ButtonOutlineColor"))
                .cornerRadius(.greatestFiniteMagnitude)
                .frame(width: 3)

            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .shadow(color: Color("ShadowColor"), radius: 2, y: 3)
                    .overlay(
                        Circle()
                            .stroke(
                                Color("ButtonOutlineColor"), lineWidth: 1
                            )
                    )

                HStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.left.fill")
                    Image(systemName: "arrowtriangle.right.fill")
                }
                .foregroundColor(Color("FgColor"))
            }
            .frame(width: width)
            .onHover { hovering in
                self.isHovered = hovering
            }
        }
    }
}

#Preview("ImageCompareView") {
    ImageCompareView(beforeImage: NSImage(named: "Butterfly256x171")!, afterImage: NSImage(named: "Butterfly4096x2731")!)
}

#Preview("SliderView") {
    SliderView(width: 40)
        .background(Color("BgDimColor"))
}
