// 
// Copyright 2020 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import MatrixSDK

@objc protocol SyncResponseStore: NSObjectProtocol {
    var syncResponse: MXSyncResponse? { get }
    func update(with response: MXSyncResponse?)
    func deleteData()
}

@objcMembers
class SyncResponseFileStore: NSObject {
    
    private enum SyncResponseFileStoreConstants {
        static let folderNname = "SyncResponse"
        static let fileName = "syncResponse.json"
        static let fileEncoding: String.Encoding = .utf8
        static let fileOperationQueue: DispatchQueue = .global(qos: .default)
    }
    private var filePath: URL!
    private var credentials: MXCredentials
    
    init(withCredentials credentials: MXCredentials) {
        self.credentials = credentials
        super.init()
        setupFilePath()
    }
    
    private func setupFilePath() {
        guard let userId = credentials.userId else {
            fatalError("Credentials must provide a user identifier")
        }
        var cachePath: URL!
        
        if let appGroupIdentifier = MXSDKOptions.sharedInstance().applicationGroupIdentifier {
            cachePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        } else {
            cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        }
        
        filePath = cachePath
            .appendingPathComponent(SyncResponseFileStoreConstants.folderNname)
            .appendingPathComponent(userId)
            .appendingPathComponent(SyncResponseFileStoreConstants.fileName)
        
        SyncResponseFileStoreConstants.fileOperationQueue.async {
            try? FileManager.default.createDirectory(at: self.filePath.deletingLastPathComponent(),
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        }
    }
    
    private func readSyncResponse() -> MXSyncResponse? {
        var fileContents: String?
        
        SyncResponseFileStoreConstants.fileOperationQueue.sync {
            fileContents = try? String(contentsOf: filePath,
                                       encoding: SyncResponseFileStoreConstants.fileEncoding)
        }
        guard let jsonString = fileContents else {
            return nil
        }
        guard let json = MXTools.deserialiseJSONString(jsonString) as? [AnyHashable: Any] else {
            return nil
        }
        return MXSyncResponse(fromJSON: json)
    }
    
    private func saveSyncResponse(_ syncResponse: MXSyncResponse?) {
        guard let syncResponse = syncResponse else {
            try? FileManager.default.removeItem(at: filePath)
            return
        }
        SyncResponseFileStoreConstants.fileOperationQueue.async {
            try? syncResponse.jsonString()?.write(to: self.filePath,
                                                  atomically: true,
                                                  encoding: SyncResponseFileStoreConstants.fileEncoding)
        }
    }
    
}

extension SyncResponseFileStore: SyncResponseStore {
    
    var syncResponse: MXSyncResponse? {
        return readSyncResponse()
    }
    
    func update(with response: MXSyncResponse?) {
        guard let response = response else {
            //  Return if no new response
            return
        }
        if let syncResponse = syncResponse {
            //  current sync response exists, merge it with the new response
            var dictionary = NSDictionary(dictionary: syncResponse.jsonDictionary())
            dictionary = dictionary + NSDictionary(dictionary: response.jsonDictionary())
            saveSyncResponse(MXSyncResponse(fromJSON: dictionary as? [AnyHashable : Any]))
        } else {
            //  no current sync response, directly save the new one
            saveSyncResponse(response)
        }
    }
    
    func deleteData() {
        saveSyncResponse(nil)
    }
    
}
