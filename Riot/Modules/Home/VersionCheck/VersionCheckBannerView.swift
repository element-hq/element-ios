// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

protocol VersionCheckBannerViewDelegate: AnyObject {
    func bannerViewDidRequestDismissal(_ bannerView: VersionCheckBannerView)
    func bannerViewDidRequestInteraction(_ bannerView: VersionCheckBannerView)
}

struct VersionCheckBannerViewDetails {
    let title: String
    let subtitle: String
}

class VersionCheckBannerView: UIView, NibLoadable, Themable {
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    
    @IBOutlet private var infoButton: UIButton!
    @IBOutlet private var dismissButton: UIButton!
    
    weak var delegate: VersionCheckBannerViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(handleTapGesture))
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func configureWithDetails(_ details: VersionCheckBannerViewDetails) {
        titleLabel.text = details.title
        subtitleLabel.text = details.subtitle
    }
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.background
        
        titleLabel.textColor = theme.colors.primaryContent
        subtitleLabel.textColor = theme.colors.secondaryContent
        
        infoButton.tintColor = theme.colors.primaryContent
        dismissButton.tintColor = theme.colors.secondaryContent
    }
    
    // MARK: - Private
    
    @IBAction private func onDismissButtonTap(_ sender: UIButton) {
        delegate?.bannerViewDidRequestDismissal(self)
    }
    
    @objc private func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.bannerViewDidRequestInteraction(self)
    }
}
