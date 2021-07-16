// File created from simpleScreenTemplate
// $ createSimpleScreen.sh CallTransfer2 CallTransferMain
/*
 Copyright 2020 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

@objc protocol CallTransferMainViewControllerDelegate: AnyObject {
    func callTransferMainViewControllerDidComplete(_ viewController: CallTransferMainViewController,
                                                   consult: Bool,
                                                   contact: MXKContact?,
                                                   phoneNumber: String?)
    func callTransferMainViewControllerDidCancel(_ viewController: CallTransferMainViewController)
}

@objcMembers
final class CallTransferMainViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.setTitle(VectorL10n.callTransferUsers, forSegmentAt: 0)
            segmentedControl.setTitle(VectorL10n.callTransferDialpad, forSegmentAt: 1)
        }
    }
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var bottomBgView: UIView!
    @IBOutlet private weak var consultButton: UIButton!
    @IBOutlet private weak var connectButton: RoundedButton! {
        didSet {
            connectButton.isEnabled = false
        }
    }
    
    // MARK: Private
    
    private var selectedContact: MXKContact? {
        didSet {
            updateConnectButton()
        }
    }
    private var phoneNumber: String? {
        didSet {
            updateConnectButton()
        }
    }
    private var session: MXSession!
    private var ignoredUserIds: [String] = []
    private var theme: Theme!
    
    private lazy var contactsVC: CallTransferSelectContactViewController = {
        let controller = CallTransferSelectContactViewController.instantiate(withSession: session, ignoredUserIds: ignoredUserIds)
        controller.delegate = self
        return controller
    }()
    
    private lazy var dialpadVC: DialpadViewController = {
        let configuration = DialpadConfiguration(showsTitle: false,
                                                 showsCloseButton: false,
                                                 showsCallButton: false)
        let controller = DialpadViewController.instantiate(withConfiguration: configuration)
        controller.delegate = self
        return controller
    }()
    
    // MARK: Public
    
    weak var delegate: CallTransferMainViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(withSession session: MXSession, ignoredUserIds: [String] = []) -> CallTransferMainViewController {
        let viewController = StoryboardScene.CallTransferMainViewController.initialScene.instantiate()
        viewController.session = session
        viewController.ignoredUserIds = ignoredUserIds
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.callTransferTitle
        self.vc_removeBackTitle()
        
        self.setupViews()
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func updateConnectButton() {
        if selectedContact != nil {
            connectButton.isEnabled = true
            connectButton.alpha = 1
        } else if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
            connectButton.isEnabled = true
            connectButton.alpha = 1
        } else {
            connectButton.isEnabled = false
            connectButton.alpha = 0.4
        }
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        
        updateConnectButton()
        
        addChild(contactsVC)
        addChild(dialpadVC)
        
        if let view = contentView(at: segmentedControl.selectedSegmentIndex) {
            containerView.vc_addSubViewMatchingParent(view)
        }
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.bottomBgView.backgroundColor = theme.baseColor
        self.consultButton.tintColor = theme.tintColor
        self.consultButton.setTitleColor(theme.textPrimaryColor, for: .normal)
        self.connectButton.update(theme: theme)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    private func contentView(at index: Int) -> UIView? {
        switch index {
        case 0:
            return contactsVC.view
        case 1:
            return dialpadVC.view
        default:
            return nil
        }
    }

    // MARK: - Actions
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    @IBAction private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        containerView.vc_removeAllSubviews()
        if let view = contentView(at: sender.selectedSegmentIndex) {
            containerView.vc_addSubViewMatchingParent(view)
        }
    }
    
    @IBAction private func consultButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction private func connectButtonAction(_ sender: UIButton) {
        delegate?.callTransferMainViewControllerDidComplete(self,
                                                            consult: consultButton.isSelected,
                                                            contact: selectedContact,
                                                            phoneNumber: phoneNumber)
    }

    private func cancelButtonAction() {
        self.delegate?.callTransferMainViewControllerDidCancel(self)
    }
}

//  MARK: - CallTransferSelectContactViewControllerDelegate

extension CallTransferMainViewController: CallTransferSelectContactViewControllerDelegate {
    
    func callTransferSelectContactViewControllerDidSelectContact(_ viewController: CallTransferSelectContactViewController, contact: MXKContact?) {
        selectedContact = contact
    }
    
}

//  MARK: - DialpadViewControllerDelegate

extension CallTransferMainViewController: DialpadViewControllerDelegate {
    
    func dialpadViewControllerDidTapDigit(_ viewController: DialpadViewController, digit: String) {
        phoneNumber = viewController.rawPhoneNumber
    }
    
}
