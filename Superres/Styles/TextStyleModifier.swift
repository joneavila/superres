import SwiftUI

struct TextStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("Readex Pro", size: 13))
            .foregroundStyle(Color("FgColor"))
    }
}

extension View {
    func textStyle() -> some View {
        modifier(TextStyleModifier())
    }
}

#Preview {
    Text("Hello, world!")
        .textStyle()
}
