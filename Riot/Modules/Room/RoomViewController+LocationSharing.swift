// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// RoomViewController live location sharing handling
@objc extension RoomViewController {
    
    func updateLiveLocationBannerViewVisibility() {
        if self.shouldShowLiveLocationSharingBannerView {
            self.showLiveLocationBannerView()
        } else {
            self.hideLiveLocationBannerView()
        }
    }
    
    func hideLiveLocationBannerView() {
        self.liveLocationSharingBannerView?.removeFromSuperview()
    }
    
    func showLiveLocationBannerView() {
        guard liveLocationSharingBannerView == nil else {
            return
        }

        let bannerView = LiveLocationSharingBannerView.instantiate()

        bannerView.update(theme: ThemeService.shared().theme)

        bannerView.didTapBackground = { [weak self] in
            guard let self = self else {
                return
            }
            
            self.delegate?.roomViewControllerDidTapLiveLocationSharingBanner(self)
        }

        bannerView.didTapStopButton = { [weak self] in
            
            guard let self = self else {
                return
            }
            self.delegate?.roomViewControllerDidStopLiveLocationSharing(self, beaconInfoEventId: nil)
        }
        
        self.topBannersStackView?.addArrangedSubview(bannerView)

        self.liveLocationSharingBannerView = bannerView
    }
}
