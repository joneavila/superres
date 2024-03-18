import SwiftUI

struct ValueTextStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Font.custom("Readex Pro", size: 13))
            .foregroundStyle(Color("FgColor"))
            .lineLimit(1)
            .truncationMode(.head)
            .padding(7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color("ButtonOutlineColor"), lineWidth: 1)
            )
    }
}

extension View {
    func valueTextStyle() -> some View {
        modifier(ValueTextStyleModifier())
    }
}

#Preview {
    Text("Hello, world!")
        .valueTextStyle()
        .frame(width: 200, height: 50)
        .background(Color("BgColor"))
}
