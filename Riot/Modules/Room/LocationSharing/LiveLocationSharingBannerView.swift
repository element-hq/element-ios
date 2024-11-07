// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Reusable
import UIKit

@objcMembers
final class LiveLocationSharingBannerView: UIView, NibLoadable, Themable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var stopButton: UIButton!
    
    // MARK: Private
    
    private var theme: Theme!
    
    // MARK: Public
    
    var didTapBackground: (() -> Void)?
    var didTapStopButton: (() -> Void)?
    
    // MARK: - Setup
    
    static func instantiate() -> LiveLocationSharingBannerView {
        let view = LiveLocationSharingBannerView.loadFromNib()
        view.update(theme: ThemeService.shared().theme)
        return view
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupBackgroundTapGestureRecognizer()
        
        self.titleLabel.text = VectorL10n.liveLocationSharingBannerTitle
        self.stopButton.setTitle(VectorL10n.liveLocationSharingBannerStop, for: .normal)
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.theme = theme
        
        let tintColor = theme.colors.background
        
        self.backgroundColor = theme.tintColor
        
        self.iconImageView.tintColor = tintColor
        
        self.titleLabel.textColor = tintColor
        self.titleLabel.font = theme.fonts.footnote
        
        self.stopButton.vc_setTitleFont(theme.fonts.footnote)
        self.stopButton.tintColor = tintColor
        self.stopButton.setTitleColor(tintColor, for: .normal)
        self.stopButton.setTitleColor(tintColor.withAlphaComponent(0.5), for: .highlighted)
    }
    
    // MARK: - Private
    
    private func setupBackgroundTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundViewTap(_:)))
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - Actions
    
    @objc private func handleBackgroundViewTap(_ gestureRecognizer: UITapGestureRecognizer) {
        self.didTapBackground?()
    }

    @IBAction private func stopButtonAction(_ sender: Any) {
        self.didTapStopButton?()
    }
}
