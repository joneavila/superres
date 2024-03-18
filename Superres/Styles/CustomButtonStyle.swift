import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled: Bool
    @State private var isHovered = false
    var isProminent = false
    var useMaxWidth = false

    private var fillColor: Color {
        switch (isProminent, isHovered) {
        case (false, false):
            return Color("ButtonColor")
        case (false, true):
            return Color("ButtonHoverColor")
        case (true, false):
            return Color("AccentColor")
        case (true, true):
            return Color("AccentHoverColor")
        }
    }

    private var strokeColor: Color {
        isProminent ? Color("AccentOutlineColor") : Color("ButtonOutlineColor")
    }

    private var foregroundColor: Color {
        isProminent ? Color("FgAccentColor") : Color("FgColor")
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: useMaxWidth ? .infinity : nil)
            .font(Font.custom("Readex Pro", size: 13))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(fillColor)
                    .stroke(strokeColor, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .shadow(color: Color("ShadowColor"), radius: 2, y: 3)
                    )
            )
            .foregroundStyle(foregroundColor)
            .opacity(isEnabled ? 1 : 0.5)
            .onHover { hovering in
                self.isHovered = hovering
            }
    }
}

#Preview("Button") {
    Button("Button") {
        print("Button pressed")
    }
    .buttonStyle(CustomButtonStyle())
}

#Preview("Button (Disabled)") {
    Button("Button") {
        print("Button pressed")
    }
    .buttonStyle(CustomButtonStyle())
    .disabled(true)
}

#Preview("Button (Prominent)") {
    Button("Button") {
        print("Button pressed")
    }
    .buttonStyle(CustomButtonStyle(isProminent: true))
}

#Preview("Button (Prominent, Disabled)") {
    Button("Button") {
        print("Button pressed")
    }
    .buttonStyle(CustomButtonStyle(isProminent: true))
    .disabled(true)
}
