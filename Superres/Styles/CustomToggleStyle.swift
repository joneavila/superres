import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    @Environment(\.isEnabled) var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top) {
            configuration.label
            Spacer()
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: .infinity)
                    .foregroundColor(configuration.isOn ? Color("AccentColor") : Color("ButtonColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: .infinity)
                            .stroke(configuration.isOn ? Color("AccentOutlineColor") : Color("ButtonOutlineColor"), lineWidth: 1)
                    )
                    .animation(.easeInOut, value: configuration.isOn)

                Circle()
                    .foregroundColor(Color("FgColor"))
                    .padding(.all, 1.5)
                    .animation(.easeInOut(duration: 0.25), value: configuration.isOn)
            }
            .frame(width: 35, height: 20)
            .padding(.top, 5)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

#Preview("Toggle (On)") {
    Toggle("Example toggle", isOn: .constant(true))
        .toggleStyle(CustomToggleStyle())
        .frame(width: 100, height: 80)
}

#Preview("Toggle (Off)") {
    Toggle("Example toggle", isOn: .constant(false))
        .toggleStyle(CustomToggleStyle())
        .frame(width: 100, height: 80)
}
