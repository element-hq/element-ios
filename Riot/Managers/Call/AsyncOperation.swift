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

class AsyncOperation: Operation {
    @objc private enum State: Int {
        case ready
        case executing
        case finished
    }
    
    private var _state: State = .ready
    private let stateQueue = DispatchQueue(label: "AsyncOpStateQueue_\(String.vc_unique)",
                                           attributes: .concurrent)
    
    @objc private dynamic var state: State {
        get {
            stateQueue.sync {
                _state
            }
        } set {
            stateQueue.sync(flags: .barrier) {
                _state = newValue
            }
        }
    }
    
    override var isAsynchronous: Bool {
        true
    }
    
    override var isReady: Bool {
        super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        state == .executing
    }
    
    override var isFinished: Bool {
        state == .finished
    }
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        state = .executing
        main()
    }
    
    override func main() {
        fatalError("Subclasses must implement `main` without calling super.")
    }
    
    @objc class var keyPathsForValuesAffectingIsReady: Set<String> {
        [#keyPath(state)]
    }
    
    @objc class var keyPathsForValuesAffectingIsExecuting: Set<String> {
        [#keyPath(state)]
    }
    
    @objc class var keyPathsForValuesAffectingIsFinished: Set<String> {
        [#keyPath(state)]
    }
    
    func finish() {
        if isExecuting {
            state = .finished
        }
    }
}
