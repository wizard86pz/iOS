import MEGADomain
import MEGAPresentation

enum FavouritesViewAction: ActionType {
    case viewWillAppear
    case viewWillDisappear
    case didSelectRow(HandleEntity)
}

protocol FavouritesRouting: Routing {
    func openNode(_ nodeHandle: HandleEntity)
    func openNodeActions(nodeHandle: HandleEntity, sender: Any)
}

final class FavouritesViewModel: ViewModelType {
    
    private var router: any FavouritesRouting
    private var favouritesUseCase: any FavouriteNodesUseCaseProtocol
    
    enum Command: CommandType, Equatable {
        case showFavouritesNodes([NodeEntity])
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    init(router: some FavouritesRouting,
         favouritesUseCase: some FavouriteNodesUseCaseProtocol) {
        self.router = router
        self.favouritesUseCase = favouritesUseCase
    }
    
    func dispatch(_ action: FavouritesViewAction) {
        switch action {
        case .viewWillAppear:
            getAllFavouritesNodes()
            registerOnNodesUpdate()
            
        case .viewWillDisappear:
            unregisterOnNodesUpdate()
            
        case .didSelectRow(let nodeHandle):
            didSelectRow(nodeHandle)
        }
    }
    
    private func getAllFavouritesNodes() {
        favouritesUseCase.getAllFavouriteNodes { [weak self] result in
            switch result {
            case .success(let nodeEntities):
                self?.invokeCommand?(.showFavouritesNodes(nodeEntities))
                
            case .failure:
                MEGALogError("Error getting all favourites nodes")
            }
        }
    }
    
    private func registerOnNodesUpdate() {
        favouritesUseCase.registerOnNodesUpdate { [weak self] _ in
            self?.getAllFavouritesNodes()
        }
    }
    
    private func unregisterOnNodesUpdate() {
        favouritesUseCase.unregisterOnNodesUpdate()
    }
    
    private func didSelectRow(_ nodeHandle: HandleEntity) {
        router.openNode(nodeHandle)
    }
}
