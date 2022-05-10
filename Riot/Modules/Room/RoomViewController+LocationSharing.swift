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
