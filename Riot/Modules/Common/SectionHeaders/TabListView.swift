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

protocol TabListViewDelegate: AnyObject {
    func tabListView(_ tabListView: TabListView, didSelectTabAt index: Int)
}

class TabListView: UIView {
    
    // MARK: - Constants
    
    enum Constants {
        static let cursorHeight: Double = 3
        static let itemSpacing: Double = 30
        static let cursorPadding: Double = 6
    }
    
    // MARK: - Item definition
    
    class Item {
        let id: Any
        let text: String?
        let icon: UIImage?
        
        init(id: Any = UUID().uuidString,
             text: String? = nil,
             icon: UIImage? = nil) {
            self.id = id
            self.text = text
            self.icon = icon
        }
    }

    // MARK: - Properties
    
    weak var delegate: TabListViewDelegate?
    var items: [Item] = [] {
        didSet {
            populateItemViews()
        }
    }
    var pageIndex: Double = 0 {
        didSet {
            updateCursor()
        }
    }
    var unselectedItemColor: UIColor = .lightGray {
        didSet {
            updateCursor()
        }
    }
    var itemFont: UIFont = .preferredFont(forTextStyle: .body) {
        didSet {
            for button in itemViews {
                button.titleLabel?.font = itemFont
            }
        }
    }
    
    // MARK: - Private
    
    private var itemViews: [UIButton] = []
    private let scrollView = UIScrollView(frame: .zero)
    private let cursorView = UIView(frame: .zero)
    private let itemsContentView = UIStackView(frame: .zero)

    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        itemsContentView.layoutIfNeeded()
        updateCursor()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        self.cursorView.backgroundColor = tintColor
        updateCursor()
    }
    
    // MARK: - Public
    
    func setPageIndex(_ pageIndex: Double, animated: Bool) {
        if !animated {
            self.pageIndex = pageIndex
        } else {
            UIView.animate(withDuration: 0.3) {
                self.pageIndex = pageIndex
            }
        }
    }

    // MARK: - Actions
    
    @objc private func tabAction(sender: UIButton) {
        delegate?.tabListView(self, didSelectTabAt: sender.tag)
    }

    // MARK: - Private
    
    private func setupView() {
        scrollView.backgroundColor = .clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true

        itemsContentView.backgroundColor = .clear
        itemsContentView.axis = .horizontal
        itemsContentView.distribution = .fillProportionally
        itemsContentView.alignment = .center
        itemsContentView.spacing = 0
        
        scrollView.addSubview(itemsContentView)

        itemsContentView.translatesAutoresizingMaskIntoConstraints = false
        itemsContentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor).isActive = true
        itemsContentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor).isActive = true
        itemsContentView.centerYAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerYAnchor).isActive = true
        itemsContentView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true

        cursorView.backgroundColor = tintColor
        cursorView.isUserInteractionEnabled = false
        cursorView.layer.masksToBounds = true

        scrollView.addSubview(cursorView)
    }
    
    private func populateItemViews() {
        for view in itemViews {
            itemsContentView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        var itemViews: [UIButton] = []
        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.titleLabel?.font = itemFont
            button.setTitle(item.text, for: .normal)
            button.setImage(item.icon?.withRenderingMode(.alwaysTemplate), for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: Constants.itemSpacing / 2, bottom: 0, right: Constants.itemSpacing / 2)
            button.tag = index
            button.tintColor = unselectedItemColor
            button.addTarget(self, action: #selector(tabAction(sender:)), for: .touchUpInside)
            
            itemViews.append(button)
            itemsContentView.addArrangedSubview(button)
        }
        
        self.itemViews = itemViews
        itemsContentView.layoutIfNeeded()
        setNeedsLayout()
    }

    private func updateCursor() {
        var integral: Double = 0
        let fractional: Double = modf(pageIndex, &integral)
        
        guard Int(integral) < itemViews.count else {
            return
        }
        
        let focusedButton = itemViews[Int(integral)]
        let nextButtonIndex = Int(integral) + 1
        
        let x: CGFloat
        let width: CGFloat
        let focusedButtonFrame: CGRect = titleLabelFrame(with: focusedButton).insetBy(dx: -Constants.cursorPadding, dy: 0)
        if nextButtonIndex < itemViews.count {
            let nextButtonFrame = titleLabelFrame(with: itemViews[nextButtonIndex]).insetBy(dx: -Constants.cursorPadding, dy: 0)
            x = focusedButtonFrame.minX + (nextButtonFrame.minX - focusedButtonFrame.minX) * fractional
            width = focusedButtonFrame.width + (nextButtonFrame.width - focusedButtonFrame.width) * fractional
        } else {
            x = focusedButtonFrame.minX
            width = focusedButtonFrame.width
        }
        
        cursorView.frame = CGRect(x: x,
                                  y: bounds.height - Constants.cursorHeight,
                                  width: width,
                                  height: Constants.cursorHeight)
        cursorView.layer.cornerRadius = cursorView.bounds.height / 2
        
        for button in self.itemViews {
            if button == focusedButton {
                button.tintColor = self.tintColor
            } else {
                button.tintColor = self.unselectedItemColor
            }
        }
    }
    
    private func titleLabelFrame(with button: UIButton) -> CGRect {
        guard let titleLabel = button.titleLabel else {
            return button.frame
        }
        
        return CGRect(x: button.frame.minX + titleLabel.frame.minX,
                      y: button.frame.minY + titleLabel.frame.minY,
                      width: titleLabel.frame.width,
                      height: titleLabel.frame.height)
    }

}
