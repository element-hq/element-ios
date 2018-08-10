/*
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/// `OnBoardingManager` is used to manage onboarding steps, like create DM room with riot bot.
final public class OnBoardingManager: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let riotBotMatrixId = "@riot-bot:matrix.org"
        static let createRiotBotDMRequestMaxNumberOfTries: UInt = UInt.max
    }
    
    // MARK: - Properties
    
    private let session: MXSession
    
    // MARK: - Setup & Teardown
    
    @objc public init(session: MXSession) {
        self.session = session
        
        super.init()
    }
    
    // MARK: - Public
    
    @objc public func createRiotBotDirectMessageIfNeeded(success: (() -> Void)?, failure: ((Error) -> Void)?) {
        
        // Check user has joined no rooms so is a new comer
        guard self.isUserJoinedARoom() == false else {
            // As the user has already rooms, one of their riot client has already created a room with riot bot
            success?()
            return
        }
        
//        // Create DM room with Riot-bot
//        
//        let httpOperation = self.session.createRoom(name: nil, visibility: .private, alias: nil, topic: nil, invite: [Constants.riotBotMatrixId], invite3PID: nil, isDirect: true, preset: .trustedPrivateChat) { (response) in
//            
//            switch response {
//            case .success(_):
//                success?()
//            case .failure(let error):
//                NSLog("[OnBoardingManager] Create chat with riot-bot failed");
//                failure?(error)
//            }
//        }
//        
//        // Make multipe tries, until we get a response
//        httpOperation.maxNumberOfTries = Constants.createRiotBotDMRequestMaxNumberOfTries

        
        // Create DM room with Riot-bot

        let httpOperation = self.session.createRoom(fromSwift: nil, visibility: kMXRoomDirectoryVisibilityPrivate, roomAlias: nil, topic: nil, invite: [Constants.riotBotMatrixId], invite3PID: nil, isDirect: true, preset: kMXRoomPresetTrustedPrivateChat, success: success, failure: nil)


        // Make multipe tries, until we get a response
        httpOperation?.maxNumberOfTries = Constants.createRiotBotDMRequestMaxNumberOfTries
    }
    
    // MARK: - Private
    
    private func isUserJoinedARoom() -> Bool {
        guard let roomSummaries = self.session.roomsSummaries() else {
            return false
        }
        
        var isUSerJoinedARoom = false
        
        for roomSummary in roomSummaries {
            // if case .join = roomSummary.membership {
            if case __MXMembershipJoin = roomSummary.membershipFromSwift {
                isUSerJoinedARoom = true
                break
            }
        }

        return isUSerJoinedARoom
    }
}
