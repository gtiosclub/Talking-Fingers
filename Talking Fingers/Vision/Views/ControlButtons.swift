import SwiftUI

struct ControlButtons: View {

    @Binding var currentIndex: Int
    let total: Int

    var body: some View {

        HStack(spacing: 30) {

            // Check button
            CircleButton(icon: "checkmark") {
                currentIndex = max(0, currentIndex - 1)
            }

            // Eye button (current word)
            CircleButton(icon: "eye.fill", isHighlighted: true) {
            }

            // Lock buttons
            CircleButton(icon: "lock.fill") {}
            CircleButton(icon: "lock.fill") {}
        }
        .padding(.top, 10)
    }
}