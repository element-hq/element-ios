// 
// Copyright 2021 New Vector Ltd
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
