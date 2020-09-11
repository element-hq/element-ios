// File created from ScreenTemplate
// $ createScreen.sh CreateRoom/EnterNewRoomDetails EnterNewRoomDetails
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

final class EnterNewRoomDetailsViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let defaultStyleCellReuseIdentifier = "default"
        static let roomNameTextFieldTag: Int = 100
        static let roomTopicTextViewTag: Int = 101
        static let roomAddressTextFieldTag: Int = 102
        static let roomNameMinimumNumberOfChars = 3
        static let roomNameMaximumNumberOfChars = 50
        static let roomAddressMaximumNumberOfChars = 50
        static let roomTopicMaximumNumberOfChars = 250
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private
    
    private var viewModel: EnterNewRoomDetailsViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private lazy var createBarButtonItem: MXKBarButtonItem = {
        let item = MXKBarButtonItem(title: VectorL10n.create, style: .plain) { [weak self] in
            self?.createButtonAction()
        }!
        item.isEnabled = false
        return item
    }()
    
    private enum RowType {
        case `default`
        case avatar(image: UIImage?)
        case textField(tag: Int, placeholder: String?, delegate: UITextFieldDelegate?)
        case textView(tag: Int, placeholder: String?, delegate: UITextViewDelegate?)
        case withSwitch(isOn: Bool, onValueChanged: ((UISwitch) -> Void)?)
    }
    
    private struct Row {
        var type: RowType
        var text: String?
        var accessoryType: UITableViewCell.AccessoryType = .none
        var action: (() -> Void)?
    }
    
    private struct Section {
        var header: String?
        var rows: [Row]
        var footer: String?
    }
    
    private var sections: [Section] = [] {
        didSet {
            mainTableView.reloadData()
        }
    }
    
    private func showActivityIndicator() {
        if self.activityPresenter.isPresenting == false {
            self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
        }
    }
    
    private func hideActivityIndicator() {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
    }
    
    private func updateSections() {
        let row_0_0 = Row(type: .avatar(image: viewModel.roomCreationParameters.avatarImage), text: nil, accessoryType: .none) {
            // open image picker
        }
        let section0 = Section(header: nil,
                               rows: [row_0_0],
                               footer: nil)
        
        let row_1_0 = Row(type: .textField(tag: Constants.roomNameTextFieldTag, placeholder: "Name", delegate: self), text: viewModel.roomCreationParameters.name, accessoryType: .none) {
            
        }
        let section1 = Section(header: "Room name",
                               rows: [row_1_0],
                               footer: nil)
        
        let row_2_0 = Row(type: .textView(tag: Constants.roomTopicTextViewTag, placeholder: "Topic", delegate: self), text: viewModel.roomCreationParameters.topic, accessoryType: .none) {
            
        }
        let section2 = Section(header: "Room topic (optional)",
                               rows: [row_2_0],
                               footer: nil)
        
        let row_3_0 = Row(type: .withSwitch(isOn: viewModel.roomCreationParameters.isEncrypted, onValueChanged: { (theSwitch) in
            self.viewModel.roomCreationParameters.isEncrypted = theSwitch.isOn
        }), text: "Enable Encryption", accessoryType: .none) {
            // no-op
        }
        let section3 = Section(header: "Room encryption",
                               rows: [row_3_0],
                               footer: "Encryption can’t be disabled afterwards.")
        
        let row_4_0 = Row(type: .default, text: "Private Room", accessoryType: viewModel.roomCreationParameters.isPublic ? .none : .checkmark) {
            self.viewModel.roomCreationParameters.isPublic = false
            self.updateSections()
        }
        let row_4_1 = Row(type: .default, text: "Public Room", accessoryType: viewModel.roomCreationParameters.isPublic ? .checkmark : .none) {
            self.viewModel.roomCreationParameters.isPublic = true
            self.updateSections()
            //  scroll bottom to show user new fields
            DispatchQueue.main.async {
                self.mainTableView.scrollToRow(at: IndexPath(row: 0, section: 6), at: .bottom, animated: true)
            }
        }
        let section4 = Section(header: "Room type",
                               rows: [row_4_0, row_4_1],
                               footer: "People join a private room only with the room invitation.")
        
        var tmpSections: [Section] = [
            section0,
            section1,
            section2,
            section3,
            section4
        ]
        
        if viewModel.roomCreationParameters.isPublic {
            let row_5_0 = Row(type: .withSwitch(isOn: viewModel.roomCreationParameters.showInDirectory, onValueChanged: { (theSwitch) in
                self.viewModel.roomCreationParameters.showInDirectory = theSwitch.isOn
            }), text: "Show the room in the directory", accessoryType: .none) {
                // no-op
            }
            let section5 = Section(header: nil,
                                   rows: [row_5_0],
                                   footer: nil)
            
            let row_6_0 = Row(type: .textField(tag: Constants.roomAddressTextFieldTag, placeholder: "#testroom:matrix.org", delegate: self), text: viewModel.roomCreationParameters.address, accessoryType: .none) {
                
            }
            let section6 = Section(header: "Room address",
                                   rows: [row_6_0],
                                   footer: nil)
            
            tmpSections.append(contentsOf: [section5, section6])
        }
        
        sections = tmpSections
    }
    
    // MARK: - Setup
    
    class func instantiate(with viewModel: EnterNewRoomDetailsViewModelType) -> EnterNewRoomDetailsViewController {
        let viewController = StoryboardScene.EnterNewRoomDetailsViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.keyboardAvoider = KeyboardAvoider(scrollViewContainerView: self.view, scrollView: self.mainTableView)
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
        
        self.viewModel.process(viewAction: .loadData)
        
        updateSections()
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
        
        self.view.backgroundColor = theme.headerBackgroundColor
        self.mainTableView.backgroundColor = theme.headerBackgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        // TODO: Set view colors here
        //        self.informationLabel.textColor = theme.textPrimaryColor
        //
        //        self.doneButton.backgroundColor = theme.backgroundColor
        //        theme.applyStyle(onButton: self.doneButton)
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        
        self.navigationItem.rightBarButtonItem = createBarButtonItem
        
        self.title = "New Room"
        
        mainTableView.keyboardDismissMode = .interactive
        mainTableView.register(cellType: ChooseAvatarTableViewCell.self)
        mainTableView.register(cellType: MXKTableViewCellWithLabelAndSwitch.self)
        mainTableView.register(cellType: MXKTableViewCellWithTextView.self)
        mainTableView.register(cellType: TextFieldTableViewCell.self)
        mainTableView.register(cellType: TextViewTableViewCell.self)
        mainTableView.register(headerFooterViewType: TableViewHeaderFooterView.self)
        mainTableView.sectionHeaderHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionHeaderHeight = 50
        mainTableView.sectionFooterHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionFooterHeight = 50
    }
    
    private func render(viewState: EnterNewRoomDetailsViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(let displayName):
            self.renderLoaded(displayName: displayName)
        case .error(let error):
            self.render(error: error)
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
        //        self.informationLabel.text = "Fetch display name"
    }
    
    private func renderLoaded(displayName: String) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        
        //        self.informationLabel.text = "You display name: \(displayName)"
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions
    
    @IBAction private func doneButtonAction(_ sender: Any) {
        self.viewModel.process(viewAction: .complete)
    }
    
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
    
    private func createButtonAction() {
        self.viewModel.process(viewAction: .create)
    }
}

