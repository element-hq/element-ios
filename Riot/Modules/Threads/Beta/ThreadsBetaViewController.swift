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

import UIKit

class ThreadsBetaViewController: UIViewController {
    // MARK: Constants

    private enum Constants {
        static let learnMoreLink = "https://element.io/help#threads"
    }

    // MARK: Outlets

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var separatorLineView: UIView!
    @IBOutlet private var informationTextView: UITextView! {
        didSet {
            informationTextView.textContainer.lineFragmentPadding = 0
        }
    }

    @IBOutlet private var enableButton: UIButton!
    @IBOutlet private var cancelButton: UIButton!

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

        setupViews()

        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide back button
        navigationItem.setHidesBackButton(true, animated: animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
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
        update(theme: ThemeService.shared().theme)
    }

    private func setupViews() {
        vc_removeBackTitle()

        enableButton.setTitle(VectorL10n.threadsBetaEnable, for: .normal)
        cancelButton.setTitle(VectorL10n.threadsBetaCancel, for: .normal)

        titleLabel.text = VectorL10n.threadsBetaTitle
        guard let font = informationTextView.font else {
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
        informationTextView.attributedText = attributedString
    }

    // MARK: - Actions

    @IBAction private func enableButtonAction(_ sender: UIButton) {
        didTapEnableButton?()
    }

    @IBAction private func cancelButtonAction(_ sender: UIButton) {
        didTapCancelButton?()
    }
}

// MARK: - Themable

extension ThreadsBetaViewController: Themable {
    func update(theme: Theme) {
        self.theme = theme

        view.backgroundColor = theme.colors.background

        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        titleLabel.textColor = theme.textPrimaryColor
        separatorLineView.backgroundColor = theme.colors.system
        informationTextView.textColor = theme.textPrimaryColor

        enableButton.vc_setBackgroundColor(theme.tintColor, for: .normal)
        enableButton.setTitleColor(theme.baseTextPrimaryColor, for: .normal)
        cancelButton.vc_setBackgroundColor(.clear, for: .normal)
        cancelButton.setTitleColor(theme.tintColor, for: .normal)
    }
}

// MARK: - SlidingModalPresentable

extension ThreadsBetaViewController: SlidingModalPresentable {
    func allowsDismissOnBackgroundTap() -> Bool {
        false
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
