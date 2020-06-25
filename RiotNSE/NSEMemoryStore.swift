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

//  error domain
let NSEMemoryStoreErrorDomain: String = "NSEMemoryStoreErrorDomain"

//  error codes
enum NSEMemoryStoreErrorCode: Int {
    case userIDMissing = 1001   // User ID is missing in credentials
}

/// Fake memory store implementation. Uses some real values from an MXFileStore instance.
class NSEMemoryStore: MXMemoryStore {

    //  In-memory value for eventStreamToken. Will be used as eventStreamToken if provided.
    private var lastStoredEventStreamToken: String?
    private var credentials: MXCredentials
    //  real store
    private var fileStore: MXFileStore!
    private var myUser: MXUser?
    
    init(withCredentials credentials: MXCredentials) {
        self.credentials = credentials
        if fileStore == nil {
            fileStore = MXFileStore(credentials: credentials)
            //  load real eventStreamToken
            fileStore.loadMetaData()
        }
    }
    
    override func open(with credentials: MXCredentials, onComplete: (() -> Void)?, failure: ((Error?) -> Void)? = nil) {
        super.open(with: credentials, onComplete: {
            guard let userId = credentials.userId else {
                failure?(NSError(domain: NSEMemoryStoreErrorDomain,
                                 code: NSEMemoryStoreErrorCode.userIDMissing.rawValue,
                                 userInfo: nil))
                return
            }
            //  load session user before calling onComplete
            self.fileStore.asyncUsers(withUserIds: [userId], success: { (users) in
                if let user = users.first {
                    self.myUser = user
                }
                onComplete?()
            }, failure: failure)
        }, failure: failure)
    }
    
    //  Return real eventStreamToken, to be able to launch a meaningful background sync
    override var eventStreamToken: String? {
        get {
            //  if more up-to-date token exists, use it
            if let token = lastStoredEventStreamToken {
                return token
            }
            return fileStore.eventStreamToken
        } set {
            //  store new token values in memory, and return these values in future reads
            lastStoredEventStreamToken = newValue
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
        //  no-op
    }
    
    //  Fetch real room state
    override func state(ofRoom roomId: String, success: @escaping ([MXEvent]) -> Void, failure: ((Error) -> Void)? = nil) {
        fileStore.state(ofRoom: roomId, success: success, failure: failure)
    }
    
    //  Fetch real soom summary
    override func summary(ofRoom roomId: String) -> MXRoomSummary? {
        return fileStore.summary(ofRoom: roomId)
    }
    
    //  Fetch real room account data
    override func accountData(ofRoom roomId: String) -> MXRoomAccountData? {
        return fileStore.accountData(ofRoom: roomId)
    }
    
    //  Override and return a user to be stored on session.myUser
    override func user(withUserId userId: String) -> MXUser? {
        if userId == credentials.userId, let myUser = myUser {
            //  if asking for session user and myUser is set, return that
            return myUser
        }
        return MXUser(userId: userId)
    }
    
    override var syncFilterId: String? {
        get {
            let filter = MXFilterJSONModel()
            filter.room = MXRoomFilter()
            filter.room.rooms = []
            return filter.jsonString()
        } set {
            //  no-op
        }
    }
    
}