// MARK: - UITableViewDataSource

extension EnterNewRoomDetailsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row.type {
        case .default:
            var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: Constants.defaultStyleCellReuseIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .default, reuseIdentifier: Constants.defaultStyleCellReuseIdentifier)
            }
            cell.textLabel?.font = .systemFont(ofSize: 17)
            cell.detailTextLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.text = row.text
            if row.accessoryType == .checkmark {
                cell.accessoryView = UIImageView(image: Asset.Images.checkmark.image)
            } else {
                cell.accessoryView = nil
                cell.accessoryType = row.accessoryType
            }
            cell.textLabel?.textColor = theme.textPrimaryColor
            cell.detailTextLabel?.textColor = theme.textSecondaryColor
            cell.backgroundColor = theme.backgroundColor
            cell.contentView.backgroundColor = .clear
            cell.tintColor = theme.tintColor
            return cell
        case .avatar(let image):
            let cell: ChooseAvatarTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.configure(withViewModel: ChooseAvatarTableViewCellVM(avatarImage: image))
            cell.delegate = self
            cell.update(theme: theme)
            
            return cell
        case .textField(let tag, let placeholder, let delegate):
            let cell: TextFieldTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textField.font = .systemFont(ofSize: 17)
            cell.textField.insets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            cell.textField.autocapitalizationType = .words
            cell.textField.tag = tag
            cell.textField.placeholder = placeholder
            cell.textField.text = row.text
            cell.textField.delegate = delegate
            cell.update(theme: theme)
            
            return cell
        case .textView(let tag, let placeholder, let delegate):
            let cell: TextViewTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.textView.tag = tag
            cell.textView.textContainer.lineFragmentPadding = 0
            cell.textView.contentInset = .zero
            cell.textView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            cell.textView.placeholder = placeholder
            cell.textView.font = .systemFont(ofSize: 17)
            cell.textView.text = row.text
            cell.textView.isEditable = true
            cell.textView.isScrollEnabled = false
            cell.textView.delegate = delegate
            cell.textView.backgroundColor = .clear
            cell.update(theme: theme)
            
            return cell
        case .withSwitch(let isOn, let onValueChanged):
            let cell: MXKTableViewCellWithLabelAndSwitch = tableView.dequeueReusableCell(for: indexPath)
            cell.mxkLabel.font = .systemFont(ofSize: 17)
            cell.mxkLabel.text = row.text
            cell.mxkSwitch.isOn = isOn
            cell.mxkSwitch.removeTarget(nil, action: nil, for: .valueChanged)
            cell.mxkSwitch.vc_addAction(for: .valueChanged) {
                onValueChanged?(cell.mxkSwitch)
            }
            cell.mxkLabelLeadingConstraint.constant = cell.vc_separatorInset.left
            cell.mxkSwitchTrailingConstraint.constant = 15
            cell.update(theme: theme)
            
            return cell
        }
    }
    
}

