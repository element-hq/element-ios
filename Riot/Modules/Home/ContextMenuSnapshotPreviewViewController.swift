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

/// A view controller that provides a preview for use in context menus.
/// The preview will display a snapshot of whichever view is passed into the init.
@objcMembers
class ContextMenuSnapshotPreviewViewController: UIViewController {
    
    // MARK: - Private
    
    private let snapshotView: UIView?
    
    // MARK: - Setup
    
    /// Creates a new preview by snapshotting the supplied view.
    /// - Parameter view: The view to use as a preview.
    init(view: UIView) {
        self.snapshotView = view.snapshotView(afterScreenUpdates: false)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let snapshotView = snapshotView else { return }
        view.vc_addSubViewMatchingParent(snapshotView)
        
        preferredContentSize = snapshotView.bounds.size
    }
    
}
