// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class SearchEmptyView: UIStackView, Themable {
    
    // MARK: - Properties
    
    public private(set) var titleLabel: UILabel!
    public private(set) var detailLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.bodySB
        
        self.detailLabel.textColor = theme.colors.secondaryContent
        self.detailLabel.font = theme.fonts.callout
    }
    
    // MARK: - Private
    
    private func setupView() {
        self.titleLabel = UILabel(frame: .zero)
        self.titleLabel.backgroundColor = .clear
        self.titleLabel.numberOfLines = 0

        self.detailLabel = UILabel(frame: .zero)
        self.detailLabel.backgroundColor = .clear
        self.detailLabel.numberOfLines = 0

        self.addArrangedSubview(titleLabel)
        self.addArrangedSubview(detailLabel)
        self.distribution = .equalSpacing
        self.axis = .vertical
        self.alignment = .leading
        self.spacing = 8
    }
}
