/*
 Copyright 2019 New Vector Ltd
 
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

/// CoordinatorDelegateQueuable describe a protocol used by view models to handle coordinator delegation in an operation queue.
protocol CoordinatorDelegateQueuable {
    
    var coordinatorDelegateQueue: OperationQueue { get }
    
    func pauseCoordinatorOperations()
    func resumeCoordinatorOperations()
    func cancelCoordinatorOperations()
}

extension CoordinatorDelegateQueuable {
    
    static func createCoordinatorDelegateQueue() -> OperationQueue {
        let coordinatorDelegateQueue = OperationQueue()
        coordinatorDelegateQueue.name = "\(String(describing: self)).coordinatorDelegateQueue"
        coordinatorDelegateQueue.maxConcurrentOperationCount = 1
        return coordinatorDelegateQueue
    }
    
    func pauseCoordinatorOperations() {
        self.coordinatorDelegateQueue.isSuspended = true
    }
    
    func resumeCoordinatorOperations() {
        self.coordinatorDelegateQueue.isSuspended = false
    }
    
    func cancelCoordinatorOperations() {
        self.coordinatorDelegateQueue.cancelAllOperations()
    }
}
