// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