// MARK: - UITableViewDelegate

extension EnterNewRoomDetailsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.backgroundColor
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = theme.selectedBackgroundColor
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = sections[section].header else {
            return nil
        }

        let view: TableViewHeaderFooterView? = tableView.dequeueReusableHeaderFooterView()

        view?.textView.text = header
        view?.textView.font = .systemFont(ofSize: 13)
        view?.textViewInsets = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
        view?.update(theme: theme)

        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = sections[section].footer else {
            return nil
        }

        let view: TableViewHeaderFooterView? = tableView.dequeueReusableHeaderFooterView()

        view?.textView.text = footer
        view?.textView.font = .systemFont(ofSize: 13)
        view?.update(theme: theme)

        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = sections[indexPath.section].rows[indexPath.row]
        row.action?()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        switch row.type {
        case .avatar:
            return 100
        case .textView:
            return 150
        default:
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].header == nil {
            return 18
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if sections[section].footer == nil {
            return 18
        }
        return UITableView.automaticDimension
    }
    
}

// MARK: - ChooseAvatarTableViewCellDelegate

extension EnterNewRoomDetailsViewController: ChooseAvatarTableViewCellDelegate {
    
    func chooseAvatarTableViewCellDidTapChooseAvatar(_ cell: ChooseAvatarTableViewCell) {
        
    }
    
}

// MARK: - EnterNewRoomDetailsViewModelViewDelegate

extension EnterNewRoomDetailsViewController: EnterNewRoomDetailsViewModelViewDelegate {
    
    func enterNewRoomDetailsViewModel(_ viewModel: EnterNewRoomDetailsViewModelType, didUpdateViewState viewSate: EnterNewRoomDetailsViewState) {
        self.render(viewState: viewSate)
    }
}

// MARK: - UITextFieldDelegate

extension EnterNewRoomDetailsViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.tag {
        case Constants.roomNameTextFieldTag:
            viewModel.roomCreationParameters.name = textField.text
            if viewModel.roomCreationParameters.userSelectedAvatar == nil {
                //  if no image selected by the user, set initials as image
                let avatar = AvatarGenerator.generateAvatar(forMatrixItem: nil,
                                                            withDisplayName: textField.text,
                                                            size: 60,
                                                            andFontSize: 30)
                viewModel.roomCreationParameters.initialsAvatar = avatar
            }
        case Constants.roomAddressTextFieldTag:
            viewModel.roomCreationParameters.address = textField.text
        default:
            break
        }
        
        updateSections()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField.tag {
        case Constants.roomNameTextFieldTag:
            let newLength = (textField.text?.count ?? 0) + (string.count - range.length)
            createBarButtonItem.isEnabled = newLength >= Constants.roomNameMinimumNumberOfChars
            return newLength <= Constants.roomNameMaximumNumberOfChars
        case Constants.roomAddressTextFieldTag:
            return (textField.text?.count ?? 0) + (string.count - range.length) <= Constants.roomAddressMaximumNumberOfChars
        default:
            return true
        }
    }
    
}

// MARK: - UITextViewDelegate

extension EnterNewRoomDetailsViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        switch textView.tag {
        case Constants.roomTopicTextViewTag:
            viewModel.roomCreationParameters.topic = textView.text
        default:
            break
        }
        
        updateSections()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        switch textView.tag {
        case Constants.roomTopicTextViewTag:
            return textView.text.count + (text.count - range.length) <= Constants.roomTopicMaximumNumberOfChars
        default:
            return true
        }
    }
    
}
