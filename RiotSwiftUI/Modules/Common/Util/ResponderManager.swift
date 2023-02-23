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

import UIKit

/// `ResponderManager` is used to chain `SwiftUI` text editing views that embed `UIKit` text editing views using `UIViewRepresentable`
class ResponderManager {
    private static var tagIndex = 1000
    private static var registeredResponders = NSMapTable<NSNumber, UIView>(keyOptions: .strongMemory, valueOptions: .weakMemory)

    private static var nextIndex: Int {
        tagIndex += 1
        return tagIndex
    }
    
    private static var firstResponder: UIView? {
        guard let enumerator = registeredResponders.objectEnumerator() else {
            return nil
        }
        
        while let view: UIView = enumerator.nextObject() as? UIView {
            if view.isFirstResponder {
                return view
            }
        }
        
        return nil
    }
    
    /// register the `UIKit` view as a responder
    ///
    /// - Parameters:
    ///     - view: view to be registered
    static func register(view: UIView) {
        if registeredResponders.object(forKey: NSNumber(value: view.tag)) == nil {
            view.tag = nextIndex
            registeredResponders.setObject(view, forKey: NSNumber(value: view.tag))
        }
    }
    
    /// Unregister the `UIKit` view from this manager. The view won't be considered as potential next responder anymore
    ///
    /// - Parameters:
    ///     - view: view to be unregistered
    static func unregister(view: UIView) {
        registeredResponders.removeObject(forKey: NSNumber(value: view.tag))
    }
    
    /// Tries to get the focused registered responder and give the focus to it's next responder
    /// - Returns: `True` if the next responder has been found and is successfully focused. `False` otherwise.
    static func makeActiveNextResponder() -> Bool {
        guard let firstResponder = firstResponder else {
            return false
        }
        
        return makeActiveNextResponder(of: firstResponder)
    }
    
    /// Give the focus to the next responder f the given `UIKit` view
    ///
    /// - Parameters:
    ///     - view: base view
    ///
    /// - Returns: `True` if the next responder has been found and is successfully focused. `False` otherwise.
    static func makeActiveNextResponder(of view: UIView) -> Bool {
        let nextTag = view.tag + 1
        guard let nextResponder = registeredResponders.object(forKey: NSNumber(value: nextTag)) else {
            return false
        }
        
        nextResponder.becomeFirstResponder()
        return true
    }
    
    /// Unfocus any focused registered view.
    static func resignFirstResponder() {
        firstResponder?.resignFirstResponder()
    }
}
