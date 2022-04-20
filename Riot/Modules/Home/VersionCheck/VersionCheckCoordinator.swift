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

import Foundation

class VersionCheckCoordinator: Coordinator, VersionCheckBannerViewDelegate, VersionCheckAlertViewControllerDelegate {
    private enum Constants {
        static let osVersionToBeDropped = 13
        static let hasOSVersionBeenDropped = false
        static let supportURL = URL(string: "https://support.apple.com/en-gb/guide/iphone/iph3e504502/ios")
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let rootViewController: UIViewController
    private let bannerPresenter: BannerPresentationProtocol
    private let themeService: ThemeService
    private var versionCheckBannerView: VersionCheckBannerView?
    
    // MARK: Public
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(rootViewController: UIViewController, bannerPresenter: BannerPresentationProtocol, themeService: ThemeService) {
        self.rootViewController = rootViewController
        self.bannerPresenter = bannerPresenter
        self.themeService = themeService
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    // MARK: - Public methods
    
    func start() {
        let majorOSVersion = ProcessInfo().operatingSystemVersion.majorVersion
        
        guard majorOSVersion <= Constants.osVersionToBeDropped else {
            return
        }
        
        let versionCheckNextDisplayDateTimeInterval = RiotSettings.shared.versionCheckNextDisplayDateTimeInterval
        if versionCheckNextDisplayDateTimeInterval > 0 {
            let nextDisplayDate = Date(timeIntervalSince1970: versionCheckNextDisplayDateTimeInterval)
            if nextDisplayDate > Date() {
                return
            }
        }
        
        let versionCheckBannerView = VersionCheckBannerView.loadFromNib()
        versionCheckBannerView.delegate = self
        versionCheckBannerView.update(theme: themeService.theme)
        
        if Constants.hasOSVersionBeenDropped {
            versionCheckBannerView.configureWithDetails(VersionCheckBannerViewDetails(title: VectorL10n.versionCheckBannerTitleDeprecated(String(Constants.osVersionToBeDropped)),
                                                                                      subtitle: VectorL10n.versionCheckBannerSubtitleDeprecated(AppInfo.current.displayName, String(Constants.osVersionToBeDropped), AppInfo.current.displayName)))
        } else {
            versionCheckBannerView.configureWithDetails(VersionCheckBannerViewDetails(title: VectorL10n.versionCheckBannerTitleSupported(String(Constants.osVersionToBeDropped)),
                                                                                      subtitle: VectorL10n.versionCheckBannerSubtitleSupported(AppInfo.current.displayName, String(Constants.osVersionToBeDropped), AppInfo.current.displayName)))
        }
        
        bannerPresenter.presentBannerView(versionCheckBannerView, animated: true)
        self.versionCheckBannerView = versionCheckBannerView
    }
    
    // MARK: - VersionDropBannerViewDelegate
    
    func bannerViewDidRequestDismissal(_ bannerView: VersionCheckBannerView) {
        dismissVersionCheckBanner()
    }
    
    func bannerViewDidRequestInteraction(_ bannerView: VersionCheckBannerView) {
        
        let versionCheckAlertViewController = VersionCheckAlertViewController.instantiate(themeService: themeService)
        versionCheckAlertViewController.delegate = self
        
        if Constants.hasOSVersionBeenDropped {
            versionCheckAlertViewController.configureWithDetails(VersionCheckAlertViewControllerDetails(title: VectorL10n.versionCheckModalTitleDeprecated(String(Constants.osVersionToBeDropped)),
                                                                                                        subtitle: VectorL10n.versionCheckModalSubtitleDeprecated(AppInfo.current.displayName, AppInfo.current.displayName),
                                                                                                        actionButtonTitle: VectorL10n.versionCheckModalActionTitleDeprecated))
        } else {
            versionCheckAlertViewController.configureWithDetails(VersionCheckAlertViewControllerDetails(title: VectorL10n.versionCheckModalTitleSupported(String(Constants.osVersionToBeDropped)),
                                                                                                        subtitle: VectorL10n.versionCheckModalSubtitleSupported(AppInfo.current.displayName, AppInfo.current.displayName),
                                                                                                        actionButtonTitle: VectorL10n.versionCheckModalActionTitleSupported))
        }
        
        rootViewController.present(versionCheckAlertViewController, animated: true) {
            self.dismissVersionCheckBanner()
        }
    }
    
    // MARK: - VersionCheckAlertViewControllerDelegate
    
    func alertViewControllerDidRequestDismissal(_ alertViewController: VersionCheckAlertViewController) {
        rootViewController.dismiss(animated: true, completion: nil)
    }
    
    func alertViewControllerDidRequestAction(_ alertViewController: VersionCheckAlertViewController) {
        rootViewController.dismiss(animated: true, completion: nil)
        
        guard Constants.hasOSVersionBeenDropped else {
            return
        }
        
        if let url = Constants.supportURL {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: - Private methods
    
    private func dismissVersionCheckBanner() {
        bannerPresenter.dismissBannerView(animated: true)
        
        let nextDisplayDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        RiotSettings.shared.versionCheckNextDisplayDateTimeInterval = nextDisplayDate?.timeIntervalSince1970 ?? 0.0
    }
    
    @objc private func updateTheme() {
        let theme = themeService.theme
        versionCheckBannerView?.update(theme: theme)
    }
}
