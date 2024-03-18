import SwiftUI

struct HeadingTextStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("Readex Pro", size: 16))
            .bold()
            .foregroundStyle(Color("FgColor"))
    }
}

extension View {
    func headingTextStyle() -> some View {
        modifier(HeadingTextStyleModifier())
    }
}

#Preview {
    Text("Hello, world!")
        .headingTextStyle()
}
