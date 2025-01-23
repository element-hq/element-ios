//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
