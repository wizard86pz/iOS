import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public final class AccountRepository: NSObject, AccountRepositoryProtocol {    
    private let sdk: MEGASdk
    private let currentUserSource: CurrentUserSource
    private let myChatFilesFolderNodeAccess: NodeAccessProtocol
    private let backupsRootFolderNodeAccess: NodeAccessProtocol
    private let accountUpdatesProvider: any AccountUpdatesProviderProtocol
    
    private let fullStorageLimit = 1.0
    private let almostFullStorageLimit = 0.9
    
    public init(
        sdk: MEGASdk = MEGASdk.sharedSdk,
        currentUserSource: CurrentUserSource = .shared,
        myChatFilesFolderNodeAccess: NodeAccessProtocol,
        backupsRootFolderNodeAccess: NodeAccessProtocol,
        accountUpdatesProvider: some AccountUpdatesProviderProtocol
    ) {
        self.sdk = sdk
        self.currentUserSource = currentUserSource
        self.myChatFilesFolderNodeAccess = myChatFilesFolderNodeAccess
        self.backupsRootFolderNodeAccess = backupsRootFolderNodeAccess
        self.accountUpdatesProvider = accountUpdatesProvider
    }

    // MARK: - User authentication status and identifiers
    public var currentUserHandle: HandleEntity? {
        currentUserSource.currentUserHandle
    }
    
    public var isGuest: Bool {
        currentUserSource.isGuest
    }
    
    public var isNewAccount: Bool {
        sdk.isNewAccount
    }
    
    public var myEmail: String? {
        sdk.myEmail
    }

    // MARK: - Account characteristics
    public var accountCreationDate: Date? {
        sdk.accountCreationDate
    }
    
    public var currentAccountDetails: AccountDetailsEntity? {
        currentUserSource.accountDetails
    }
    
    public var bandwidthOverquotaDelay: Int64 {
        sdk.bandwidthOverquotaDelay
    }
    
    public var isMasterBusinessAccount: Bool {
        sdk.isMasterBusinessAccount
    }
    
    public var isSMSAllowed: Bool {
        sdk.smsAllowedState() == .optInAndUnblock
    }
    
    public var isAchievementsEnabled: Bool {
        sdk.isAchievementsEnabled
    }
    
    public func currentAccountPlan() async -> PlanEntity? {
        let availablePlans = await availablePlans()
        
        return availablePlans.first(where: {
            $0.type == currentAccountDetails?.proLevel && $0.subscriptionCycle == currentAccountDetails?.subscriptionCycle
        })
    }
    
    public var currentStorageStatus: StorageStatusEntity {
        guard let details = currentAccountDetails else { return .noStorageProblems }

        let percentageUsed = Double(details.storageUsed) / Double(details.storageMax)

        return percentageUsed >= fullStorageLimit ? .full :
               percentageUsed >= almostFullStorageLimit ? .almostFull :
               .noStorageProblems
    }
    
    public var currentProPlan: AccountPlanEntity? {
        accountProPlans()?.first
    }
    
    public func currentSubscription() -> AccountSubscriptionEntity? {
        guard let subscriptions = accountSubscriptions(),
              let currentProPlan else {
            return nil
        }
        return subscriptions.first(where: { $0.id == currentProPlan.subscriptionId })
    }

    // MARK: - User and session management
    public func currentUser() async -> UserEntity? {
        await currentUserSource.currentUser()
    }
    
    public func isLoggedIn() -> Bool {
        currentUserSource.isLoggedIn
    }
    
    public func isAccountType(_ type: AccountTypeEntity) -> Bool {
        guard let currentAccountDetails else { return false }
        
        return currentAccountDetails.proLevel == type
    }
    
    public func refreshCurrentAccountDetails() async throws -> AccountDetailsEntity {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getAccountDetails(with: RequestDelegate { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let request):
                    guard let accountDetails = request.megaAccountDetails?.toAccountDetailsEntity() else {
                        completion(.failure(AccountDetailsErrorEntity.generic))
                        return
                    }
                    currentUserSource.setAccountDetails(accountDetails)
                    completion(.success(accountDetails))
                case .failure:
                    completion(.failure(AccountDetailsErrorEntity.generic))
                }
            })
        })
    }
    
    public func isExpiredAccount() -> Bool {
        sdk.businessStatus == .expired
    }
    
    public func isInGracePeriod() -> Bool {
        sdk.businessStatus == .gracePeriod
    }
    
    public func isBilledProPlan() -> Bool {
        guard let subscriptions = accountSubscriptions(),
              let currentProPlan = accountProPlans()?.first,
              let subscriptionId = currentProPlan.subscriptionId else {
            return false
        }
        
        return subscriptions.contains { $0.id == subscriptionId }
    }
    
    public func hasMultipleBilledProPlans() -> Bool {
        accountSubscriptions()?.filter { $0.accountType != .feature }.count ?? 0 > 1
    }

    // MARK: - Account operations
    public func contacts() -> [UserEntity] {
        sdk.contacts().toUserEntities()
    }
    
    public func totalNodesCount() -> UInt64 {
        sdk.totalNodes
    }
    
    public func getMyChatFilesFolder(completion: @escaping (Result<NodeEntity, AccountErrorEntity>) -> Void) {
        myChatFilesFolderNodeAccess.loadNode { myChatFilesFolderNode, _ in
            guard let myChatFilesFolderNode = myChatFilesFolderNode else {
                completion(.failure(AccountErrorEntity.nodeNotFound))
                return
            }
            
            completion(.success(myChatFilesFolderNode.toNodeEntity()))
        }
    }
    
    public func upgradeSecurity() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            sdk.upgradeSecurity(with: RequestDelegate { (result) in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure:
                    continuation.resume(throwing: AccountErrorEntity.generic)
                }
            })
        }
    }
    
    public func getMiscFlags() async throws {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getMiscFlags(with: RequestDelegate { result in
                switch result {
                case .success:
                    completion(.success)
                case .failure:
                    completion(.failure(AccountErrorEntity.generic))
                }
            })
        })
    }
    
    public func sessionTransferURL(path: String) async throws -> URL {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getSessionTransferURL(path, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let link = request.link,
                          let url = URL(string: link) else {
                        completion(.failure(AccountErrorEntity.generic))
                        return
                    }
                    completion(.success(url))
                case .failure:
                    completion(.failure(AccountErrorEntity.generic))
                }
            })
        })
    }

    // MARK: - Account social and notifications
    public func incomingContactsRequestsCount() -> Int {
        sdk.incomingContactRequests().size
    }
    
    public func relevantUnseenUserAlertsCount() -> UInt {
        sdk.userAlertList().relevantUnseenCount
    }

    // MARK: - Account events and delegates
    public var onAccountRequestFinish: AnyAsyncSequence<Result<AccountRequestEntity, any Error>> {
        accountUpdatesProvider.onAccountRequestFinish
    }
    
    public var onUserAlertsUpdates: AnyAsyncSequence<[UserAlertEntity]> {
        accountUpdatesProvider.onUserAlertsUpdates
    }
    
    public var onContactRequestsUpdates: AnyAsyncSequence<[ContactRequestEntity]> {
        accountUpdatesProvider.onContactRequestsUpdates
    }
    
    public var onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> {
        accountUpdatesProvider.onStorageStatusUpdates
    }
    
    public func multiFactorAuthCheck(email: String) async throws -> Bool {
        try await withAsyncThrowingValue { completion in
            sdk.multiFactorAuthCheck(withEmail: email, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.flag))
                case .failure:
                    completion(.failure(AccountErrorEntity.generic))
                }
            })
        }
    }
    
