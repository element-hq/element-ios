// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
