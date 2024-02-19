import MEGADesignToken
import SwiftUI

struct RecurrenceOptionView: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(name)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundStyle(isDesignTokenEnabled ?
                                 TokenColors.Support.success.swiftUI : MEGAAppColor.Chat.chatMeetingFrequencySelectionTickMark.color)
                .font(.system(.footnote).bold())
                .opacity(isSelected ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}
