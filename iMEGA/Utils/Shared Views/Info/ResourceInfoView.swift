import DeviceCenter
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ResourceInfoView: View {
    @ObservedObject var viewModel: ResourceInfoViewModel
    
    private var backgroundColor: Color {
        isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : .clear
    }

    var body: some View {
        NavigationStackView {
            List {
                VStack(alignment: .center) {
                    Spacer()
                    Image(viewModel.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    Spacer()
                }
                .frame(height: 156)
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .listRowBackground(backgroundColor)

                Text(viewModel.title)
                    .font(.callout)
                    .bold()
                    .foregroundColor(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                    .padding(.vertical, 2)
                    .listRowBackground(backgroundColor)
                
                Section(header: Text(Strings.Localizable.details)) {
                    DetailRow(
                        title: Strings.Localizable.totalSize,
                        detail: viewModel.totalSize,
                        backgroundColor: backgroundColor
                    )
                    DetailRow(
                        title: Strings.Localizable.contains,
                        detail: viewModel.contentDescription,
                        backgroundColor: backgroundColor
                    )
                    if viewModel.formattedDate.isNotEmpty {
                        DetailRow(
                            title: Strings.Localizable.added,
                            detail: viewModel.formattedDate,
                            backgroundColor: backgroundColor
                        )
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle(Strings.Localizable.info)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.dismiss()
                    }, label: {
                        Text(Strings.Localizable.close)
                            .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                    })
                }
            }
            .designTokenBackground(isDesignTokenEnabled)
        }
    }
}

struct DetailRow: View {
    let title: String
    let detail: String
    let backgroundColor: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(
                    isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : UIColor.secondaryLabel.swiftUI
                )
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(
                    isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : UIColor.label.swiftUI
                )
        }
        .listRowBackground(backgroundColor)
    }
}

struct InfoView_Previews: PreviewProvider {
    static let infoModel = ResourceInfoModel(
        icon: "pc-mac",
        name: "MEGA Mac",
        counter: ResourceCounter(
            files: 15,
            folders: 12
        ),
        totalSize: UInt64(5000000),
        added: Date(),
        formatDateClosure: dateFormatter
    )
    
    static let dateFormatter: DateFormatterClosure = { date in
        DateFormatter.dateMediumTimeShort().localisedString(from: date)
    }
    
    static var previews: some View {
        ResourceInfoView(
            viewModel:
                ResourceInfoViewModel(
                    infoModel: infoModel,
                    router:
                        ResourceInfoViewRouter(
                            presenter: UIViewController(),
                            infoModel: infoModel
                        )
                )
        )
    }
}
