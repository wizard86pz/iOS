@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

fileprivate extension ViewModeLocation {
    static var anyCustomLocation: Self {
        .customLocation(.anyCustom)
    }
}

fileprivate extension ViewModeLocation.Custom {
    static var anyCustom: Self {
        .init(name: "AnyLocation")
    }
}

fileprivate extension HandleEntity {
    static var anyHandle: Self = 1
}

final class ViewModeStoreTests: XCTestCase {
    class Harness {
        let sut: ViewModeStore
        let megaStore = MockMEGAStore()
        var preferenceRepo: MockPreferenceRepository
        
        init(savedPreference: ViewModePreferenceEntity? = nil) {
            self.preferenceRepo = MockPreferenceRepository()
            if let savedPreference {
                preferenceRepo[MEGAViewModePreference] = savedPreference.rawValue
            }
            sut = ViewModeStore(
                preferenceRepo: preferenceRepo,
                megaStore: megaStore,
                sdk: MockSdk(),
                notificationCenter: .init()
            )
        }
        
        func viewMode(for location: ViewModeLocation) -> ViewModePreferenceEntity {
            sut.viewMode(for: location)
        }
        
        func viewMode(for node: NodeEntity = NodeEntity(handle: HandleEntity.anyHandle)) -> ViewModePreferenceEntity {
            viewMode(for: .node(node))
        }
        
        func primeMegaStore(_ handle: HandleEntity, mode: ViewModePreferenceEntity) {
            megaStore.viewModes[handle] = mode
        }
        
        func primeMegaStore(_ offlineLocation: ViewModeLocation.Custom, mode: ViewModePreferenceEntity) {
            megaStore.offlineViewModes[offlineLocation.path] = mode
        }
        
        func storedOfflineMode(for location: ViewModeLocation.Custom) -> ViewModePreferenceEntity? {
            megaStore.offlineViewModes[location.path]
        }
        
        class MockMEGAStore: MEGAStore {
            lazy var inMemoryContainer: NSPersistentContainer = {
                let description = NSPersistentStoreDescription()
                description.url = URL(fileURLWithPath: "/dev/null")
                let container = NSPersistentContainer(name: "MEGACD")
                container.persistentStoreDescriptions = [description]
                container.loadPersistentStores { _, error in
                    if let error = error as NSError? {
                        fatalError("Unresolved error \(error), \(error.userInfo)")
                    }
                }
                return container
            }()
            var viewModes: [UInt64: ViewModePreferenceEntity] = [:]
            @objc override func fetchCloudAppearancePreference(handle: UInt64) -> CloudAppearancePreference? {
                let pref = NSEntityDescription.insertNewObject(forEntityName: "CloudAppearancePreference", into: inMemoryContainer.viewContext) as! CloudAppearancePreference
                if let viewMode = viewModes[handle] {
                    pref.viewMode = NSNumber(integerLiteral: viewMode.rawValue)
                }
                return pref
            }
            
            var offlineViewModes: [String: ViewModePreferenceEntity] = [:]
            @objc override func fetchOfflineAppearancePreference(path: String) -> OfflineAppearancePreference? {
                
                guard let viewMode = offlineViewModes[path] else {
                    return nil
                }
                
                let pref = NSEntityDescription.insertNewObject(forEntityName: "OfflineAppearancePreference", into: inMemoryContainer.viewContext) as! OfflineAppearancePreference
                pref.viewMode = NSNumber(integerLiteral: viewMode.rawValue)
                pref.localPath = path
                return pref
            }
            
            @objc override func insertOrUpdateOfflineViewMode(path: String, viewMode: Int) {
                offlineViewModes[path] = ViewModePreferenceEntity(rawValue: viewMode)
            }
        }
    }
    
    func test_ReadViewMode_fromPreference_returnsList_ifNothingIsSaved() {
        let mode = Harness().viewMode()
        XCTAssertEqual(mode, .list)
    }
    
    func test_ReadViewMode_fromPreference_returnsThumbnail_ifIsSavedInPrefs() {
        let harness = Harness(savedPreference: .thumbnail)
        XCTAssertEqual(harness.viewMode(), .thumbnail)
    }
    
    func test_ReadViewMode_fromPreference_returnsList_ifIsSavedInPrefs() {
        let harness = Harness(savedPreference: .list)
        XCTAssertEqual(harness.viewMode(), .list)
    }
    
    func test_ReadViewMode_fromMEGAStore_returnsList_ifSavedForNode() {
        let harness = Harness(savedPreference: .perFolder)
        harness.primeMegaStore(.anyHandle, mode: .list)
        XCTAssertEqual(harness.viewMode(), .list)
    }
    
    func test_ReadViewMode_fromMEGAStore_returnsThumbnail_ifSavedForNode() {
        let harness = Harness(savedPreference: .perFolder)
        harness.primeMegaStore(.anyHandle, mode: .thumbnail)
        XCTAssertEqual(harness.viewMode(), .thumbnail)
    }
    
    func test_ReadViewMode_fromMEGAStore_forCustomLocation_returnStoreViewMode() {
        let harness = Harness()
        harness.primeMegaStore(.anyCustom, mode: .thumbnail)
        XCTAssertEqual(harness.viewMode(for: .anyCustomLocation), .thumbnail)
    }
    
    func test_saveViewMode_toMEGAStore_forCustomLocation_storesInMEGAStore() {
        let harness = Harness()
        harness.sut.save(viewMode: .thumbnail, for: .anyCustomLocation)
        XCTAssertEqual(harness.storedOfflineMode(for: .anyCustom), .thumbnail)
    }
    
    func test_readViewMode_fromMEGAStore_forCustomLocation_returnsPreference_ifCoreDataEmpty() {
        let harness = Harness(savedPreference: .thumbnail)
        XCTAssertEqual(harness.viewMode(for: .anyCustomLocation), .thumbnail)
    }
    
    func test_saveViewMode_toMEGAStore_forCustomLocation_doesNotUpdatePreference() {
        let harness = Harness()
        harness.sut.save(viewMode: .thumbnail, for: .anyCustomLocation)
        XCTAssertTrue(harness.preferenceRepo.isEmpty)
    }
}
