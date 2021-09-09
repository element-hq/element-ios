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
