// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit
import Reusable

protocol VersionCheckAlertViewControllerDelegate: AnyObject {
    func alertViewControllerDidRequestDismissal(_ alertViewController: VersionCheckAlertViewController)
    func alertViewControllerDidRequestAction(_ alertViewController: VersionCheckAlertViewController)
}

struct VersionCheckAlertViewControllerDetails {
    let title: String
    let subtitle: String
    let actionButtonTitle: String
}

class VersionCheckAlertViewController: UIViewController {
    
    @IBOutlet private var alertContainerView: UIView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    
    @IBOutlet private var dismissButton: UIButton!
    @IBOutlet private var actionButton: UIButton!
    
    private var themeService: ThemeService!
    private var details: VersionCheckAlertViewControllerDetails?
    
    weak var delegate: VersionCheckAlertViewControllerDelegate?
    
    static func instantiate(themeService: ThemeService) -> VersionCheckAlertViewController {
        let versionCheckAlertViewController = VersionCheckAlertViewController(nibName: nil, bundle: nil)
        versionCheckAlertViewController.themeService = themeService
        versionCheckAlertViewController.modalPresentationStyle = .overFullScreen
        versionCheckAlertViewController.modalTransitionStyle = .crossDissolve
        return versionCheckAlertViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        actionButton.layer.masksToBounds = true
        actionButton.layer.cornerRadius = 6.0
        
        configureWithDetails(details)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: .themeServiceDidChangeTheme, object: nil)
        updateTheme()
    }
    
    func configureWithDetails(_ details: VersionCheckAlertViewControllerDetails?) {
        guard let details = details else {
            return
        }
        
        guard self.isViewLoaded else {
            self.details = details
            return
        }
        
        titleLabel.text = details.title
        actionButton.setTitle(details.actionButtonTitle, for: .normal)
        
        let attributedSubtitle = NSMutableAttributedString(string: details.subtitle)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.alignment = .center
        
        attributedSubtitle.addAttribute(.paragraphStyle, value: paragraphStyle, range: .init(location: 0, length: attributedSubtitle.length))
        
        subtitleLabel.attributedText = attributedSubtitle
    }
    
    // MARK: - Private
    
    @IBAction private func onDismissButtonTap(_ sender: UIButton) {
        delegate?.alertViewControllerDidRequestDismissal(self)
    }
    
    @IBAction private func onActionButtonTap(_ sender: UIButton) {
        delegate?.alertViewControllerDidRequestAction(self)
    }
    
    @objc private func updateTheme() {
        let theme = themeService.theme
        
        alertContainerView.backgroundColor = theme.colors.background
        
        titleLabel.textColor = theme.colors.primaryContent
        subtitleLabel.textColor = theme.colors.secondaryContent
        
        dismissButton.tintColor = theme.colors.secondaryContent
        actionButton.vc_setBackgroundColor(theme.colors.accent, for: .normal)
    }
}
