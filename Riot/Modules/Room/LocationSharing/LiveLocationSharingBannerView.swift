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
