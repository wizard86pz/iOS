import MEGADomain
import MEGARepo

@objc final class NodeAssetsManager: NSObject {
    @objc static var shared = NodeAssetsManager()
    
    @objc func icon(for node: MEGANode) -> UIImage {
        switch node.type {
        case .file:
            return image(for: ((node.name ?? "") as NSString).pathExtension)
        case .folder:
            if MyChatFilesFolderNodeAccess.shared.isTargetNode(for: node) {
                return Asset.Images.Filetypes.folderChat.image
            }
#if MAIN_APP_TARGET
            if CameraUploadNodeAccess.shared.isTargetNode(for: node) {
                return Asset.Images.Filetypes.folderCamera.image
            } else if BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupDeviceFolder(node.toNodeEntity()) {
                return backupDeviceIcon(for: node)
            }
#endif
            return commonFolderImage(for: node)
        case .incoming:
            return node.isFolder() ? commonFolderImage(for: node) : Asset.Images.Filetypes.generic.image
        default:
            return Asset.Images.Filetypes.generic.image
        }
    }
    
    @objc func image(for extension: String) -> UIImage {
        imageAsset(for: `extension`).image
    }
    
    @objc func imageName(for extension: String) -> String {
        imageAsset(for: `extension`).name
    }
    
    private func imageAsset(for extension: String) -> ImageAsset {
        let ext = `extension`.lowercased()
        
        if ext.matches(regex: FileExtensionType.jpg.rawValue) {
            return Asset.Images.Filetypes.image
        } else {
            let fileTypeImageName = FileTypes().fileType(forFileExtension: ext)
            return ImageAsset(name: fileTypeImageName)
        }
    }
    
    private func commonFolderImage(for node: MEGANode) -> UIImage {
        if node.isInShare() {
            return Asset.Images.Filetypes.folderIncoming.image
        } else if node.isOutShare() {
            return Asset.Images.Filetypes.folderOutgoing.image
        } else {
            return Asset.Images.Filetypes.folder.image
        }
    }
    
    private func backupDeviceIcon(for node: MEGANode) -> UIImage {
        guard node.deviceId != nil, let nodeName = node.name, !nodeName.isEmpty else { return commonFolderImage(for: node) }
        let nodeNameLowerCased = nodeName.lowercased()
        
        if nodeNameLowerCased.matches(regex: BackupDeviceTypeEntity.win.toRegexString()) {
            return Asset.Images.Backup.pcWindows.image
        } else if nodeNameLowerCased.matches(regex: BackupDeviceTypeEntity.linux.toRegexString()) {
            return Asset.Images.Backup.pcLinux.image
        } else if nodeNameLowerCased.matches(regex: BackupDeviceTypeEntity.mac.toRegexString()) {
            return Asset.Images.Backup.pcMac.image
        } else if nodeNameLowerCased.matches(regex: BackupDeviceTypeEntity.drive.toRegexString()) {
            return Asset.Images.Backup.drive.image
        } else {
            return Asset.Images.Backup.pc.image
        }
    }
}

enum FileExtensionType: String {
    case jpg = "jpg|jpeg"
}
