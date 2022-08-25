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
        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.bodySB
        
        detailLabel.textColor = theme.colors.secondaryContent
        detailLabel.font = theme.fonts.callout
    }
    
    // MARK: - Private
    
    private func setupView() {
        titleLabel = UILabel(frame: .zero)
        titleLabel.backgroundColor = .clear
        titleLabel.numberOfLines = 0

        detailLabel = UILabel(frame: .zero)
        detailLabel.backgroundColor = .clear
        detailLabel.numberOfLines = 0

        addArrangedSubview(titleLabel)
        addArrangedSubview(detailLabel)
        distribution = .equalSpacing
        axis = .vertical
        alignment = .leading
        spacing = 8
    }
}
