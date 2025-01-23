// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class AllChatsFilterOptionListView: UIView, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let separatorHeight: Double = 1
    }
    
    // MARK: - Option definition
    
    class Option {
        let type: AllChatsLayoutFilterType
        let name: String
        
        init(type: AllChatsLayoutFilterType,
             name: String) {
            self.type = type
            self.name = name
        }
        
        fileprivate var tabListItem: TabListView.Item {
            TabListView.Item(id: type, text: name)
        }
        
        fileprivate static func optionType(with tabListViewItem: TabListView.Item) -> AllChatsLayoutFilterType? {
            return tabListViewItem.id as? AllChatsLayoutFilterType
        }
    }
    
    // MARK: - Private
    
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    private let separator = UIView()
    private let tabListView = TabListView()
    
    // MARK: - Properties
    
    var options: [AllChatsFilterOptionListView.Option] = [] {
        didSet {
            tabListView.items = options.map { $0.tabListItem }
        }
    }
    var selectionChanged: ((AllChatsLayoutFilterType) -> Void)?
    var selectedOptionType: AllChatsLayoutFilterType = .all {
        didSet {
            for (index, option) in options.enumerated() where option.type == selectedOptionType {
                tabListView.pageIndex = Double(index)
            }
        }
    }

    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Public
    
    func setSelectedOptionType(_ optionType: AllChatsLayoutFilterType, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.3 : 0) {
            self.selectedOptionType = optionType
        }
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.background.withAlphaComponent(0.7)
        
        tabListView.itemFont = theme.fonts.calloutSB
        tabListView.tintColor = theme.colors.accent
        tabListView.unselectedItemColor = theme.colors.tertiaryContent
        
        separator.backgroundColor = theme.colors.system
    }
    
    // MARK: - Private
    
    private func setupView() {
        vc_addSubViewMatchingParent(backgroundView)
        
        addSubview(separator)
        
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.bottomAnchor.constraint(equalTo: self.bottomAnchor,
                                          constant: -(TabListView.Constants.cursorHeight - Constants.separatorHeight) / 2).isActive = true
        separator.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        separator.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: Constants.separatorHeight).isActive = true

        tabListView.delegate = self
        vc_addSubViewMatchingParent(tabListView)
        
        self.update(theme: ThemeService.shared().theme)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.themeDidChange), name: Notification.Name.themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
}

// MARK: - TabListViewDelegate
extension AllChatsFilterOptionListView: TabListViewDelegate {
    
    func tabListView(_ tabListView: TabListView, didSelectTabAt index: Int) {
        guard let optionType = AllChatsFilterOptionListView.Option.optionType(with: tabListView.items[index]) else {
            return
        }
        
        self.setSelectedOptionType(optionType, animated: true)
        selectionChanged?(optionType)
    }
    
}
