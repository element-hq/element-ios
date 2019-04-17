// File created from simpleScreenTemplate
// $ createSimpleScreen.sh DeviceVerification/Loading DeviceVerificationDataLoading
/*
 Copyright 2019 New Vector Ltd
 
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

protocol DeviceVerificationDataLoadingViewControllerDelegate: class {
    func deviceVerificationDataLoadingViewControllerDidLoadData(_ viewController: DeviceVerificationDataLoadingViewController, user: MXUser, device: MXDeviceInfo)
    func deviceVerificationDataLoadingViewControllerDidCancel(_ viewController: DeviceVerificationDataLoadingViewController)
}

final class DeviceVerificationDataLoadingViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    // MARK: Private

    private var session: MXSession!
    private var otherUserId: String!
    private var otherDeviceId: String!

    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    
    // MARK: Public
    
    weak var delegate: DeviceVerificationDataLoadingViewControllerDelegate?
    
    // MARK: - Setup

    class func instantiate(session: MXSession, otherUserId: String, otherDeviceId: String) -> DeviceVerificationDataLoadingViewController {
        let viewController = StoryboardScene.DeviceVerificationDataLoadingViewController.initialScene.instantiate()
        viewController.session = session
        viewController.otherUserId = otherUserId
        viewController.otherDeviceId = otherDeviceId
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = VectorL10n.deviceVerificationTitle
        self.vc_removeBackTitle()
        
        self.setupViews()

        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()

        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)

        self.loadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
    }
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }

    private func loadData() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)

        if let otherUser = self.session.user(withUserId: otherUserId) {
            self.session.crypto?.downloadKeys([self.otherUserId], forceDownload: false, success: { [weak self] (usersDevicesMap) in
                guard let sself = self else {
                    return
                }

                sself.activityPresenter.removeCurrentActivityIndicator(animated: true)

                if let otherDevice = usersDevicesMap?.object(forDevice: sself.otherDeviceId, forUser: sself.otherUserId) {
                    sself.delegate?.deviceVerificationDataLoadingViewControllerDidLoadData(sself, user: otherUser, device: otherDevice)
                } else {
                    sself.errorPresenter.presentError(from: sself, title: "", message: VectorL10n.deviceVerificationErrorCannotLoadDevice, animated: true, handler: {
                        sself.delegate?.deviceVerificationDataLoadingViewControllerDidCancel(sself)
                    })
                }

                }, failure: { [weak self] (error) in
                    guard let sself = self else {
                        return
                    }

                    sself.activityPresenter.removeCurrentActivityIndicator(animated: true)
                    sself.errorPresenter.presentError(from: sself, forError: error, animated: true, handler: {
                        sself.delegate?.deviceVerificationDataLoadingViewControllerDidCancel(sself)
                    })
            })

        } else {
            self.errorPresenter.presentError(from: self, title: "", message: VectorL10n.deviceVerificationErrorCannotLoadDevice, animated: true, handler: {
                self.delegate?.deviceVerificationDataLoadingViewControllerDidCancel(self)
            })
        }
    }

    // MARK: - Actions

    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }

    private func cancelButtonAction() {
        self.delegate?.deviceVerificationDataLoadingViewControllerDidCancel(self)
    }
}
