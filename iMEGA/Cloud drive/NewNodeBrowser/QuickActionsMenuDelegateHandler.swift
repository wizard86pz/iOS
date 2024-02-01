import MEGADomain
import MEGAL10n

final class QuickActionsMenuDelegateHandler: QuickActionsMenuDelegate {
    
    let showNodeInfo: (NodeEntity) -> Void
    let manageShare: (NodeEntity) -> Void
    let shareFolders: ([NodeEntity]) -> Void
    let download: ([NodeEntity]) -> Void
    let presentGetLink: ([NodeEntity]) -> Void
    let copy: (NodeEntity) -> Void
    let removeLink: ([NodeEntity]) -> Void
    let removeSharing: (NodeEntity) -> Void
    let rename: (NodeEntity) -> Void
    let leaveSharing: (NodeEntity) -> Void
    let nodeSource: NodeSource
    
    // this needs to be supplied from the outside to trigger the menu rebuild
    var refreshMenu: (() -> Void)?
    
    init(
        showNodeInfo: @escaping (NodeEntity) -> Void,
        manageShare: @escaping (NodeEntity) -> Void,
        shareFolders: @escaping ([NodeEntity]) -> Void,
        download: @escaping ([NodeEntity]) -> Void,
        presentGetLink: @escaping ([NodeEntity]) -> Void,
        copy: @escaping (NodeEntity) -> Void,
        removeLink: @escaping ([NodeEntity]) -> Void,
        removeSharing: @escaping (NodeEntity) -> Void,
        rename: @escaping (NodeEntity) -> Void,
        leaveSharing: @escaping (NodeEntity) -> Void,
        nodeSource: NodeSource
    ) {
        self.showNodeInfo = showNodeInfo
        self.manageShare = manageShare
        self.shareFolders = shareFolders
        self.presentGetLink = presentGetLink
        self.copy = copy
        self.removeLink = removeLink
        self.download = download
        self.removeSharing = removeSharing
        self.rename = rename
        self.leaveSharing = leaveSharing
        
        self.nodeSource = nodeSource
    }
    
    func quickActionsMenu(
        didSelect action: QuickActionEntity,
        needToRefreshMenu: Bool
    ) {
        guard
            case let .node(nodeProvider) = nodeSource,
            let parentNode = nodeProvider()
        else { return }
        
        switch action {
        case .info:
            showNodeInfo(parentNode)
        case .download:
            download([parentNode])
        case .shareLink, .manageLink:
            presentGetLink([parentNode])
        case .shareFolder:
            shareFolders([parentNode])
        case .rename:
            rename(parentNode)
        case .leaveSharing:
            leaveSharing(parentNode)
        case .copy:
            copy(parentNode)
        case .manageFolder:
            manageShare(parentNode)
        case .removeSharing:
            removeSharing(parentNode)
        case .removeLink:
            removeLink([parentNode])
        default:
            break
        }
        
        if needToRefreshMenu {
            assert(refreshMenu != nil, "refreshMenu needs to be set before using")
            refreshMenu?()
        }
    }
}
