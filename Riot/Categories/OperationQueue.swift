/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

extension OperationQueue {
    
    class func vc_createSerialOperationQueue(name: String? = nil) -> OperationQueue {
        let coordinatorDelegateQueue = OperationQueue()
        coordinatorDelegateQueue.name = name
        coordinatorDelegateQueue.maxConcurrentOperationCount = 1
        return coordinatorDelegateQueue
    }
    
    func vc_pause() {
        self.isSuspended = true
    }
    
    func vc_resume() {
        self.isSuspended = false
    }
}
