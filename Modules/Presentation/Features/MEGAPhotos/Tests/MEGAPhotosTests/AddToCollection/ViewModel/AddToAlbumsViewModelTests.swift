import Combine
import ContentLibraries
import MEGADomain
import MEGADomainMock
import MEGAL10n
@testable import MEGAPhotos
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import MEGASwiftUI
import SwiftUI
import Testing

@Suite("AddToAlbumsViewModel Tests")
struct AddToAlbumsViewModelTests {
    private enum TestError: Error {
        case timeout
    }

    @Suite("Ensure Columns Counts")
    @MainActor
    struct ColumnsCount {
        @Test("Column count is 3 for compact and 5 for regular",
              arguments: [
                (UserInterfaceSizeClass?.some(.compact), 3),
                (UserInterfaceSizeClass?.some(.regular), 5),
                (UserInterfaceSizeClass?.none, 3)]
        )
        func columnCount(
            horizontalSizeClass: UserInterfaceSizeClass?,
            expectedCount: Int
        ) {
            let sut = AddToAlbumsViewModelTests.makeSUT()
            
            #expect(sut.columns(horizontalSizeClass: horizontalSizeClass).count == expectedCount)
        }
    }
   
    @Suite("Monitor User Albums")
    @MainActor
    struct MonitorUseAlbums {
        @Test("Loading album cell view models")
        func userAlbumLoaded() async throws {
            let userAlbum1 = AlbumEntity(id: 4, type: .user, creationTime: try "2024-04-04T22:01:04Z".date)
            let userAlbum2 = AlbumEntity(id: 5, type: .user, creationTime: try "2024-04-05T10:02:04Z".date)
            let userAlbums = [userAlbum1, userAlbum2]
            let monitorUserAlbumsAsyncSequence = SingleItemAsyncSequence(item: userAlbums)
                .eraseToAnyAsyncSequence()
            
            let monitorAlbumsUseCase = MockMonitorAlbumsUseCase(
                monitorUserAlbumsSequence: monitorUserAlbumsAsyncSequence
            )
            let sut = AddToAlbumsViewModelTests.makeSUT(
                monitorAlbumsUseCase: monitorAlbumsUseCase)
            
            await confirmation("Album view models loaded in correct order") { albumViewModelsLoaded in
                let subscription = sut.$albums
                    .dropFirst()
                    .sink {
                        #expect($0 == [AlbumCellViewModel(album: userAlbum2),
                                       AlbumCellViewModel(album: userAlbum1)])
                        albumViewModelsLoaded()
                    }
                
                await sut.monitorUserAlbums()
                subscription.cancel()
            }
        }
    }
    
    @Suite("Create Albums")
    @MainActor
    struct CreateAlbums {
        @Test("On create album tap should show alert view")
        func onCreateAlbumTap() async throws {
            let sut = AddToAlbumsViewModelTests.makeSUT()
            
            var cancellable: AnyCancellable?
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                cancellable = sut.$showCreateAlbumAlert
                    .setFailureType(to: TestError.self)
                    .dropFirst()
                    .timeout(.milliseconds(500), scheduler: DispatchQueue.main, customError: {
                        TestError.timeout
                    })
                    .sink(receiveCompletion: {
                        cancellable?.cancel()
                        switch $0 {
                        case .finished:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }, receiveValue: {
                        #expect($0 == true)
                        cancellable?.cancel()
                        continuation.resume()
                    })
                
                sut.onCreateAlbumTapped()
            }
        }
        
        @Test("when create alert is shown and action is triggered then it should create album", arguments: [
            ("My Album", "My Album"),
            ("", Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder),
            (String?.none, Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder)])
        func createAlertView(albumName: String?, expectedName: String) async {
            let albumListUseCase = MockAlbumListUseCase()
            let sut = AddToAlbumsViewModelTests
                .makeSUT(albumListUseCase: albumListUseCase)
            let alertViewModel = sut.alertViewModel()
            
            #expect(alertViewModel == TextFieldAlertViewModel(
                title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                affirmativeButtonTitle: Strings.Localizable.createFolderButton,
                destructiveButtonTitle: Strings.Localizable.cancel))
            
            await confirmation("Ensure create user album created") { createdConfirmation in
                let invocationTask = Task {
                    for await invocation in albumListUseCase.invocationSequence {
                        #expect(invocation == .createUserAlbum(name: expectedName))
                        createdConfirmation()
                        break
                    }
                }
                alertViewModel.action?(albumName)
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
        }
    }

    @MainActor
    private static func makeSUT(
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol = MockMonitorAlbumsUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        albumListUseCase: some AlbumListUseCaseProtocol = MockAlbumListUseCase(),
        contentLibrariesConfiguration: ContentLibraries.Configuration = .init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { true })
    ) -> AddToAlbumsViewModel {
        .init(
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            thumbnailLoader: thumbnailLoader,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            albumCoverUseCase: albumCoverUseCase,
            albumListUseCase: albumListUseCase,
            contentLibrariesConfiguration: contentLibrariesConfiguration)
    }
}
