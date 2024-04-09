import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

protocol AlbumListViewRouting {
    func cell(album: AlbumEntity, selection: AlbumSelection) -> AlbumCell
    func albumContainer(album: AlbumEntity, newAlbumPhotosToAdd: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) -> AlbumContainerWrapper
}

struct AlbumListViewRouter: AlbumListViewRouting, Routing {
    weak var photoAlbumContainerViewModel: PhotoAlbumContainerViewModel?
    
    func cell(album: AlbumEntity, selection: AlbumSelection) -> AlbumCell {
        let vm = AlbumCellViewModel(
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
            album: album,
            selection: selection
        )
        return AlbumCell(viewModel: vm)
    }
    
    func albumContainer(album: AlbumEntity, newAlbumPhotosToAdd: [NodeEntity]?, existingAlbumNames: @escaping () -> [String]) -> AlbumContainerWrapper {
        return AlbumContainerWrapper(album: album, newAlbumPhotos: newAlbumPhotosToAdd, existingAlbumNames: existingAlbumNames)
    }
    
    @MainActor
    func build() -> UIViewController {
        let filesSearchRepo = FilesSearchRepository.newRepo
        let albumContentsUpdatesRepo = AlbumContentsUpdateNotifierRepository.newRepo
        let mediaUseCase = MediaUseCase(fileSearchRepo: filesSearchRepo)
        let userAlbumRepo = userAlbumRepository()
        let vm = AlbumListViewModel(
            usecase: AlbumListUseCase(
                fileSearchRepository: filesSearchRepo,
                mediaUseCase: mediaUseCase,
                userAlbumRepository: userAlbumRepo,
                albumContentsUpdateRepository: albumContentsUpdatesRepo,
                albumContentsUseCase: AlbumContentsUseCase(albumContentsRepo: albumContentsUpdatesRepo,
                                                           mediaUseCase: mediaUseCase,
                                                           fileSearchRepo: filesSearchRepo,
                                                           userAlbumRepo: userAlbumRepo)
            ),
            albumModificationUseCase: AlbumModificationUseCase(userAlbumRepo: userAlbumRepo),
            shareAlbumUseCase: ShareAlbumUseCase(shareAlbumRepository: ShareAlbumRepository.newRepo),
            tracker: DIContainer.tracker,
            monitorAlbumsUseCase: makeMonitorAlbumsUseCase(),
            alertViewModel: TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                                                    placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                                                    affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                                                    message: nil),
            photoAlbumContainerViewModel: photoAlbumContainerViewModel
        )
        
        let content = AlbumListView(viewModel: vm,
                                    router: self)
        
        return UIHostingController(rootView: content)
    }
    
    func start() {}
    
    private func makeMonitorAlbumsUseCase() -> MonitorAlbumsUseCase {
        let photoLibraryRepository = PhotoLibraryRepository(
            sdk: MEGASdk.shared,
            cameraUploadNodeAccess: CameraUploadNodeAccess.shared
        )
        let photoLibraryUseCase = PhotoLibraryUseCase(photosRepository: photoLibraryRepository,
                                                      searchRepository: FilesSearchRepository.newRepo)
        
        return MonitorAlbumsUseCase(
            monitorPhotosUseCase: MonitorPhotosUseCase(
                photosRepository: PhotosRepository.sharedRepo,
                photoLibraryUseCase: photoLibraryUseCase),
            mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo),
            userAlbumRepository: userAlbumRepository(),
            photosRepository: PhotosRepository.sharedRepo)
    }
    
    private func userAlbumRepository() -> any UserAlbumRepositoryProtocol {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .albumPhotoCache) else {
            return UserAlbumRepository.newRepo
        }
        return UserAlbumCacheRepository.newRepo
    }
}
