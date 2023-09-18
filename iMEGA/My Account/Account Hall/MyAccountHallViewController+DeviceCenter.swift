import DeviceCenter
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import SwiftUI

extension MyAccountHallViewController {
    func navigateToDeviceCenter() {
        DeviceListViewRouter(
            navigationController: navigationController,
            deviceCenterBridge: makeDeviceCenterBridge(),
            deviceCenterUseCase: DeviceCenterUseCase(deviceCenterRepository: DeviceCenterRepository.newRepo),
            deviceCenterAssets: makeDeviceListAssetData()
        ).start()
    }
    
    func makeDeviceListAssetData() -> DeviceCenterAssets {
        DeviceCenterAssets(
            deviceListAssets:
                makeDeviceListAssets(),
            backupListAssets:
                makeBackupListAssets(),
            emptyStateAssets:
                makeEmptyStateAssets(),
            searchAssets:
                makeSearchAssets(),
            backupStatuses: backupStatusesList(),
            deviceCenterActions: deviceCenterActionList()
        )
    }
    
    private func makeDeviceListAssets() -> DeviceListAssets {
        return DeviceListAssets(
            title: Strings.Localizable.Device.Center.title,
            currentDeviceTitle: Strings.Localizable.Device.Center.Current.Device.title,
            otherDevicesTitle: Strings.Localizable.Device.Center.Other.Devices.title,
            deviceDefaultName: Strings.Localizable.Device.Center.Default.Device.title
        )
    }
    
    private func makeBackupListAssets() -> BackupListAssets {
        return BackupListAssets(
            backupTypes: [
                BackupType(type: .backupUpload, iconName: Asset.Images.Backup.backupFolder.name),
                BackupType(type: .cameraUpload, iconName: Asset.Images.Backup.cameraUploadsFolder.name),
                BackupType(type: .mediaUpload, iconName: Asset.Images.Backup.cameraUploadsFolder.name),
                BackupType(type: .twoWay, iconName: Asset.Images.Backup.syncFolder.name),
                BackupType(type: .downSync, iconName: Asset.Images.Backup.syncFolder.name),
                BackupType(type: .upSync, iconName: Asset.Images.Backup.syncFolder.name),
                BackupType(type: .invalid, iconName: Asset.Images.Backup.syncFolder.name)
            ]
        )
    }
    
    private func makeEmptyStateAssets() -> EmptyStateAssets {
        return EmptyStateAssets(
            image: Asset.Images.EmptyStates.searchEmptyState.name,
            title: Strings.Localizable.noResults
        )
    }
    
    private func makeSearchAssets() -> SearchAssets {
        return SearchAssets(
            placeHolder: Strings.Localizable.search,
            cancelTitle: Strings.Localizable.cancel
        )
    }
    
    private func backupStatusesList() -> [BackupStatus] {
        return [
            BackupStatus(
                status: .upToDate,
                title: Strings.Localizable.Device.Center.Backup.UpToDate.Status.message,
                colorName: Colors.General.Green._34C759.name,
                iconName: Asset.Images.BackupStatus.upToDate.name
            ),
            BackupStatus(
                status: .scanning,
                title: Strings.Localizable.Device.Center.Backup.Scanning.Status.message,
                colorName: Colors.General.Blue._007Aff.name,
                iconName: Asset.Images.BackupStatus.updating.name
            ),
            BackupStatus(
                status: .initialising,
                title: Strings.Localizable.Device.Center.Backup.Initialising.Status.message,
                colorName: Colors.General.Blue._007Aff.name,
                iconName: Asset.Images.BackupStatus.updating.name
            ),
            BackupStatus(
                status: .updating,
                title: Strings.Localizable.Device.Center.Backup.Updating.Status.message,
                colorName: Colors.General.Blue._007Aff.name,
                iconName: Asset.Images.BackupStatus.updating.name
            ),
            BackupStatus(
                status: .noCameraUploads,
                title: Strings.Localizable.Device.Center.Backup.NoCameraUploads.Status.message,
                colorName: Colors.General.Orange.ff9500.name,
                iconName: Asset.Images.BackupStatus.noCameraUploads.name
            ),
            BackupStatus(
                status: .disabled,
                title: Strings.Localizable.Device.Center.Backup.Disabled.Status.message,
                colorName: Colors.General.Orange.ff9500.name,
                iconName: Asset.Images.BackupStatus.disabled.name
            ),
            BackupStatus(
                status: .offline,
                title: Strings.Localizable.Device.Center.Backup.Offline.Status.message,
                colorName: Colors.General.Gray._8E8E93.name,
                iconName: Asset.Images.BackupStatus.offlineStatus.name
            ),
            BackupStatus(
                status: .backupStopped,
                title: Strings.Localizable.Device.Center.Backup.BackupStopped.Status.message,
                colorName: Colors.General.Gray._8E8E93.name,
                iconName: Asset.Images.BackupStatus.error.name
            ),
            BackupStatus(
                status: .paused,
                title: Strings.Localizable.Device.Center.Backup.Paused.Status.message,
                colorName: Colors.General.Gray._8E8E93.name,
                iconName: Asset.Images.BackupStatus.paused.name
            ),
            BackupStatus(
                status: .outOfQuota,
                title: Strings.Localizable.Device.Center.Backup.OutOfQuota.Status.message,
                colorName: Colors.General.Red.ff3B30.name,
                iconName: Asset.Images.BackupStatus.outOfQuota.name
            ),
            BackupStatus(
                status: .error,
                title: Strings.Localizable.Device.Center.Backup.Error.Status.message,
                colorName: Colors.General.Red.ff3B30.name,
                iconName: Asset.Images.BackupStatus.error.name
            ),
            BackupStatus(
                status: .blocked,
                title: Strings.Localizable.Device.Center.Backup.Blocked.Status.message,
                colorName: Colors.General.Red.ff3B30.name,
                iconName: Asset.Images.BackupStatus.disabled.name
            )
        ]
    }
    
