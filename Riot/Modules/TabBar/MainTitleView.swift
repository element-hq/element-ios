// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objcMembers
class MainTitleView: UIStackView, Themable {
    
    // MARK: - Properties
    
    public private(set) var titleLabel: UILabel!
    public private(set) var breadcrumbView: BreadcrumbView!
    
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
        self.titleLabel.font = theme.fonts.calloutSB
        
        self.breadcrumbView.update(theme: theme)
    }
    
    // MARK: - Private
    
    private func setupView() {
        self.titleLabel = UILabel(frame: .zero)
        self.titleLabel.backgroundColor = .clear

        self.breadcrumbView = BreadcrumbView(frame: .zero)

        self.addArrangedSubview(titleLabel)
        self.addArrangedSubview(breadcrumbView)
        self.distribution = .equalCentering
        self.axis = .vertical
        self.alignment = .center
        self.spacing = 0.5
    }
}
