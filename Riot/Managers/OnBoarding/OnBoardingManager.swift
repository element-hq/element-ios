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
    
    private var session: MXSession
    
    // MARK: - Setup & Teardown
    
    @objc init(session: MXSession) {
        self.session = session
        
        super.init()
    }
    
    // MARK: - Public
    
    @objc func createRiotBotDirectMessageIfNeeded(sucess: (() -> Void)?, failure: ((Error) -> Void)?) {
        
        // Check user has join no rooms so is a new comer
        guard self.isUSerJoinedARoom() == false else {
            return
        }
        
        // Create DM room with Riot-bot
        
        let httpOperation = self.session.createRoom(name: nil, visibility: .private, alias: nil, topic: nil, invite: [Constants.riotBotMatrixId], invite3PID: nil, isDirect: true, preset: .trustedPrivateChat) { (response) in
            
            switch response {
            case .success(_):
                sucess?()
            case .failure(let error):
                NSLog("[OnBoardingManager] Create chat with riot-bot failed with error \(error)");
                failure?(error)
            }
            
        }
        
        // Make multipe tries, until we get a response
        httpOperation.maxNumberOfTries = Constants.createRiotBotDMRequestMaxNumberOfTries
    }
    
    // MARK: - Private
    
    private func isUSerJoinedARoom() -> Bool {
        var isUSerJoinedARoom = false
        
        for roomSummary in self.session.roomsSummaries() {
            if case .join = roomSummary.membership {
                isUSerJoinedARoom = true
                break
            }
        }
        
        return isUSerJoinedARoom
    }
}
