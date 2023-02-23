// 
// Copyright 2021 New Vector Ltd
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
import UIKit

@objcMembers
public class ThreadDataSource: RoomDataSource {

    private typealias ThreadID = String

    /// Map of cached data sources. Keys are thread identifiers.
    private static var dataSourceCache: [ThreadID: ThreadDataSource] = [:]
    
    public override func finalizeInitialization() {
        super.finalizeInitialization()
        showReadMarker = true
        showBubbleReceipts = true
        showTypingRow = false

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didLeaveRoom(_:)),
                                               name: .mxSessionDidLeaveRoom,
                                               object: nil)
    }
    
    public override class func load(withRoomId roomId: String!,
                                    initialEventId: String!,
                                    threadId: String!,
                                    andMatrixSession mxSession: MXSession!,
                                    onComplete: ((Any?) -> Void)!) {
        if let dataSource = dataSourceCache[threadId] {
            onComplete(dataSource)
            return
        }
        super.load(withRoomId: roomId, initialEventId: initialEventId, threadId: threadId, andMatrixSession: mxSession) { dataSource in
            if let dataSource = dataSource as? ThreadDataSource {
                Self.dataSourceCache[threadId] = dataSource
            }
            onComplete(dataSource)
        }
    }

    @objc
    private func didReceiveMemoryWarning() {
        MXLog.debug("[ThreadDataSource] didReceiveMemoryWarning. Will reload not active data sources in cache.")

        Self.dataSourceCache.forEach {
            if $1.delegate == nil {
                $1.reload()
            }
        }
    }

    @objc
    private func didLeaveRoom(_ notification: Notification) {
        MXLog.debug("[ThreadDataSource] didReceiveMemoryWarning. Will reload not active data sources in cache.")

        guard let session = notification.object as? MXSession,
              session == mxSession,
              let roomId = notification.userInfo?[kMXSessionNotificationRoomIdKey] as? String else {
            return
        }

        let threadIds = Array(Self.dataSourceCache.filter { $1.roomId == roomId }.keys)
        threadIds.forEach { Self.dataSourceCache.removeValue(forKey: $0) }
    }
    
}