// MARK: - Node Sizes
    public func rootStorageUsed() -> Int64 {
        storageUsed(for: sdk.rootNode?.handle)
    }
    
    public func rubbishBinStorageUsed() -> Int64 {
        storageUsed(for: sdk.rubbishNode?.handle)
    }
    
    public func incomingSharesStorageUsed() -> Int64 {
        sdk.inShares()
            .toNodeArray()
            .reduce(0) { sum, node in
                sum + sdk.size(for: node).int64Value
            }
    }
    
    public func backupStorageUsed() async throws -> Int64 {
        guard let node = try await backupRootNode().toMEGANode(in: sdk) else { return 0 }
        let nodeInfo = try await folderInfo(node: node)
        return nodeInfo.currentSize
    }
    
    private func storageUsed(for handle: HandleEntity?) -> Int64 {
        guard let handle,
             let currentAccountDetails else { return 0 }

        return currentAccountDetails.storageUsedForHandle(handle)
    }
    
    private func backupRootNode() async throws -> NodeEntity {
        try await withAsyncThrowingValue(in: { completion in
            backupsRootFolderNodeAccess.loadNode { node, _ in
                guard let node = node else {
                    completion(.failure(FolderInfoErrorEntity.notFound))
                    return
                }
                
                completion(.success(node.toNodeEntity()))
            }
        })
    }
    
    private func folderInfo(node: MEGANode) async throws -> FolderInfoEntity {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getFolderInfo(for: node, delegate: RequestDelegate { result in
                switch result {
                case .failure:
                    completion(.failure(FolderInfoErrorEntity.notFound))
                case .success(let request):
                    guard let megaFolderInfo = request.megaFolderInfo else {
                        completion(.failure(FolderInfoErrorEntity.notFound))
                        return
                    }
                    completion(.success(megaFolderInfo.toFolderInfoEntity()))
                }
            })
        })
    }
    
    private func availablePlans() async -> [PlanEntity] {
        await withAsyncValue { completion in
            sdk.getPricingWith(RequestDelegate { result in
                if case let .success(request) = result {
                    completion(.success(request.pricing?.availableSDKPlans() ?? []))
                } else {
                    completion(.success([]))
                }
            })
        }
    }
    
    /// Retrieves the Pro plan from the current account details, if it exists.
    ///
    /// This function checks if the `currentAccountDetails` is available and
    /// filters the plans to find the one marked as the Pro plan. It is guaranteed
    /// that a user can only have 0 or 1 Pro plan at any given time. Therefore, this
    /// function will return either one Pro plan or nil if no Pro plan is found.
    ///
    /// - Returns: An optional `AccountPlanEntity` representing the Pro plan,
    ///
    private func accountProPlans() -> [AccountPlanEntity]? {
        guard let currentAccountDetails else { return nil }
        return currentAccountDetails.plans.filter { $0.isProPlan }
    }
    
    private func accountSubscriptions() -> [AccountSubscriptionEntity]? {
        guard let currentAccountDetails else { return nil }
        return currentAccountDetails.subscriptions
    }
}
