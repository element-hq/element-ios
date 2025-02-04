// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
            return stateQueue.sync {
                _state
            }
        } set {
            stateQueue.sync(flags: .barrier) {
                _state = newValue
            }
        }
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        self.state = .executing
        main()
    }
    
    override func main() {
        fatalError("Subclasses must implement `main` without calling super.")
    }
    
    @objc class var keyPathsForValuesAffectingIsReady: Set<String> {
        return [#keyPath(state)]
    }
    
    @objc class var keyPathsForValuesAffectingIsExecuting: Set<String> {
        return [#keyPath(state)]
    }
    
    @objc class var keyPathsForValuesAffectingIsFinished: Set<String> {
        return [#keyPath(state)]
    }
    
    func finish() {
        if isExecuting {
            self.state = .finished
        }
    }
    
}
