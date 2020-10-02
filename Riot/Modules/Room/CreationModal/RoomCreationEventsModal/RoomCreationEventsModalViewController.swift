// File created from ScreenTemplate
// $ createScreen.sh Modal2/RoomCreation RoomCreationEventsModal
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

final class RoomCreationEventsModalViewController: UIViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var mainTableView: UITableView!
    @IBOutlet private weak var roomAvatarImageView: MXKImageView! {
        didSet {
            roomAvatarImageView.layer.cornerRadius = roomAvatarImageView.frame.width/2
        }
    }
    @IBOutlet private weak var encryptionIconImageView: UIImageView!
    @IBOutlet private weak var roomNameLabel: UILabel!
    @IBOutlet private weak var roomInfoLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var separatorView: UIView!
    
    // MARK: Private

    private var viewModel: RoomCreationEventsModalViewModelType!
    private var theme: Theme!

    // MARK: - Setup
    
    class func instantiate(with viewModel: RoomCreationEventsModalViewModelType) -> RoomCreationEventsModalViewController {
        let viewController = StoryboardScene.RoomCreationEventsModalViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        _ = viewController.view
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
        
        roomNameLabel.text = viewModel.roomName
        roomInfoLabel.text = viewModel.roomInfo
        viewModel.setAvatar(in: roomAvatarImageView)
        viewModel.setEncryptionIcon(in: encryptionIconImageView)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.backgroundColor
        self.mainTableView.backgroundColor = theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }

        roomNameLabel.textColor = theme.textPrimaryColor
        roomInfoLabel.textColor = theme.textSecondaryColor
        closeButton.backgroundColor = theme.headerBorderColor
        closeButton.tintColor = theme.textSecondaryColor
        closeButton.setImage(closeButton.image(for: .normal)?.vc_tintedImage(usingColor: theme.textSecondaryColor), for: .normal)
        separatorView.backgroundColor = theme.lineBreakColor
        
        self.mainTableView.reloadData()
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            mainTableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        } else {
            mainTableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 36, right: 0)
        }
        mainTableView.register(cellType: TextViewTableViewCell.self)
    }

    private func render(viewState: RoomCreationEventsModalViewState) {
        switch viewState {
        case .loaded:
            self.renderLoaded()
        }
    }
    
    private func renderLoaded() {
        mainTableView.reloadData()
    }
    
    // MARK: - Actions

    @IBAction private func closeButtonTapped(_ sender: Any) {
        self.viewModel.process(viewAction: .close)
    }

}


// MARK: - RoomCreationEventsModalViewModelViewDelegate

extension RoomCreationEventsModalViewController: RoomCreationEventsModalViewModelViewDelegate {

    func roomCreationEventsModalViewModel(_ viewModel: RoomCreationEventsModalViewModelType, didUpdateViewState viewSate: RoomCreationEventsModalViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - SlidingModalPresentable

extension RoomCreationEventsModalViewController: SlidingModalPresentable {
    
    func allowsDismissOnBackgroundTap() -> Bool {
        return true
    }
    
    func layoutHeightFittingWidth(_ width: CGFloat) -> CGFloat {
        return mainTableView.contentSize.height
            + mainTableView.contentInset.top
            + mainTableView.contentInset.bottom
            + 80    // height of the above view
    }
    
}

// MARK: - UITableViewDataSource

extension RoomCreationEventsModalViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = viewModel.rowViewModel(at: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        let cell: TextViewTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        
        if let title = viewModel.title {
            let mutableTitle = NSMutableAttributedString(attributedString: title)
            mutableTitle.setAttributes([
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                NSAttributedString.Key.foregroundColor: theme.textSecondaryColor
            ], range: NSRange(location: 0, length: mutableTitle.length))
            cell.textView.attributedText = mutableTitle
        } else {
            cell.textView.attributedText = nil
        }
        
        cell.textView.textContainerInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        cell.textView.isScrollEnabled = false
        cell.textView.isEditable = false
        cell.textView.isSelectable = false
        cell.textView.backgroundColor = .clear
        cell.backgroundColor = theme.backgroundColor
        cell.contentView.backgroundColor = .clear
        cell.tintColor = theme.tintColor
        cell.selectionStyle = .none
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension RoomCreationEventsModalViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}
