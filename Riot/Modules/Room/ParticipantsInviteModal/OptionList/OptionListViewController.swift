// File created from ScreenTemplate
// $ createScreen.sh Room/ParticipantsInviteModal/OptionList OptionList
/*
 Copyright 2021 New Vector Ltd
 
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

final class OptionListViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 80.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var bottomMargin: NSLayoutConstraint!

    // MARK: Private

    private var viewModel: OptionListViewModelProtocol!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var options: [OptionListItemViewData] = []

    // MARK: - Setup
    
    class func instantiate(with viewModel: OptionListViewModelProtocol) -> OptionListViewController {
        let viewController = StoryboardScene.OptionListViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.tableView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.backgroundColor
        self.tableView.backgroundColor = theme.backgroundColor

        self.titleLabel.textColor = theme.colors.primaryContent
        self.titleLabel.font = theme.fonts.title3SB
        
        self.closeButton.backgroundColor = theme.roomInputTextBorder
        self.closeButton.tintColor = theme.noticeSecondaryColor
        
        self.tableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        self.setupTableView()
        
        self.closeButton.layer.masksToBounds = true
        self.closeButton.layer.cornerRadius = self.closeButton.bounds.height / 2
    }
    
    private func setupTableView() {
        self.tableView.separatorStyle = .none
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Constants.estimatedRowHeight
        self.tableView.allowsSelection = true
        self.tableView.register(cellType: OptionListViewCell.self)
        self.tableView.tableFooterView = UIView()
    }

    private func render(viewState: OptionListViewState) {
        switch viewState {
        case .idle:
            break
        case .loading:
            self.renderLoading()
        case .loaded(let title, let options):
            self.renderLoaded(title: title, options: options)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(title: String?, options: [OptionListItemViewData]) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.titleLabel.text = title
        self.options = options
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    
    // MARK: - Actions
    
    @IBAction private func closeAction(_ sender: Any) {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - OptionListViewModelViewDelegate
extension OptionListViewController: OptionListViewModelViewDelegate {

    func optionListViewModel(_ viewModel: OptionListViewModelProtocol, didUpdateViewState viewSate: OptionListViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - SlidingModalPresentable
extension OptionListViewController: SlidingModalPresentable {
    func allowsDismissOnBackgroundTap() -> Bool {
        return true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        return tableView.frame.minY + Constants.estimatedRowHeight * CGFloat(options.count) + bottomMargin.constant
    }
}

// MARK: - UITableViewDataSource
extension OptionListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewData = options[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: OptionListViewCell.self)
        cell.update(theme: self.theme)
        cell.update(with: viewData)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension OptionListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if options[indexPath.row].enabled {
            viewModel.process(viewAction: .selected(indexPath.row))
        }
    }
}
