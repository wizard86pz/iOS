@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

extension Int {
    static let testLimit = 10
}

final class CallLimitationsTests: XCTestCase {
    
    class Harness {
        let sut: CallLimitations
        init(
            initialLimit: Int = .testLimit,
            flagEnabled: Bool,
            isModerator: Bool = false // this is not used using contactPickerLimitChecker
        ) {
            
            let list: [FeatureFlagKey: Bool] = if flagEnabled {
                [.chatMonetization: true]
            } else {
                [.chatMonetization: false]
            }
            
            let ownPrivilege: ChatRoomPrivilegeEntity = if isModerator {
                .moderator
            } else {
                .unknown
            }
            
            sut = .init(
                initialLimit: initialLimit,
                chatRoom: ChatRoomEntity(ownPrivilege: ownPrivilege),
                callUseCase: MockCallUseCase(),
                chatRoomUseCase: MockChatRoomUseCase(),
                featureFlagProvider: MockFeatureFlagProvider(
                    list: list
                )
            )
        }
        
        // this is a short hand way of creating harness that has the most common/interesting scenario
        // with FF enabled and moderator
        static func withFeaturePresent() -> Harness {
            .init(
                flagEnabled: true,
                isModerator: true
            )
        }
    }
    
    func testCheckingInitialLimit_FF_off_isNotModerator_limitIsNeverReached() {
        let harness = Harness(flagEnabled: false, isModerator: false)
        XCTAssertFalse(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 999))
        XCTAssertFalse(harness.sut.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: 999,
            callParticipantsInWaitingRoom: 999)
        )
    }
    
    func testCheckingInitialLimit_FF_off_isModerator_limitIsNeverReached() {
        let harness = Harness(flagEnabled: false, isModerator: true)
        XCTAssertFalse(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 999))
        XCTAssertFalse(harness.sut.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: 999,
            callParticipantsInWaitingRoom: 999)
        )
    }
    
    func testCheckingInitialLimit_FF_on_isNotModerator_limitIsNeverReached() {
        let harness = Harness(flagEnabled: true, isModerator: false)
        XCTAssertFalse(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 999))
        XCTAssertFalse(harness.sut.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: 999,
            callParticipantsInWaitingRoom: 999)
        )
    }
    
    func testCheckingInitialLimit_FF_on_isModerator_belowLimit() {
        let harness = Harness(initialLimit: 10, flagEnabled: true, isModerator: true)
        XCTAssertFalse(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 9))
    }
    
    func testCheckingInitialLimit_FF_on_isModerator_atLimit() {
        let harness = Harness(initialLimit: 10, flagEnabled: true, isModerator: true)
        XCTAssertTrue(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 10))
    }
    
    func testCheckingInitialLimit_FF_on_isModerator_aboveLimit() {
        let harness = Harness(initialLimit: 10, flagEnabled: true, isModerator: true)
        XCTAssertTrue(harness.sut.hasReachedInCallFreeUserParticipantLimit(callParticipantCount: 11))
    }
    
    func testCheckingInitialLimit_TotalOfCallAndWaitingRoom_BelowLimit() {
        let harness = Harness.withFeaturePresent()
        XCTAssertFalse(harness.sut.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: 5,
            callParticipantsInWaitingRoom: 4)
        ) // 5 + 4 < 10
    }
    
    func testCheckingInitialLimit_TotalOfCallAndWaitingRoom_AboveLimit() {
        let harness = Harness.withFeaturePresent()
        XCTAssertTrue(harness.sut.hasReachedInCallPlusWaitingRoomFreeUserParticipantLimit(
            callParticipantCount: 5,
            callParticipantsInWaitingRoom: 6)
        ) // 5 + 6 > 10
    }
    
    func test_contactPickerLimitChecker_FF_off_returnsFalse() {
        let harness = Harness(flagEnabled: false)
        XCTAssertFalse(harness.sut.contactPickerLimitChecker(callParticipantCount: 100, selectedCount: 100, allowsNonHostToInvite: true))
    }
    
    func test_contactPickerLimitChecker_FF_on_not_allow_to_invite_returnsFalse() {
        let harness = Harness(flagEnabled: true)
        XCTAssertFalse(harness.sut.contactPickerLimitChecker(callParticipantCount: 100, selectedCount: 100, allowsNonHostToInvite: false))
    }
    
    func test_contactPickerLimitChecker_FF_on_allow_to_invite_underLimit_returnsFalse() {
        let harness = Harness(flagEnabled: true) // 10 > 5 + 4
        XCTAssertFalse(harness.sut.contactPickerLimitChecker(callParticipantCount: 5, selectedCount: 4, allowsNonHostToInvite: true))
    }
    
    func test_contactPickerLimitChecker_FF_on_allow_to_invite_overLimit_returnsTrue() {
        let harness = Harness(flagEnabled: true) // 10 > 5 + 6
        XCTAssertTrue(harness.sut.contactPickerLimitChecker(callParticipantCount: 6, selectedCount: 5, allowsNonHostToInvite: true))
    }
}
