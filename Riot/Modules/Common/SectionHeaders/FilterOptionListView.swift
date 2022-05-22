// 
// Copyright 2022 New Vector Ltd
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

class FilterOptionListView: UIView, Themable {
    // MARK: - Private
    
    private var stackView: UIStackView!
    
    // MARK: - Properties
    
    var filterViews: [FilterOptionView] = [] {
        didSet {
            stackView.vc_removeAllArrangedSubviews()
            
            for filterView in filterViews {
                stackView.addArrangedSubview(filterView)
            }
        }
    }

    // MARK: - Setup
    
    override init(frame: CGRect) {
        super .init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.navigation
        
        for filterView in filterViews {
            filterView.update(theme: theme)
        }
    }
    
    // MARK: - Private
    
    private func setupView() {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.backgroundColor = .clear
        
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16).isActive = true
        
        vc_addSubViewMatchingParent(scrollView)
        
        self.stackView = stackView
        
        self.update(theme: ThemeService.shared().theme)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.themeDidChange), name: Notification.Name.themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
}
