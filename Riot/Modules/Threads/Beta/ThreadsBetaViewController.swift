// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

class ThreadsBetaViewController: UIViewController {

    // MARK: Constants

    private enum Constants {
        static let learnMoreLink = "https://element.io/help#threads"
    }

    // MARK: Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var separatorLineView: UIView!
    @IBOutlet private weak var informationTextView: UITextView! {
        didSet {
            informationTextView.textContainer.lineFragmentPadding = 0
        }
    }
    @IBOutlet private weak var enableButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!

    // MARK: Private

    private var theme: Theme!
    private var infoText: String!
    private var additionalText: String?

    // MARK: Public

    @objc var didTapEnableButton: (() -> Void)?
    @objc var didTapCancelButton: (() -> Void)?

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupViews()

        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide back button
        self.navigationItem.setHidesBackButton(true, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }

    // MARK: - Setup

    @objc class func instantiate(infoText: String, additionalText: String?) -> ThreadsBetaViewController {
        let viewController = StoryboardScene.ThreadsBetaViewController.initialScene.instantiate()
        viewController.theme = ThemeService.shared().theme
        viewController.infoText = infoText
        viewController.additionalText = additionalText
        return viewController
    }

    // MARK: - Private

    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: .themeServiceDidChangeTheme,
                                               object: nil)
    }

    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }

    private func setupViews() {
        self.vc_removeBackTitle()

        self.enableButton.setTitle(VectorL10n.threadsBetaEnable, for: .normal)
        self.cancelButton.setTitle(VectorL10n.threadsBetaCancel, for: .normal)

        self.titleLabel.text = VectorL10n.threadsBetaTitle
        guard let font = self.informationTextView.font else {
            return
        }
        let attributedString = NSMutableAttributedString(string: infoText,
                                                         attributes: [.font: font])
        let link = NSAttributedString(string: VectorL10n.threadsBetaInformationLink,
                                      attributes: [.link: Constants.learnMoreLink,
                                                   .font: font])
        attributedString.append(link)

        if let additionalText = additionalText {
            attributedString.append(NSAttributedString(string: additionalText,
                                                       attributes: [.font: font]))
        }
        self.informationTextView.attributedText = attributedString
    }

    // MARK: - Actions

    @IBAction private func enableButtonAction(_ sender: UIButton) {
        self.didTapEnableButton?()
    }

    @IBAction private func cancelButtonAction(_ sender: UIButton) {
        self.didTapCancelButton?()
    }

}

// MARK: - Themable

extension ThreadsBetaViewController: Themable {

    func update(theme: Theme) {
        self.theme = theme

        self.view.backgroundColor = theme.colors.background

        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        self.titleLabel.textColor = theme.textPrimaryColor
        self.separatorLineView.backgroundColor = theme.colors.system
        self.informationTextView.textColor = theme.textPrimaryColor

        self.enableButton.vc_setBackgroundColor(theme.tintColor, for: .normal)
        self.enableButton.setTitleColor(theme.baseTextPrimaryColor, for: .normal)
        self.cancelButton.vc_setBackgroundColor(.clear, for: .normal)
        self.cancelButton.setTitleColor(theme.tintColor, for: .normal)
    }

}

// MARK: - SlidingModalPresentable

extension ThreadsBetaViewController: SlidingModalPresentable {

    func allowsDismissOnBackgroundTap() -> Bool {
        return false
    }

    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        guard let view = ThreadsNoticeViewController.instantiate().view else {
            return 0
        }

        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)

        return view.systemLayoutSizeFitting(fittingSize).height
            + UIWindow().safeAreaInsets.top
            + UIWindow().safeAreaInsets.bottom
    }

}
