import Combine
import MEGADomain
import MEGAPresentation
import MEGAUIKit
import SwiftUI

public protocol DeviceListRouting: Routing {
    func showDeviceBackups(_ device: DeviceEntity)
}

public final class DeviceListViewRouter: NSObject, DeviceListRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    private let deviceCenterBridge: DeviceCenterBridge
    private let devicesUpdatePublisher: PassthroughSubject<[DeviceEntity], Never>
    private let refreshDevicesPublisher: PassthroughSubject<Void, Never>
    private let updateInterval: UInt64
    private let deviceCenterAssets: DeviceCenterAssets
    private let deviceCenterUseCase: any DeviceCenterUseCaseProtocol
    
    public init(
        navigationController: UINavigationController?,
        deviceCenterBridge: DeviceCenterBridge,
        deviceCenterUseCase: any DeviceCenterUseCaseProtocol,
        deviceCenterAssets: DeviceCenterAssets
    ) {
        self.navigationController = navigationController
        self.deviceCenterBridge = deviceCenterBridge
        self.deviceCenterAssets = deviceCenterAssets
        self.deviceCenterUseCase = deviceCenterUseCase
        
        devicesUpdatePublisher = PassthroughSubject<[DeviceEntity], Never>()
        refreshDevicesPublisher = PassthroughSubject<Void, Never>()
        updateInterval = 30
        
        super.init()
    }
    
    public func build() -> UIViewController {
        let deviceListViewModel = DeviceListViewModel(
            devicesUpdatePublisher: devicesUpdatePublisher,
            refreshDevicesPublisher: refreshDevicesPublisher,
            updateInterval: updateInterval,
            router: self,
            deviceCenterBridge: deviceCenterBridge,
            deviceCenterUseCase: deviceCenterUseCase,
            deviceListAssets: deviceCenterAssets.deviceListAssets,
            emptyStateAssets: deviceCenterAssets.emptyStateAssets,
            searchAssets: deviceCenterAssets.searchAssets,
            backupStatuses: deviceCenterAssets.backupStatuses,
            deviceCenterActions: deviceCenterAssets.deviceCenterActions
        )
        let deviceListView = DeviceListView(viewModel: deviceListViewModel)
        let hostingController = UIHostingController(rootView: deviceListView)
        baseViewController = hostingController
        baseViewController?.title = deviceCenterAssets.deviceListAssets.title
        baseViewController?.navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: deviceCenterAssets.deviceListAssets.title)

        return hostingController
    }
    
    public func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    public func showDeviceBackups(_ device: DeviceEntity) {
        guard let backups = device.backups else { return }
        
        BackupListViewRouter(
            selectedDeviceId: device.id,
            selectedDeviceName: device.name.isEmpty ? deviceCenterAssets.deviceListAssets.deviceDefaultName : device.name,
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            backups: backups,
            deviceCenterUseCase: deviceCenterUseCase,
            navigationController: navigationController,
            deviceCenterBridge: deviceCenterBridge,
            backupListAssets: deviceCenterAssets.backupListAssets,
            emptyStateAssets: deviceCenterAssets.emptyStateAssets,
            searchAssets: deviceCenterAssets.searchAssets,
            backupStatuses: deviceCenterAssets.backupStatuses,
            deviceCenterActions: deviceCenterAssets.deviceCenterActions
        ).start()
    }
}
