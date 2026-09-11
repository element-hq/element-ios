// 
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

/// Decides when the banner inviting users to migrate to the new app is displayed at the top of the room list,
/// based on the homeserver Well Known configuration (see `HomeserverMigrationBannerConfiguration`).
///
/// The Well Known is refreshed by the SDK at every session start without any notification, so the banner is
/// re-evaluated when the session state changes, and the Well Known is explicitly refreshed when the app comes back to the foreground.
final class MigrationBannerCoordinator: Coordinator {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let rootViewController: UIViewController
    private let bannerPresenter: BannerPresentationProtocol
    private let sessionProvider: () -> MXSession?
    
    private var bannerView: MigrationBannerView?
    private var bannerHostingController: VectorHostingController?
    private var wellKnownRefreshOperation: MXHTTPOperation?
    /// Whether the user closed the banner. Only kept in memory for now: the banner comes back on the next app launch.
    private var isDismissedByUser = false
    
    // MARK: Public
    
    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    /// - Parameters:
    ///   - rootViewController: The view controller used to present the App Store page.
    ///   - bannerPresenter: The object in charge of displaying the banner view.
    ///   - sessionProvider: Provides the main session, if any. The banner follows the configuration of this session's homeserver.
    init(rootViewController: UIViewController,
         bannerPresenter: BannerPresentationProtocol,
         sessionProvider: @escaping () -> MXSession?) {
        self.rootViewController = rootViewController
        self.bannerPresenter = bannerPresenter
        self.sessionProvider = sessionProvider
    }
    
    deinit {
        wellKnownRefreshOperation?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public methods
    
    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionStateDidChange(_:)), name: .mxSessionStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bannerSlotDidBecomeFree(_:)), name: .bannerPresenterDidFreeBannerSlot, object: nil)

        updateBanner()
    }

    // MARK: - Private methods

    @objc private func sessionStateDidChange(_ notification: Notification) {
        guard let session = notification.object as? MXSession, session === sessionProvider() else {
            return
        }

        updateBanner()
    }

    @objc private func bannerSlotDidBecomeFree(_ notification: Notification) {
        guard let presenter = notification.object as AnyObject?, presenter === (bannerPresenter as AnyObject) else {
            return
        }

        // Another banner (e.g. the verification one) has been dismissed: present this one if needed.
        updateBanner()
    }
    
    @objc private func applicationDidBecomeActive() {
        guard let session = sessionProvider() else {
            return
        }
        
        // The SDK doesn't refresh the Well Known when resuming, do it so a configuration change on the homeserver is applied quickly.
        wellKnownRefreshOperation?.cancel()
        wellKnownRefreshOperation = session.refreshHomeserverWellknown({ [weak self] _ in
            self?.wellKnownRefreshOperation = nil
            self?.updateBanner()
        }, failure: { [weak self] error in
            self?.wellKnownRefreshOperation = nil
            MXLog.warning("[MigrationBannerCoordinator] Failed to refresh the homeserver Well Known: \(String(describing: error))")
        })
    }
    
    private func updateBanner() {
        guard let session = sessionProvider(),
              session.state != .closed,
              !isDismissedByUser,
              BuildSettings.replacementApp != nil else {
            dismissBannerIfNeeded()
            return
        }
        
        let configuration = session.vc_homeserverConfiguration().migrationBanner
        guard configuration.isEnabled else {
            dismissBannerIfNeeded()
            return
        }

        presentBannerIfNeeded(with: configuration)
    }

    private func handleCloseAction() {
        isDismissedByUser = true
        dismissBannerIfNeeded()

        // The banner slot is free again: let the verification banner be displayed if the device isn't verified.
        if let session = sessionProvider() {
            AppDelegate.theDelegate().checkCrossSigning(for: session)
        }
    }

    private func presentBannerIfNeeded(with configuration: HomeserverMigrationBannerConfiguration) {
        if let bannerView = bannerView, bannerView.superview == nil {
            // The banner has been replaced by another one with a higher priority, forget it so it can be presented again.
            self.bannerView = nil
            self.bannerHostingController = nil
        }

        guard bannerView == nil else {
            return
        }
        
        let targetAppStoreID = configuration.targetAppStoreID
        let banner = MigrationBanner(title: configuration.title,
                                     message: configuration.body,
                                     buttonTitle: targetAppStoreID == nil ? nil : configuration.buttonText,
                                     showsAppIcon: configuration.isTargetDefaultReplacementApp,
                                     downloadAction: { [weak self] in
                                         guard let self = self, let targetAppStoreID = targetAppStoreID else { return }
                                         Task { @MainActor in
                                             await ReplacementAppStorePresenter.presentStorePage(appStoreID: targetAppStoreID, from: self.rootViewController)
                                         }
                                     },
                                     closeAction: { [weak self] in
                                         self?.handleCloseAction()
                                     })
        
        let hostingController = VectorHostingController(rootView: banner)
        let bannerView = MigrationBannerView()
        bannerView.contentView = hostingController.view
        
        guard bannerPresenter.presentBannerView(bannerView, animated: true) else {
            // Another banner with a higher priority is displayed, the presentation will be retried on the next update.
            MXLog.debug("[MigrationBannerCoordinator] Banner not presented, another banner is displayed.")
            return
        }
        
        self.bannerHostingController = hostingController
        self.bannerView = bannerView
    }
    
    private func dismissBannerIfNeeded() {
        guard let bannerView = bannerView else {
            return
        }
        
        bannerPresenter.dismissBannerView(bannerView, animated: true)
        self.bannerView = nil
        self.bannerHostingController = nil
    }
}
