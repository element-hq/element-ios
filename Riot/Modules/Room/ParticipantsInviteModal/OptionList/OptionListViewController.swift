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

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var bottomMargin: NSLayoutConstraint!

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
        
        setupViews()
        keyboardAvoider = KeyboardAvoider(scrollViewContainerView: view, scrollView: tableView)
        activityPresenter = ActivityIndicatorPresenter()
        errorPresenter = MXKErrorAlertPresentation()
        
        registerThemeServiceDidChangeThemeNotification()
        update(theme: theme)
        
        viewModel.viewDelegate = self

        viewModel.process(viewAction: .loadData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        keyboardAvoider?.stopAvoiding()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor

        titleLabel.textColor = theme.colors.primaryContent
        titleLabel.font = theme.fonts.title3SB
        
        closeButton.backgroundColor = theme.roomInputTextBorder
        closeButton.tintColor = theme.noticeSecondaryColor
        
        tableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        setupTableView()
        
        closeButton.layer.masksToBounds = true
        closeButton.layer.cornerRadius = closeButton.bounds.height / 2
    }
    
    private func setupTableView() {
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
        tableView.allowsSelection = true
        tableView.register(cellType: OptionListViewCell.self)
        tableView.tableFooterView = UIView()
    }

    private func render(viewState: OptionListViewState) {
        switch viewState {
        case .idle:
            break
        case .loading:
            renderLoading()
        case .loaded(let title, let options):
            renderLoaded(title: title, options: options)
        case .error(let error):
            render(error: error)
        }
    }
    
    private func renderLoading() {
        activityPresenter.presentActivityIndicator(on: view, animated: true)
    }
    
    private func renderLoaded(title: String?, options: [OptionListItemViewData]) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        titleLabel.text = title
        self.options = options
    }
    
    private func render(error: Error) {
        activityPresenter.removeCurrentActivityIndicator(animated: true)
        errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }

    // MARK: - Actions
    
    @IBAction private func closeAction(_ sender: Any) {
        viewModel.process(viewAction: .cancel)
    }
}

// MARK: - OptionListViewModelViewDelegate

extension OptionListViewController: OptionListViewModelViewDelegate {
    func optionListViewModel(_ viewModel: OptionListViewModelProtocol, didUpdateViewState viewSate: OptionListViewState) {
        render(viewState: viewSate)
    }
}

// MARK: - SlidingModalPresentable

extension OptionListViewController: SlidingModalPresentable {
    func allowsDismissOnBackgroundTap() -> Bool {
        true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        tableView.frame.minY + Constants.estimatedRowHeight * CGFloat(options.count) + bottomMargin.constant
    }
}

// MARK: - UITableViewDataSource

extension OptionListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewData = options[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: OptionListViewCell.self)
        cell.update(theme: theme)
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
