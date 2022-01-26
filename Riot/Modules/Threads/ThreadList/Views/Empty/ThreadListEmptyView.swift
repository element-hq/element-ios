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

import Foundation
import Reusable

@objc
protocol ThreadListEmptyViewDelegate: AnyObject {
    func threadListEmptyViewTappedShowAllThreads(_ emptyView: ThreadListEmptyView)
}

/// View to be shown on the thread list screen when no thread is available. Use a `ThreadListEmptyModel` instance to configure.
class ThreadListEmptyView: UIView {
    
    @IBOutlet weak var delegate: ThreadListEmptyViewDelegate?
    
    @IBOutlet private weak var iconBackgroundView: UIView!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var tipLabel: UILabel!
    @IBOutlet private weak var showAllThreadsButton: UIButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadNibContent()
    }
    
    func configure(withModel model: ThreadListEmptyModel) {
        iconView.image = model.icon
        titleLabel.text = model.title
        infoLabel.text = model.info
        tipLabel.text = model.tip
        showAllThreadsButton.setTitle(model.showAllThreadsButtonTitle,
                                      for: .normal)
        showAllThreadsButton.isHidden = model.showAllThreadsButtonHidden
        
        titleLabel.isHidden = titleLabel.text?.isEmpty ?? true
        infoLabel.isHidden = infoLabel.text?.isEmpty ?? true
        tipLabel.isHidden = tipLabel.text?.isEmpty ?? true
    }
    
    @IBAction private func showAllThreadsButtonTapped(_ sender: UIButton) {
        delegate?.threadListEmptyViewTappedShowAllThreads(self)
    }
    
}

extension ThreadListEmptyView: NibOwnerLoadable {}

extension ThreadListEmptyView: Themable {
    
    func update(theme: Theme) {
        iconBackgroundView.backgroundColor = theme.colors.system
        iconView.tintColor = theme.colors.secondaryContent
        titleLabel.textColor = theme.colors.primaryContent
        infoLabel.textColor = theme.colors.secondaryContent
        tipLabel.textColor = theme.colors.secondaryContent
        showAllThreadsButton.tintColor = theme.colors.accent
    }
    
}
