public protocol WaitingRoomUseCaseProtocol {
    func userName() -> String
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity
}

public final class WaitingRoomUseCase<T: WaitingRoomRepositoryProtocol>: WaitingRoomUseCaseProtocol {
    private var waitingRoomRepo: T
    
    public init(waitingRoomRepo: T) {
        self.waitingRoomRepo = waitingRoomRepo
    }
    
    public func userName() -> String {
        waitingRoomRepo.userName()
    }
    
    public func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity {
        try await waitingRoomRepo.joinChat(forChatId: chatId, userHandle: userHandle)
    }
}
