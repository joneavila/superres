import SwiftUI

struct SubheadingTextStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("Readex Pro", size: 13))
            .bold()
            .foregroundStyle(Color("FgColor"))
    }
}

extension View {
    func subheadingTextStyle() -> some View {
        modifier(SubheadingTextStyleModifier())
    }
}

#Preview {
    Text("Hello, world!")
        .subheadingTextStyle()
}
