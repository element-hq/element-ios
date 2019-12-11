/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/// Empty view controller used to embed a view conforming to `SlidingModalPresentable`.
final class SlidingModalEmptyViewController: UIViewController {
    
    // MARK: - Properties
    
    private var modalView: SlidingModalPresentable.ViewType!
    
    // MARK: - Setup
    
    static func instantiate(with view: SlidingModalPresentable.ViewType) -> SlidingModalEmptyViewController {
        let viewController = SlidingModalEmptyViewController()
        viewController.modalView = view
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func loadView() {
        self.view = self.modalView
    }
}

// MARK: - SlidingModalPresentable
extension SlidingModalEmptyViewController: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return self.modalView.allowsDismissOnBackgroundTap()
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        return self.modalView.layoutHeightFittingWidth(width)
    }
}
