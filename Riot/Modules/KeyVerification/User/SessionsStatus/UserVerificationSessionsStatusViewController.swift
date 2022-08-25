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
    
    @IBOutlet private var badgeImageImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var informationLabel: UILabel!
    @IBOutlet private var sessionsTableViewTitle: UILabel!
    @IBOutlet private var tableView: UITableView!
    
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
                
        setupViews()
        vc_removeBackTitle()
        activityIndicatorPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        self.theme.statusBarStyle
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        closeButton.layer.cornerRadius = closeButton.frame.size.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        closeButton.vc_setBackgroundColor(theme.headerTextSecondaryColor, for: .normal)
        titleLabel.textColor = theme.textPrimaryColor
        informationLabel.textColor = theme.textPrimaryColor
        sessionsTableViewTitle.textColor = theme.textPrimaryColor
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        closeButton.layer.masksToBounds = true
        setupTableView()
        updateTitleViews()
        
        sessionsTableViewTitle.text = VectorL10n.userVerificationSessionsListTableTitle
        informationLabel.text = VectorL10n.userVerificationSessionsListInformation
    }
    
    private func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        
        tableView.register(cellType: UserVerificationSessionStatusCell.self)
    }
    
    private func render(viewState: UserVerificationSessionsStatusViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded(userTrustLevel: let userTrustLevel, sessionsStatusViewData: let sessionsStatusViewData):
            renderLoaded(userTrustLevel: userTrustLevel, sessionsStatusViewData: sessionsStatusViewData)
        case .error(let error):
            render(error: error)
        }
    }

    private func renderLoading() {
        tableView.isUserInteractionEnabled = false
        activityIndicatorPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(userTrustLevel: UserEncryptionTrustLevel, sessionsStatusViewData: [UserVerificationSessionStatusViewData]) {
        activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        tableView.isUserInteractionEnabled = true
        
        userEncryptionTrustLevel = userTrustLevel
        self.sessionsStatusViewData = sessionsStatusViewData
        
        updateTitleViews()
        tableView.reloadData()
    }
    
    private func render(error: Error) {
        activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        tableView.isUserInteractionEnabled = true
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func updateTitleViews() {
        let badgeImage: UIImage
        let title: String
        
        switch userEncryptionTrustLevel {
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
        
        badgeImageImageView.image = badgeImage
        titleLabel.text = title
    }
    
    // MARK: - Actions

    @IBAction private func closeButtonAction(_ sender: Any) {
        viewModel.process(viewAction: .close)
    }
}

// MARK: - UITableViewDataSource

extension UserVerificationSessionsStatusViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessionsStatusViewData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: UserVerificationSessionStatusCell.self)
        
        let viewData = sessionsStatusViewData[indexPath.row]
        
        cell.update(theme: theme)
        cell.fill(viewData: viewData)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension UserVerificationSessionsStatusViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewData = sessionsStatusViewData[indexPath.row]
        viewModel.process(viewAction: .selectSession(deviceId: viewData.deviceId))
    }
}

// MARK: - UserVerificationSessionsStatusViewModelViewDelegate

extension UserVerificationSessionsStatusViewController: UserVerificationSessionsStatusViewModelViewDelegate {
    func userVerificationSessionsStatusViewModel(_ viewModel: UserVerificationSessionsStatusViewModelType, didUpdateViewState viewSate: UserVerificationSessionsStatusViewState) {
        render(viewState: viewSate)
    }
}
