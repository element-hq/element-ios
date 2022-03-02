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
import Reusable

class LaunchLoadingViewController: UIViewController, Reusable {
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    init() {
        super.init(nibName: "LaunchLoadingViewController", bundle: nil)
        
        let launchLoadingView = LaunchLoadingView.instantiate()
        launchLoadingView.update(theme: ThemeService.shared().theme)
        view.vc_addSubViewMatchingParent(launchLoadingView)
        
        // The launch time isn't profiled for analytics as it's presentation length
        // will be artificially changed based on other views in the flow.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
