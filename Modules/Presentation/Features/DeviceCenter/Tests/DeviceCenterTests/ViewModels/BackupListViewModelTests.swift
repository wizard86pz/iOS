import Combine
@testable import DeviceCenter
import DeviceCenterMocks
import MEGADomain
import MEGADomainMock
import XCTest

final class BackupListViewModelTests: XCTestCase {
    let mockCurrentDeviceId = "1"
    let mockAuxDeviceId = "2"
    let devicesUpdatePublisher = PassthroughSubject<[DeviceEntity], Never>()
    
    func test_loadAssets_matchesBackupStatuses() {
        var backup = BackupEntity(
            id: 1,
            name: "backup1"
        )
        
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: [backup]
        )
        
        for status in backupStatusEntities() {
            backup.backupStatus = status
            validateCurrentStatus(viewModel, backup)
        }
    }
    
    func testLoadBackupsModels_backupsWithDifferentStatus_loadsBackupModels() {
        let backups = backups()
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: backups
        )
        
        viewModel.loadBackupsModels()
        
        XCTAssertEqual(viewModel.backupModels.count, 3)
        
        let expectedBackupNames = backups.map(\.name)
        let foundBackupNames = viewModel.backupModels.map(\.name)
        XCTAssertEqual(foundBackupNames, expectedBackupNames)
    }
    
    func testFilterBackups_withSearchText_matchingPartialDeviceName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "backup")
        
        let expectedDeviceNames = ["backup1", "backup2", "backup3"]
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let foundDeviceNames = viewModel.filteredBackups.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        cancellables.forEach { $0.cancel() }
    }

    func testFilterBackups_withSearchText_matchingDeviceName() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "backup1")
        
        let expectedDeviceNames = ["backup1"]
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let foundDeviceNames = viewModel.filteredBackups.map(\.name)
        XCTAssertEqual(expectedDeviceNames, foundDeviceNames)
        
        cancellables.forEach { $0.cancel() }
    }

    func testFilterBackups_withSearchText_whenNoMatchFound() async {
        let (viewModel, expectation, cancellables) = await makeSUTForSearch(searchText: "fake_name")
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(viewModel.filteredBackups.isEmpty)
        
        cancellables.forEach { $0.cancel() }
    }
    
    func testFilterBackups_withEmptySearchText_shouldReturnTheSameBackups() {
        let backups = backups()
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: backups
        )
        
        viewModel.searchText = ""
        
        let expectedBackupNames = backups.map(\.name)
        let foundBackupNames = viewModel.backupModels.map(\.name)
        XCTAssertEqual(foundBackupNames, expectedBackupNames)
    }
    
    func testFilterAndLoadCurrentDeviceBackups_loadsBackupsForCurrentDevice() async {
        let backups = backups()
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: userGroupedBackups[mockCurrentDeviceId] ?? []
        )
        
        let expectedBackupNames = userGroupedBackups[mockCurrentDeviceId]?.map(\.name)
        let foundBackupNames = viewModel.backups.map(\.name)
        
        await viewModel.filterAndLoadCurrentDeviceBackups(devices())
        XCTAssertEqual(foundBackupNames, expectedBackupNames)
        
        let viewModel2 = makeSUT(
            currentDeviceId: mockAuxDeviceId,
            backups: userGroupedBackups[mockAuxDeviceId] ?? []
        )
        
        await viewModel2.filterAndLoadCurrentDeviceBackups(devices())
        
        let expectedBackupNames2 = userGroupedBackups[mockAuxDeviceId]?.map(\.name)
        let foundBackupNames2 = viewModel2.backups.map(\.name)
        
        XCTAssertEqual(foundBackupNames2, expectedBackupNames2)
    }
    
    func testUpdateDeviceStatusesAndNotify_fetchesAndUpdateDevices() async {
        let backups = backups()
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: userGroupedBackups[mockCurrentDeviceId] ?? [],
            deviceCenterUseCase: mockUseCase
        )
        
        await viewModel.syncDevicesAndLoadBackups()
        let expectedBackupNames = userGroupedBackups[mockCurrentDeviceId]?.map(\.name)
        let foundBackupNames = viewModel.backups.map(\.name)
        
        XCTAssertEqual(foundBackupNames, expectedBackupNames)
    }
    
    func testUpdateDeviceStatusesAndNotify_cancellation() async throws {
        let backups = backups()
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: userGroupedBackups[mockCurrentDeviceId] ?? [],
            deviceCenterUseCase: mockUseCase,
            updateInterval: 5
        )
        
        let task = Task {
            try await viewModel.updateDeviceStatusesAndNotify()
        }
        
        task.cancel()
        
        XCTAssertTrue(task.isCancelled, "Task should be cancelled")
    }
    
    func testActionsForBackup_cameraUploadBackupType_returnsCorrectActions() {
        let backup = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId,
            type: .cameraUpload
        )
        
        let backups = [backup]
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: userGroupedBackups[mockCurrentDeviceId] ?? [],
            deviceCenterUseCase: mockUseCase
        )
        
        let actions = viewModel.actionsForBackup(backup)
        let actionsType = actions?.compactMap {$0.type}
        let expectedActions: [DeviceCenterActionType] = [.showInCD, .info]
        
        XCTAssertEqual(actionsType, expectedActions, "Actions for camera upload backup are incorrect")
    }
 
    func testActionsForBackup_otherBackupType_returnsCorrectActions() {
        let backup = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId,
            type: .downSync
        )
        
        let backups = [backup]
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: userGroupedBackups[mockCurrentDeviceId] ?? [],
            deviceCenterUseCase: mockUseCase
        )
        
        let actions = viewModel.actionsForBackup(backup)
        let actionsType = actions?.compactMap {$0.type}
        let expectedActions: [DeviceCenterActionType] = [.showInBackups, .info]
        
        XCTAssertEqual(actionsType, expectedActions, "Actions for backup are incorrect")
    }
    
    func testActionsForDevice_currentDeviceWithCameraUpload_returnsCorrectActions() {
        let backup = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId,
            type: .cameraUpload
        )
        
        let backups = [backup]
        
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: userGroupedBackups[mockCurrentDeviceId] ?? [],
            deviceCenterUseCase: mockUseCase
        )
        
        let actions = viewModel.actionsForDevice()
        
        let expectedActions: [DeviceCenterActionType] = [.rename, .info, .cameraUploads]
        let actionsType = actions.compactMap {$0.type}
        XCTAssertEqual(actionsType, expectedActions, "Actions for the current device are incorrect")
    }
    
    func testActionsForDevice_currentDeviceWithoutCameraUpload_returnsCorrectActions() {
        let backup = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId,
            type: .upSync
        )
        
        let backups = [backup]
        
        let userGroupedBackups = Dictionary(grouping: backups, by: \.deviceId)
        let mockUseCase = MockDeviceCenterUseCase(devices: devices(), currentDeviceId: mockCurrentDeviceId)
        
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: userGroupedBackups[mockCurrentDeviceId] ?? [],
            deviceCenterUseCase: mockUseCase
        )
        
        let actions = viewModel.actionsForDevice()
        
        let expectedActions: [DeviceCenterActionType] = [.rename, .info]
        let actionsType = actions.compactMap {$0.type}
        XCTAssertEqual(actionsType, expectedActions, "Actions for the current device are incorrect")
    }
    
    private func backups() -> [BackupEntity] {
        var backup1 = BackupEntity(
            id: 1,
            name: "backup1",
            deviceId: mockCurrentDeviceId
        )
        
        backup1.backupStatus = .updating
        
        var backup2 = BackupEntity(
            id: 2,
            name: "backup2",
            deviceId: mockCurrentDeviceId
        )
        
        backup2.backupStatus = .upToDate
        
        var backup3 = BackupEntity(
            id: 3,
            name: "backup3",
            deviceId: mockAuxDeviceId
        )
        
        backup3.backupStatus = .offline
        
        return [backup1, backup2, backup3]
    }
    
    private func devices() -> [DeviceEntity] {
        let userGroupedBackups = Dictionary(grouping: backups(), by: \.deviceId)
        
        let device1 = DeviceEntity(
            id: mockCurrentDeviceId,
            name: "device1",
            backups: userGroupedBackups[mockCurrentDeviceId],
            status: .upToDate
        )
        
        let device2 = DeviceEntity(
            id: "2",
            name: "device2",
            backups: userGroupedBackups[mockAuxDeviceId],
            status: .upToDate
        )
        
        return [device1, device2]
    }
    
    private func backupStatusEntities() -> [BackupStatusEntity] {
        [.upToDate, .offline, .blocked, .outOfQuota, .error, .disabled, .paused, .updating, .scanning, .initialising, .backupStopped, .noCameraUploads]
    }
    
    private func backupTypeEntities() -> [BackupTypeEntity] {
        [.backupUpload, .cameraUpload, .mediaUpload, .twoWay, .downSync, .upSync, .invalid]
    }
    
    private func validateCurrentStatus(_ viewModel: BackupListViewModel, _ backupEntity: BackupEntity) {
        let assets = viewModel.loadAssets(for: backupEntity)
        XCTAssertNotNil(assets)
        XCTAssertEqual(assets?.backupStatus.status, backupEntity.backupStatus)
    }
    
    private func makeSUTForSearch(
        searchText: String? = nil
    ) async -> (
        viewModel: BackupListViewModel,
        expectation: XCTestExpectation,
        cancellables: Set<AnyCancellable>
    ) {
        let backups = backups()
        let viewModel = makeSUT(
            currentDeviceId: mockCurrentDeviceId,
            backups: backups
        )
        
        var cancellables = Set<AnyCancellable>()
        var expectationDescription = "Filtered backups should update"
        
        if let searchText = searchText {
            expectationDescription += " when searching for '\(searchText)'"
            viewModel.searchText = searchText
        }
        
        let expectation = XCTestExpectation(description: expectationDescription)
        
        viewModel.$filteredBackups
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        return (viewModel, expectation, cancellables)
    }
    
    private func makeSUT(
        currentDeviceId: String,
        backups: [BackupEntity],
        deviceCenterUseCase: MockDeviceCenterUseCase = MockDeviceCenterUseCase(),
        updateInterval: UInt64 = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) -> BackupListViewModel {
        
        let backupStatusEntities = backupStatusEntities()
        let backupTypeEntities = backupTypeEntities()
        let sut = BackupListViewModel(
            selectedDeviceId: currentDeviceId,
            devicesUpdatePublisher: devicesUpdatePublisher,
            updateInterval: updateInterval,
            deviceCenterUseCase: deviceCenterUseCase,
            router: MockBackupListViewRouter(),
            backups: backups,
            backupListAssets:
                BackupListAssets(
                    backupTypes: backupTypeEntities.compactMap { BackupType(type: $0) }
                ),
            emptyStateAssets:
                EmptyStateAssets(
                    image: "",
                    title: ""
                ),
            searchAssets: SearchAssets(
                placeHolder: "",
                cancelTitle: ""
            ),
            backupStatuses: backupStatusEntities.compactMap { BackupStatus(status: $0) },
            deviceCenterActions: [
                DeviceCenterAction(
                    type: .cameraUploads
                ),
                DeviceCenterAction(
                    type: .info
                ),
                DeviceCenterAction(
                    type: .rename
                ),
                DeviceCenterAction(
                    type: .showInBackups
                ),
                DeviceCenterAction(
                    type: .showInCD
                )
            ]
        )
        
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
