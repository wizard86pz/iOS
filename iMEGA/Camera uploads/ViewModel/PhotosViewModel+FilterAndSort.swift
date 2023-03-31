import Foundation
import MEGADomain

extension PhotosViewModel {
    // MARK: - Sort
    
    func sortOrderType(forKey key: SortingKeys) -> SortOrderType {
        let sortType = SortOrderType(megaSortOrderType: Helper.sortType(for: key.rawValue))
        return sortType != .newest && sortType != .oldest ? .newest : sortType
    }
    
    // MARK: - Filter
    
    func filter(nodes: inout [NodeEntity], with type: PhotosFilterOptions) {
        if type == .allMedia {
            nodes = nodes.filter { $0.hasThumbnail }
        } else if type == .images {
            nodes = nodes.filter({ $0.name.mnz_isImagePathExtension && $0.hasThumbnail })
        } else if type == .videos {
            nodes = nodes.filter({ $0.name.mnz_isVideoPathExtension && $0.hasThumbnail })
        }
    }
    
    @objc func hasNoPhotos() -> Bool {
        mediaNodes.isEmpty
    }
}
