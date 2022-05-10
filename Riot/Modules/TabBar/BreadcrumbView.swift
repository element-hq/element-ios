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

import Foundation
import UIKit

/// `BreadcrumbView` can be used to display a path into a  single line of text and manages ellipsis.
@objcMembers
class BreadcrumbView: UIView, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let separator: String = "/"
    }
    
    // MARK: - Properties
    
    public var breadcrumbs: [String] = [] {
        didSet {
            populateLabels()
        }
    }
    
    // MARK: - Private
    
    private var labels: [UILabel] = []
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        for label in labels {
            update(theme: theme, for: label)
        }
    }
    
    // MARK: - Private
    
    private func populateLabels() {
        for label in labels {
            label.removeFromSuperview()
        }
        
        labels.removeAll()

        for (index, breadcrumb) in breadcrumbs.enumerated() {
            if index > 0 {
                createLabel(with: Constants.separator, at: index)
            }
            createLabel(with: breadcrumb, at: index)
        }
        self.layoutIfNeeded()
    }
    
    private func createLabel(with text: String?, at index: Int) {
        guard let text = text, !text.isEmpty else {
            return
        }
        
        let label = UILabel(frame: .zero)
        label.backgroundColor = .clear
        label.text = text
        let priority: UILayoutPriority
        if index < breadcrumbs.count - 1 {
            // We put a higher priority to the first element then decrease the priority linearly for the next elements.
            priority = UILayoutPriority(UILayoutPriority.defaultLow.rawValue + Float(breadcrumbs.count * 2 - labels.count))
        } else {
            // The last element has the highest priority
            priority = .defaultHigh
        }
        label.setContentCompressionResistancePriority(priority, for: .horizontal)
        
        update(theme: ThemeService.shared().theme, for: label)

        self.addSubview(label)
        self.labels.append(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        if let prevSibling = prevSibling(of: label) {
            label.leadingAnchor.constraint(equalTo: prevSibling.trailingAnchor).isActive = true
        } else {
            label.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor).isActive = true
        }
        
        if index == breadcrumbs.count - 1 && label.text != Constants.separator {
            label.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor).isActive = true
        }
    }
    
    private func prevSibling(of label: UILabel) -> UILabel? {
        guard let index = labels.firstIndex(of: label), index - 1 >= 0 else {
            return nil
        }
        
        return labels[index-1]
    }
    
    private func update(theme: Theme, for label: UILabel) {
        label.textColor = theme.colors.tertiaryContent
        label.font = theme.fonts.footnote
    }
}
