// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

class LaunchLoadingViewController: UIViewController, Reusable {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init(startupProgress: MXSessionStartupProgress?) {
        super.init(nibName: "LaunchLoadingViewController", bundle: nil)
        
        let launchLoadingView = LaunchLoadingView.instantiate(startupProgress: startupProgress)
        launchLoadingView.update(theme: ThemeService.shared().theme)
        view.vc_addSubViewMatchingParent(launchLoadingView)
        
        // The launch time isn't profiled for analytics as it's presentation length
        // will be artificially changed based on other views in the flow.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
