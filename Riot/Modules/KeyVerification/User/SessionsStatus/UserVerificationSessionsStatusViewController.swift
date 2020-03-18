// File created from ScreenTemplate
// $ createScreen.sh UserVerification UserVerificationSessionsStatus
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

final class UserVerificationSessionsStatusViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 40.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var badgeImageImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var informationLabel: UILabel!
    @IBOutlet private weak var sessionsTableViewTitle: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: Private

    private var viewModel: UserVerificationSessionsStatusViewModelType!
    private var theme: Theme!
    private var errorPresenter: MXKErrorPresentation!
    private var activityIndicatorPresenter: ActivityIndicatorPresenter!
    private var sessionsStatusViewData: [UserVerificationSessionStatusViewData] = []
    private var userEncryptionTrustLevel: UserEncryptionTrustLevel = .unknown

    // MARK: - Setup
    
    class func instantiate(with viewModel: UserVerificationSessionsStatusViewModelType) -> UserVerificationSessionsStatusViewController {
        let viewController = StoryboardScene.UserVerificationSessionsStatusViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
                
        self.setupViews()
        self.vc_removeBackTitle()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.closeButton.layer.cornerRadius = self.closeButton.frame.size.width/2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        self.closeButton.vc_setBackgroundColor(theme.headerTextSecondaryColor, for: .normal)
        self.titleLabel.textColor = theme.textPrimaryColor
        self.informationLabel.textColor = theme.textPrimaryColor
        self.sessionsTableViewTitle.textColor = theme.textPrimaryColor
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.closeButton.layer.masksToBounds = true
        self.setupTableView()
        self.updateTitleViews()
        
        self.sessionsTableViewTitle.text = VectorL10n.userVerificationSessionsListTableTitle
        self.informationLabel.text = VectorL10n.userVerificationSessionsListInformation
    }
    
    private func setupTableView() {
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Constants.estimatedRowHeight
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        self.tableView.alwaysBounceVertical = false
        
        self.tableView.register(cellType: UserVerificationSessionStatusCell.self)
    }
    
    private func render(viewState: UserVerificationSessionsStatusViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(userTrustLevel: let userTrustLevel, sessionsStatusViewData: let sessionsStatusViewData):
            self.renderLoaded(userTrustLevel: userTrustLevel, sessionsStatusViewData: sessionsStatusViewData)
        case .error(let error):
            self.render(error: error)
        }
    }

    private func renderLoading() {
        self.tableView.isUserInteractionEnabled = false
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(userTrustLevel: UserEncryptionTrustLevel, sessionsStatusViewData: [UserVerificationSessionStatusViewData]) {
        self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        self.tableView.isUserInteractionEnabled = true
        
        self.userEncryptionTrustLevel = userTrustLevel
        self.sessionsStatusViewData = sessionsStatusViewData
        
        self.updateTitleViews()
        self.tableView.reloadData()
    }
    
    private func render(error: Error) {
        self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        self.tableView.isUserInteractionEnabled = true
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func updateTitleViews() {
        
        let badgeImage: UIImage
        let title: String
        
        switch self.userEncryptionTrustLevel {
        case .trusted:
            badgeImage = Asset.Images.encryptionTrusted.image
            title = VectorL10n.userVerificationSessionsListUserTrustLevelTrustedTitle
        case .warning:
            badgeImage = Asset.Images.encryptionWarning.image
            title = VectorL10n.userVerificationSessionsListUserTrustLevelWarningTitle
        default:
            badgeImage = Asset.Images.encryptionNormal.image
            title = VectorL10n.userVerificationSessionsListUserTrustLevelUnknownTitle
        }
        
        self.badgeImageImageView.image = badgeImage
        self.titleLabel.text = title
    }
    
    // MARK: - Actions

    @IBAction private func closeButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .close)
    }
}

// MARK: - UITableViewDataSource
extension UserVerificationSessionsStatusViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sessionsStatusViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: UserVerificationSessionStatusCell.self)
        
        let viewData = self.sessionsStatusViewData[indexPath.row]
        
        cell.update(theme: self.theme)
        cell.fill(viewData: viewData)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension UserVerificationSessionsStatusViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewData = self.sessionsStatusViewData[indexPath.row]
        self.viewModel.process(viewAction: .selectSession(deviceId: viewData.deviceId))
    }
}

// MARK: - UserVerificationSessionsStatusViewModelViewDelegate
extension UserVerificationSessionsStatusViewController: UserVerificationSessionsStatusViewModelViewDelegate {

    func userVerificationSessionsStatusViewModel(_ viewModel: UserVerificationSessionsStatusViewModelType, didUpdateViewState viewSate: UserVerificationSessionsStatusViewState) {
        self.render(viewState: viewSate)
    }
}
