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
import Reusable
import MatrixSDK

@objcMembers
class FilterOptionViewCell: UICollectionViewCell, Themable {
    
    // MARK: - Private
    
    private var backgroundLayer: CAShapeLayer!
    
    @IBOutlet private var imageView: UIImageView?
    @IBOutlet private var label: UILabel?
    
    // MARK: - Properties
    
    var data: AllChatLayoutEditorFilter? {
        didSet {
            guard let data = data else {
                imageView?.image = nil
                label?.text = nil
                return
            }
            
            imageView?.image = data.image.withRenderingMode(.alwaysTemplate)
            label?.text = data.name
            isSelected = data.selected
        }
    }
    
    override var isSelected: Bool {
        didSet {
            update(theme: ThemeService.shared().theme)
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            update(theme: ThemeService.shared().theme)
        }
    }
    
    // MARK: - Setup
    
    static var nib: UINib {
      return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }

    static func loadFromNib() -> Self {
      guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
        fatalError("The nib \(nib) expected its root view to be of type \(self)")
      }
      return view
    }

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
        
        backgroundLayer.path = UIBezierPath(roundedRect: bounds.inset(by: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)), cornerRadius: bounds.height / 2).cgPath
        update(theme: ThemeService.shared().theme)
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        label?.font = theme.fonts.callout
        
        if isHighlighted {
            self.alpha = 0.3
        } else if isSelected {
            backgroundLayer.strokeColor = theme.colors.accent.cgColor
            backgroundLayer.fillColor = theme.colors.background.cgColor
            imageView?.tintColor = theme.colors.accent
            label?.textColor = theme.colors.accent
        } else {
            backgroundLayer.strokeColor = UIColor.clear.cgColor
            backgroundLayer.fillColor = theme.colors.system.cgColor
            imageView?.tintColor = theme.colors.primaryContent
            label?.textColor = theme.colors.primaryContent
        }
    }
    
    // MARK: - Private
    
    func setupView() {
        self.backgroundColor = .clear
        
        backgroundLayer = CAShapeLayer()
        backgroundLayer.lineWidth = 2
        layer.insertSublayer(backgroundLayer, at: 0)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
//        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
    }
    
    func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        // handling code
        MXLog.debug("[FilterOptionViewCell] handleTap: \(sender?.state)")
        self.isHighlighted = sender?.state == .began
        
        if sender?.state == .ended {
            self.isSelected = !self.isSelected
        }
    }
}
