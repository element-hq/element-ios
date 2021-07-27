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

/**
 Object container storing references weakly. Ideal for implementing simple multiple delegation.
 */
struct DelegateContainer {
    
    private let hashTable: NSHashTable<AnyObject>
    
    var delegates: [AnyObject] {
        return hashTable.allObjects
    }
    
    init() {
        hashTable = NSHashTable(options: .weakMemory)
    }
    
    func registerDelegate(_ delegate: AnyObject) {
        hashTable.add(delegate)
    }
    
    func deregisterDelegate(_ delegate: AnyObject) {
        hashTable.remove(delegate)
    }
    
    func notifyDelegatesWithBlock(_ block: (AnyObject) -> Void) {
        for delegate in hashTable.allObjects {
            block(delegate)
        }
    }
}
