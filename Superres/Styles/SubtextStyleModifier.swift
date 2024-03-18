import SwiftUI

struct SubtextStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("Readex Pro", size: 13))
            .foregroundStyle(Color("FgSecondaryColor"))
    }
}

extension View {
    func subtextStyle() -> some View {
        modifier(SubtextStyleModifier())
    }
}

#Preview {
    Text("Hello, world!")
        .subtextStyle()
}
