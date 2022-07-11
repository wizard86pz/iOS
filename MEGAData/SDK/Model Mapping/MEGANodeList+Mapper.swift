

extension MEGANodeList {
    func toNodeArray() -> [MEGANode] {
        guard (size?.intValue ?? 0) > 0 else { return [] }
        return (0..<size.intValue).compactMap({ node(at: $0) })
    }
    
    func toNodeEntities() -> [NodeEntity] {
        guard (size?.intValue ?? 0) > 0 else { return [] }
        return (0..<size.intValue).compactMap({ NodeEntity(node: node(at: $0)) })
    }
}

extension Array where Element == MEGANode {
    func toNodeEntities() -> [NodeEntity] {
        map { $0.toNodeEntity() }
    }
    
    func folderNodeList() -> [MEGANode] {
        filter { $0.isFolder() }
    }
    
    func fileNodeList() -> [MEGANode] {
        filter { $0.isFile() }
    }
    
    func multiMediaNodeList() -> [MEGANode] {
        filter { $0.name?.mnz_isVisualMediaPathExtension == true }
    }
}
