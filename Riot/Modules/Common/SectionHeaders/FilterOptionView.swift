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

@objcMembers
class FilterOptionView: UIView, Themable {
    
    // MARK: - Constants
    
    enum Constants {
        static let verticalPadding: CGFloat = 9
        static let horizontalPadding: CGFloat = 12
        static let animationDuration: TimeInterval = 0.1
    }
    
    // MARK: - Private
    
    private var backgroundLayer: CAShapeLayer!
    private var stackView: UIStackView!
    
    private weak var imageView: UIImageView?
    private weak var label: UILabel?
    
    // MARK: - Properties
    
    var isAll: Bool = false {
        didSet {
            if isAll {
                let label = UILabel()
                label.text = VectorL10n.allChatsAllFilter
                stackView.addArrangedSubview(label)
                self.label = label
                
                let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                self.isSelected = settings.activeFilters.isEmpty

                NotificationCenter.default.addObserver(forName: AllChatsLayoutSettings.didUpdateFilters, object: nil, queue: OperationQueue.main) { [weak self] notification in
                    guard let self = self, let settings = notification.object as? AllChatsLayoutSettings else {
                        return
                    }
                    
                    self.isSelected = settings.activeFilters.isEmpty
                }
            }
        }
    }
    
    var data: AllChatsLayoutEditorFilter? {
        didSet {
            for subView in stackView.arrangedSubviews {
                stackView.removeArrangedSubview(subView)
                subView.removeFromSuperview()
            }

            if let image = data?.image {
                let imageView = UIImageView(image: image.withRenderingMode(.alwaysTemplate))
                stackView.addArrangedSubview(imageView)
                imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
                imageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
                self.imageView = imageView
            }
            
            if let text = data?.name, !text.isEmpty {
                let label = UILabel()
                label.text = text
                stackView.addArrangedSubview(label)
                self.label = label
            }
            
            isSelected = data?.selected == true
            
            update(theme: ThemeService.shared().theme)
            
            NotificationCenter.default.addObserver(forName: AllChatsLayoutSettings.didUpdateFilters, object: nil, queue: OperationQueue.main) { [weak self] notification in
                guard let settings = notification.object as? AllChatsLayoutSettings, let data = self?.data else {
                    return
                }
                
                self?.isSelected = settings.activeFilters.contains(data.type)
            }
        }
    }
    
    var didTap: ((FilterOptionView) -> Void)?
    
    var isSelected: Bool = false {
        didSet {
            UIView.animate(withDuration: Constants.animationDuration) {
                self.update(theme: ThemeService.shared().theme)
            }
        }
    }
    
    var isHighlighted: Bool = false {
        didSet {
            UIView.animate(withDuration: Constants.animationDuration) {
                self.update(theme: ThemeService.shared().theme)
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
    
    // MARK: - Public
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundLayer.path = UIBezierPath(roundedRect: bounds.inset(by: UIEdgeInsets(top: 2, left: 2, bottom: 3, right: 2)), cornerRadius: bounds.height / 2).cgPath
        update(theme: ThemeService.shared().theme)
        
        self.layoutIfNeeded()
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        label?.font = theme.fonts.calloutSB
        
        if isHighlighted {
            self.alpha = 0.3
        } else if isSelected {
            backgroundLayer.strokeColor = theme.colors.accent.cgColor
            backgroundLayer.fillColor = theme.colors.background.cgColor
            imageView?.tintColor = theme.colors.accent
            label?.textColor = theme.colors.accent
        } else {
            backgroundLayer.strokeColor = UIColor.clear.cgColor
            backgroundLayer.fillColor = theme.colors.background.cgColor
            imageView?.tintColor = theme.colors.primaryContent
            label?.textColor = theme.colors.primaryContent
        }
    }
    
    // MARK: - Private
    
    func setupView() {
        self.backgroundColor = .clear
        self.translatesAutoresizingMaskIntoConstraints = false
        
        backgroundLayer = CAShapeLayer()
        backgroundLayer.lineWidth = 2
        layer.insertSublayer(backgroundLayer, at: 0)
        
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        self.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Constants.horizontalPadding).isActive = true
        stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: Constants.verticalPadding).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Constants.horizontalPadding).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Constants.verticalPadding).isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    func handleTap(_ sender: UIGestureRecognizer? = nil) {
        self.isHighlighted = (sender?.state == .began)
        
        if sender?.state == .ended {
            self.didTap?(self)
        }
    }
}
