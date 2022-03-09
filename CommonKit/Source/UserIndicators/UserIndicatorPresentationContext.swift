// 
// Copyright 2022 New Vector Ltd
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
