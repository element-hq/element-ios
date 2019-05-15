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

import UIKit
import Reusable

final class ReactionsMenuView: UIView, NibOwnerLoadable {

    // MARK: - Properties

    // MARK: Outlets

    // MARK: Private

    //private var strengthViews: [UIView] = []

    // MARK: Public

    var viewModel: ReactionsMenuViewModelType? {
        didSet {
            self.updateView()
            self.viewModel?.viewDelegate = self
        }
    }

    // MARK: - Setup

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }

    // MARK: - Private

    private func updateView() {
        guard let viewModel = self.viewModel else {
            return
        }
    }
}

extension ReactionsMenuView: ReactionsMenuViewModelDelegate {
    func reactionsMenuViewModelDidUpdate(_ viewModel: ReactionsMenuViewModelType) {
        self.updateView()
    }
}
