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
