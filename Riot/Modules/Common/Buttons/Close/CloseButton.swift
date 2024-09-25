/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation

final class CloseButton: UIButton, Themable {
    
    // MARK: - Constants
    
    private enum CircleBackgroundConstants {
        static let height: CGFloat = 26.0
        static let highlightedAlha: CGFloat = 0.5
        static let normalAlha: CGFloat = 0.8
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var theme: Theme?
    
    private var circleBackgroundView: UIView!
    
    // MARK: Public
    
    override var isHighlighted: Bool {
        didSet {
            self.circleBackgroundView.alpha = self.isHighlighted ? CircleBackgroundConstants.highlightedAlha : CircleBackgroundConstants.normalAlha
        }
    }
    
    // MARK: - Life cycle
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.backgroundColor = UIColor.clear
        self.setImage(Asset.Images.closeButton.image, for: .normal)
        self.setupCircleView()
        
        self.update(theme: ThemeService.shared().theme)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.sendSubviewToBack(self.circleBackgroundView)
        self.circleBackgroundView.layer.cornerRadius = self.circleBackgroundView.bounds.height/2
    }
    
    // MARK: - Private
    
    private func setupCircleView() {
        
        //  sanity check
        if circleBackgroundView != nil {
            //  already set up
            return
        }
        
        let rect = CGRect(x: 0, y: 0, width: CircleBackgroundConstants.height, height: CircleBackgroundConstants.height)
        let view = UIView(frame: rect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.layer.masksToBounds = true
        
        self.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: CircleBackgroundConstants.height),
            view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0),
            view.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
        
        self.sendSubviewToBack(view)
        
        self.circleBackgroundView = view
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.circleBackgroundView.backgroundColor = theme.secondaryCircleButtonBackgroundColor
    }
}