    private func deviceCenterActionList() -> [DeviceCenterAction] {
        return [
            DeviceCenterAction(
                type: .cameraUploads,
                title: Strings.Localizable.cameraUploadsLabel,
                dynamicSubtitle: {
                    CameraUploadManager.isCameraUploadEnabled ? Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.enabled :
                        Strings.Localizable.Device.Center.Camera.Uploads.Action.Status.disabled
                },
                icon: Asset.Images.Settings.cameraUploadsSettings.name
            ),
            DeviceCenterAction(
                type: .info,
                title: Strings.Localizable.info,
                icon: Asset.Images.Generic.info.name
            ),
            DeviceCenterAction(
                type: .rename,
                title: Strings.Localizable.rename,
                icon: Asset.Images.Generic.rename.name
            ),
            DeviceCenterAction(
                type: .showInCD,
                title: Strings.Localizable.Device.Center.Show.In.Cloud.Drive.Action.title,
                icon: Asset.Images.ActionSheetIcons.cloudDriveFolder.name
            ),
            DeviceCenterAction(
                type: .showInBackups,
                title: Strings.Localizable.Device.Center.Show.In.Backups.Action.title,
                icon: Asset.Images.MyAccount.backups.name
            ),
            DeviceCenterAction(
                type: .sort,
                title: Strings.Localizable.sortTitle,
                icon: Asset.Images.ActionSheetIcons.sort.name,
                subActions: [
                    DeviceCenterAction(
                        type: .sortAscending,
                        title: Strings.Localizable.nameAscending,
                        icon: Asset.Images.ActionSheetIcons.SortBy.ascending.name
                    ),
                    DeviceCenterAction(
                        type: .sortDescending,
                        title: Strings.Localizable.nameDescending,
                        icon: Asset.Images.ActionSheetIcons.SortBy.descending.name
                    )
                ]
            )
        ]
    }
    
    private func makeDeviceCenterBridge() -> DeviceCenterBridge {
        let bridge = DeviceCenterBridge()
        
        bridge.cameraUploadActionTapped = { [weak self] cameraUploadStatusChanged in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let navigationController = self?.findTopNavigationController() else { return }
        
                CameraUploadsSettingsViewRouter(presenter: navigationController, closure: {
                    cameraUploadStatusChanged()
                }).start()
            }
        }

        bridge.infoActionTapped = { _ in
            // Will be added in future tickets
        }
        
        bridge.renameActionTapped = { [weak self] renameEntity in
            guard let self else { return }
            RenameRouter(
                presenter: self,
                type: .device(
                    renameEntity: renameEntity
                ),
                renameUseCase:
                    RenameUseCase(
                        renameRepository: RenameRepository.newRepo
                    )
            ).start()
        }
        
        bridge.showInCDActionTapped = { _ in
            // Will be added in future tickets
        }
        
        bridge.showInBackupsActionTapped = { _ in
            // Will be added in future tickets
        }
        
        bridge.sortActionTapped = { _, _ in
            // Will be added in future tickets
        }
        
        return bridge
    }
    
    private func findPresentedViewController() -> UIViewController? {
        guard var topController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
    
    private func findTopNavigationController() -> UINavigationController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }

        if let hostingController = rootViewController as? UIHostingController<AdsSlotView<MainTabBarWrapper>> {
            for child in hostingController.children {
                if let tabBarController = child as? MainTabBarController,
                   let selectedNavController = tabBarController.selectedViewController as? UINavigationController {
                    return selectedNavController
                }
            }
        } else if let tabBarController = rootViewController as? MainTabBarController,
                  let selectedNavController = tabBarController.selectedViewController as? UINavigationController {
            return selectedNavController
        }
        return nil
    }
}
