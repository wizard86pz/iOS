import ChatRepo
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

extension MainTabBarController {
    private var shouldUseNewHomeSearchResults: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newHomeSearch)
    }

    @objc func makeHomeViewController() -> UIViewController {
        HomeScreenFactory().createHomeScreen(
            from: self,
            newHomeSearchResultsEnabled: shouldUseNewHomeSearchResults,
            tracker: DIContainer.tracker
        )
    }

    @objc func loadTabViewControllers() {
        defaultViewControllers = .init(capacity: 5)

        if let cloudDriveVC = cloudDriveViewController() {
            defaultViewControllers.add(cloudDriveVC)
        }
        if let photoAlbumVC = photoAlbumViewController() {
            defaultViewControllers.add(photoAlbumVC)
        }

        defaultViewControllers.add(makeHomeViewController())
        defaultViewControllers.add(chatViewController())

        if let sharedItemsVC = sharedItemsViewController() {
            defaultViewControllers.add(sharedItemsVC)
        }

        addTabDelegate()
        mainTabBarViewModel = createMainTabBarViewModel()
        configProgressView()
        showPSAViewIfNeeded()
        updateUI()
    }

    @objc func setupHomeSearchForABTesting() async {
        let isNewHomeSearchEnabled = await DIContainer.abTestProvider.abTestVariant(for: .newSearch) == .variantA
        await updateHomeSearchForABTesting(isNewHomeSearchEnabled: isNewHomeSearchEnabled)
    }

    @MainActor
    func updateHomeSearchForABTesting(isNewHomeSearchEnabled: Bool) async {
        guard let nav = defaultViewControllers[2] as? MEGANavigationController,
              let homeVC = nav.viewControllers.first as? HomeViewController
        else {
            return
        }

        let searchResultVC = HomeScreenFactory().makeSearchResultViewController(
            with: nav,
            bridge: homeVC.searchResultsBridge,
            newHomeSearchResultsEnabled: isNewHomeSearchEnabled,
            tracker: DIContainer.tracker
        )
        homeVC.searchResultViewController = searchResultVC
    }

    @objc func showPSAViewIfNeeded() {
        if psaViewModel == nil {
            psaViewModel = createPSAViewModel()
        }
        guard let psaViewModel else { return }
        showPSAViewIfNeeded(psaViewModel)
    }

    @objc func sharedItemsViewController() -> UIViewController? {
        guard let sharedItemsNavigationController = UIStoryboard(name: "SharedItems", bundle: nil).instantiateInitialViewController() as? MEGANavigationController,
              let vc = sharedItemsNavigationController.viewControllers.first
        else { return nil }
        (vc as? (any MyAvatarPresenterProtocol))?.configureMyAvatarManager()
        return sharedItemsNavigationController
    }

    @objc func cloudDriveViewController() -> UIViewController? {
        guard let cloudDriveNavigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateInitialViewController() as? MEGANavigationController,
              let vc = cloudDriveNavigationController.viewControllers.first
        else { return nil }
        (vc as? (any MyAvatarPresenterProtocol))?.configureMyAvatarManager()
        return cloudDriveNavigationController
    }

    @objc func updateUI() {
        guard let defaultViewControllers = defaultViewControllers as? [UIViewController] else { return }

        for i in  0...defaultViewControllers.count-1 {
            guard let navigationController = defaultViewControllers[i] as? MEGANavigationController else { break }
            navigationController.navigationDelegate = self

            guard
                let tabBarItem = navigationController.tabBarItem,
                let tabType = TabType(rawValue: i)
            else { break }
            tabBarItem.title = nil
            reloadInsets(for: tabBarItem)
            tabBarItem.accessibilityLabel = Tab(tabType: tabType).title
        }
        
        viewControllers = defaultViewControllers

        setBadgeValueForSharedItems()
        setBadgeValueForChats()
        configurePhoneImageBadge()

        selectedViewController = defaultViewControllers[TabManager.getPreferenceTab().tabType.rawValue]

        AppearanceManager.setupTabbar(tabBar, traitCollection: traitCollection)
    }

    @objc func configProgressView() {
        TransfersWidgetViewController.sharedTransfer().setProgressViewInKeyWindow()
    }

    @objc func reloadInsets(for tabBarItem: UITabBarItem) {
        if traitCollection.horizontalSizeClass == .regular {
            tabBarItem.imageInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            tabBarItem.imageInsets = .init(top: 6, left: 0, bottom: -6, right: 0)
        }
    }

    @objc func configurePhoneImageBadge() {
        if phoneBadgeImageView == nil {
            phoneBadgeImageView = UIImageView(image: .init(named: "onACall"))
            phoneBadgeImageView?.isHidden = true
            if let phoneBadgeImageView {
                tabBar.addSubview(phoneBadgeImageView)
            }
        }
    }

    @objc func createPSAViewModel() -> PSAViewModel? {
        let router = PSAViewRouter(tabBarController: self)
        let useCase = PSAUseCase(repo: PSARepository.newRepo)
        return PSAViewModel(router: router, useCase: useCase)
    }
    
    @objc func showPSAViewIfNeeded(_ psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.showPSAViewIfNeeded)
    }
    
    @objc func hidePSAView(_ hide: Bool, psaViewModel: PSAViewModel) {
        psaViewModel.dispatch(.setPSAViewHidden(hide))
    }
    
    @objc func updateUnreadChatsOnBackButton() {
        if let chatVC = existingChatRoomsListViewController {
            chatVC.assignBackButton()
        }
    }
    
    @objc func createMainTabBarViewModel() -> MainTabBarCallsViewModel {
        let router = MainTabBarCallsRouter(baseViewController: self)
        let mainTabBarCallsViewModel = MainTabBarCallsViewModel(router: router,
                                                                chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
                                                                callUseCase: CallUseCase(repository: CallRepository(chatSdk: .shared, callActionManager: CallActionManager.shared)),
                                                                chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
                                                                chatRoomUserUseCase: ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo, userStoreRepo: UserStoreRepository.newRepo))
        
        mainTabBarCallsViewModel.invokeCommand = { [weak self] command in
            guard let self else { return }
            
            excuteCommand(command)
        }
        
        return mainTabBarCallsViewModel
    }
    
    private func excuteCommand(_ command: MainTabBarCallsViewModel.Command) {
        switch command {
        case .showActiveCallIcon:
            phoneBadgeImageView?.isHidden = unreadMessages > 0
        case .hideActiveCallIcon:
            phoneBadgeImageView?.isHidden = true
        case .navigateToChatTab:
            selectedIndex = TabType.chat.rawValue
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func addTabDelegate() {
        self.delegate = self
    }

    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        showPSAViewIfNeeded()
    }
}

// MARK: - MEGANavigationControllerDelegate
extension MainTabBarController: MEGANavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController!, willShow viewController: UIViewController!, animated: Bool) {
        guard let psaViewModel else { return }
        hidePSAView(viewController.hidesBottomBarWhenPushed, psaViewModel: psaViewModel)
    }
}
