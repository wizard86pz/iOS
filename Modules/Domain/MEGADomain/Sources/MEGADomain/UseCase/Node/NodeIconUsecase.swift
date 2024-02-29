import Foundation

public protocol NodeIconUsecaseProtocol {
    func iconData(for node: NodeEntity) -> Data
}

public struct NodeIconUseCase<T: NodeIconRepositoryProtocol>: NodeIconUsecaseProtocol {
    
    private let nodeIconRepo: T
    
    public init(nodeIconRepo: T) {
        self.nodeIconRepo = nodeIconRepo
    }
    
    public func iconData(for node: NodeEntity) -> Data {
        nodeIconRepo.iconData(for: node)
    }
}
