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

import UIKit

protocol SplitViewMasterPresentableDelegate: class {
    func splitViewMasterPresentable(_ presentable: Presentable, wantsToDisplay detailPresentable: Presentable)
}

/// Protocol used by the master view presentable of a UISplitViewController
protocol SplitViewMasterPresentable: class, Presentable {
        
    var splitViewMasterPresentableDelegate: SplitViewMasterPresentableDelegate? { get set }
    
    /// Indicate true if the detail can be collapsed
    var collapseDetailViewController: Bool { get }
    
    /// Return the detail view controller to display when the detail is separated from the master view controller
    func secondViewControllerWhenSeparatedFromPrimary() -> UIViewController?
}
