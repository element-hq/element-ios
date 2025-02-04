// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

struct DirectoryNetworkVM {
    var title: String?
}

@objc protocol DirectoryNetworkTableHeaderFooterViewDelegate: NSObjectProtocol {
    func directoryNetworkTableHeaderFooterViewDidTapSwitch(_ view: DirectoryNetworkTableHeaderFooterView)
}

class DirectoryNetworkTableHeaderFooterView: UITableViewHeaderFooterView {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var switchButton: UIButton! {
        didSet {
            switchButton.setTitle(VectorL10n.switch, for: .normal)
        }
    }
    @IBOutlet private weak var separatorView: UIView!
    
    weak var delegate: DirectoryNetworkTableHeaderFooterViewDelegate?

    func configure(withViewModel viewModel: DirectoryNetworkVM) {
        titleLabel.text = viewModel.title
    }
    
    @IBAction private func switchButtonTapped(_ sender: UIButton) {
        delegate?.directoryNetworkTableHeaderFooterViewDidTapSwitch(self)
    }
}

extension DirectoryNetworkTableHeaderFooterView: NibReusable {}

extension DirectoryNetworkTableHeaderFooterView: Themable {
    
    func update(theme: Theme) {
        //  bg
        let view = UIView()
        view.backgroundColor = theme.backgroundColor
        backgroundView = view
        
        titleLabel.textColor = theme.textSecondaryColor
        theme.applyStyle(onButton: switchButton)
        separatorView.backgroundColor = theme.lineBreakColor
    }
    
}
