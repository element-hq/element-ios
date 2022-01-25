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

        // Check first that the user homeserver is federated with the  Riot-bot homeserver
        self.session.matrixRestClient.avatarUrl(forUser: Constants.riotBotMatrixId) { (response) in

            switch response {
            case .success:

                // Create DM room with Riot-bot
                let roomCreationParameters = MXRoomCreationParameters(forDirectRoomWithUser: Constants.riotBotMatrixId)
                let httpOperation = self.session.createRoom(parameters: roomCreationParameters) { (response) in

                    switch response {
                    case .success:
                        success?()
                    case .failure(let error):
                        MXLog.debug("[OnBoardingManager] Create chat with riot-bot failed")
                        failure?(error)
                    }
                }

                // Make multipe tries, until we get a response
                httpOperation.maxNumberOfTries = Constants.createRiotBotDMRequestMaxNumberOfTries

            case .failure(let error):
                MXLog.debug("[OnBoardingManager] riot-bot is unknown or the user hs is non federated. Do not try to create a room with riot-bot")
                failure?(error)
            }
        }
    }
    
    // MARK: - Private
    
    private func isUserJoinedARoom() -> Bool {
        var isUserJoinedARoom = false
        
        for room in session.rooms {
            guard let roomSummary = room.summary else {
                continue
            }
            if case .join = roomSummary.membership {
                isUserJoinedARoom = true
                break
            }
        }

        return isUserJoinedARoom
    }
}
