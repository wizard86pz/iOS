import SwiftUI

@MainActor
final class CancelSubscriptionStepsViewModel: ObservableObject {
    private let cancelSubscriptionStepsHelper: CancelSubscriptionStepsHelperProtocol
    @Published var shouldDismiss: Bool = false
    @Published var title: String = ""
    @Published var message: String = ""
    @Published var sections: [StepSection] = []
    
    init(helper: CancelSubscriptionStepsHelperProtocol) {
        self.cancelSubscriptionStepsHelper = helper
    }
    
    func setupStepList() {
        let cancellationData = cancelSubscriptionStepsHelper.loadCancellationData()
        title = cancellationData.title
        message = cancellationData.message
        sections = cancellationData.sections
    }
    
    func dismiss() {
        shouldDismiss = true
    }
}
