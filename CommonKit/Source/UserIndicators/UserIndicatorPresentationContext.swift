// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

/// The presentation context is used by `UserIndicatorViewPresentable`s to display content
/// on the screen and it serves two primary purposes:
///
/// - abstraction on top of UIKit (passing context instead of view controllers)
/// - immutable context passed at init with variable presenting view controller
///   (e.g. depending on collapsed / uncollapsed iPad presentation that changes
///   at runtime)
public protocol UserIndicatorPresentationContext {
    var indicatorPresentingViewController: UIViewController? { get }
}

/// A simple implementation of `UserIndicatorPresentationContext` that uses a weak reference
/// to the passed-in view controller as the presentation context.
public class StaticUserIndicatorPresentationContext: UserIndicatorPresentationContext {
    // The presenting view controller will be the parent of the user indicator,
    // and the indicator holds a strong reference to the context, so the view controller
    // must be decleared `weak` to avoid a retain cycle
    public private(set) weak var indicatorPresentingViewController: UIViewController?
    
    public init(viewController: UIViewController) {
        self.indicatorPresentingViewController = viewController
    }
}
