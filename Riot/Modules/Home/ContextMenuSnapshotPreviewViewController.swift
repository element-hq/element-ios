// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
