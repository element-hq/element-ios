/*
 Copyright 2020 New Vector Ltd
 
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
import MatrixSDK

class NSEMemoryStore: MXMemoryStore {

    private var credentials: MXCredentials
    private var fileStore: MXFileStore
    
    init(withCredentials credentials: MXCredentials) {
        self.credentials = credentials
        fileStore = MXFileStore(credentials: credentials)
        fileStore.loadMetaData()
    }
    
    //  Return real eventStreamToken, to be able to launch a meaningful background sync
    override var eventStreamToken: String? {
        get {
            return fileStore.eventStreamToken
        } set {
            //  no-op
        }
    }
    
    //  Return real userAccountData, to be able to use push rules
    override var userAccountData: [AnyHashable : Any]? {
        get {
            return fileStore.userAccountData
        } set {
            //  no-op
        }
    }
    
    //  This store should act like as a permanent one
    override var isPermanent: Bool {
        return true
    }
    
    //  Some mandatory methods to implement to be permanent
    override func storeState(forRoom roomId: String, stateEvents: [MXEvent]) {
        
    }
    
    override func state(ofRoom roomId: String, success: @escaping ([MXEvent]) -> Void, failure: ((Error) -> Void)? = nil) {
        
    }
    
    override func summary(ofRoom roomId: String) -> MXRoomSummary? {
        return fileStore.summary(ofRoom: roomId)
    }
    
    override func accountData(ofRoom roomId: String) -> MXRoomAccountData? {
        return fileStore.accountData(ofRoom: roomId)
    }
    
    //  Override and return a user to be stored on session.myUser
    override func user(withUserId userId: String) -> MXUser? {
        if userId == credentials.userId {
            return MXMyUser(userId: userId)
        }
        return MXUser(userId: userId)
    }
    
    override func close() {
        fileStore.close()
    }
    
}
