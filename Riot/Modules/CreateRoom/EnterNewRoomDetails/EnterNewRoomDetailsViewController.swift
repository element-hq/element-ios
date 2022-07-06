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
import CommonKit

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
        static let chooseAvatarTableViewCellHeight: CGFloat = 140
        static let textViewTableViewCellHeight: CGFloat = 150
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var mainTableView: UITableView!
    
    // MARK: Private
    
    private var viewModel: EnterNewRoomDetailsViewModelType!
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var userIndicatorPresenter: UserIndicatorTypePresenterProtocol!
    private var loadingIndicator: UserIndicator?
    
    private lazy var createBarButtonItem: MXKBarButtonItem = {
        let title: String
        switch viewModel.actionType {
        case .createAndAddToSpace:
            title = VectorL10n.add
        case .createOnly:
            title = VectorL10n.create
        }
        let item = MXKBarButtonItem(title: title, style: .plain) { [weak self] in
            self?.createButtonAction()
        }!
        item.isEnabled = false
        return item
    }()
    private var screenTracker = AnalyticsScreenTracker(screen: .createRoom)
    
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
    
    private func updateSections() {
        let row_0_0 = Row(type: .avatar(image: viewModel.roomCreationParameters.avatarImage), text: nil, accessoryType: .none) {
            // open image picker
        }
        let section0 = Section(header: nil,
                               rows: [row_0_0],
                               footer: nil)
        
        let row_1_0 = Row(type: .textField(tag: Constants.roomNameTextFieldTag, placeholder: VectorL10n.createRoomPlaceholderName, delegate: self), text: viewModel.roomCreationParameters.name, accessoryType: .none) {
            
        }
        let section1 = Section(header: VectorL10n.createRoomSectionHeaderName,
                               rows: [row_1_0],
                               footer: nil)
        
        let row_2_0 = Row(type: .textView(tag: Constants.roomTopicTextViewTag, placeholder: VectorL10n.createRoomPlaceholderTopic, delegate: self), text: viewModel.roomCreationParameters.topic, accessoryType: .none) {
            
        }
        let section2 = Section(header: VectorL10n.createRoomSectionHeaderTopic,
                               rows: [row_2_0],
                               footer: nil)
        
        var section3: Section?
        if RiotSettings.shared.roomCreationScreenAllowEncryptionConfiguration {
            let row_3_0 = Row(type: .withSwitch(isOn: viewModel.roomCreationParameters.isEncrypted, onValueChanged: { [weak self] (theSwitch) in
                self?.viewModel.roomCreationParameters.isEncrypted = theSwitch.isOn
            }), text: VectorL10n.createRoomEnableEncryption, accessoryType: .none) {
                // no-op
            }
            section3 = Section(header: VectorL10n.createRoomSectionHeaderEncryption,
                                   rows: [row_3_0],
                                   footer: VectorL10n.createRoomSectionFooterEncryption)
        }
        
        var section4: Section?
        if RiotSettings.shared.roomCreationScreenAllowRoomTypeConfiguration {
            let row_4_0 = Row(type: .default, text: VectorL10n.createRoomTypePrivate, accessoryType: viewModel.roomCreationParameters.joinRule == .private ? .checkmark : .none) { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.viewModel.roomCreationParameters.joinRule = .private
                self.updateSections()
            }
            let row_4_1 = Row(type: .default, text: VectorL10n.createRoomTypeRestricted, accessoryType: viewModel.roomCreationParameters.joinRule == .restricted ? .checkmark : .none) { [weak self] in
                
                guard let self = self else {
                    return
                }
                
                self.viewModel.roomCreationParameters.joinRule = .restricted
                self.updateSections()
                //  scroll bottom to show user new fields
                DispatchQueue.main.async {
                    self.mainTableView.vc_scrollToBottom()
                }
            }
            let row_4_2 = Row(type: .default, text: VectorL10n.createRoomTypePublic, accessoryType: viewModel.roomCreationParameters.joinRule == .public ? .checkmark : .none) { [weak self] in
                
                guard let self = self else {
                    return
                }
                
                self.viewModel.roomCreationParameters.joinRule = .public
                self.updateSections()
                //  scroll bottom to show user new fields
                DispatchQueue.main.async {
                    self.mainTableView.vc_scrollToBottom()
                }
            }
            let rows: [Row]
            switch viewModel.actionType {
            case .createAndAddToSpace:
                rows = [row_4_0, row_4_1, row_4_2]
            case .createOnly:
                rows = [row_4_0, row_4_2]
            }
            let footer: String
            switch viewModel.roomCreationParameters.joinRule {
            case .private:
                footer = VectorL10n.createRoomSectionFooterTypePrivate
            case .restricted:
                footer = VectorL10n.createRoomSectionFooterTypeRestricted
            default:
                footer = VectorL10n.createRoomSectionFooterTypePublic
            }
            section4 = Section(header: VectorL10n.createRoomSectionHeaderType,
                                   rows: rows,
                                   footer: footer)
        }
        
        var tmpSections: [Section] = [
            section0,
            section1,
            section2
        ]
        
        if let section3 = section3 {
            tmpSections.append(section3)
        }
        
        if let section4 = section4 {
            tmpSections.append(section4)
        }
        
        if viewModel.roomCreationParameters.joinRule == .public {
            let row_5_0 = Row(type: .withSwitch(isOn: viewModel.roomCreationParameters.showInDirectory, onValueChanged: { [weak self] (theSwitch) in
                self?.viewModel.roomCreationParameters.showInDirectory = theSwitch.isOn
            }), text: VectorL10n.createRoomShowInDirectory, accessoryType: .none) {
                // no-op
            }

            let rows: [Row]
            if viewModel.actionType == .createAndAddToSpace {
                let row_5_1 = Row(type: .withSwitch(isOn: viewModel.roomCreationParameters.isRoomSuggested, onValueChanged: { [weak self] (theSwitch) in
                    self?.viewModel.roomCreationParameters.isRoomSuggested = theSwitch.isOn
                }), text: VectorL10n.createRoomSuggestRoom, accessoryType: .none) {
                    // no-op
                }
                rows = [row_5_0, row_5_1]
            } else {
                rows = [row_5_0]
            }
            
            let section5 = Section(header: VectorL10n.createRoomPromotionHeader,
                                   rows: rows,
                                   footer: VectorL10n.createRoomShowInDirectoryFooter)
            
            let row_6_0 = Row(type: .textField(tag: Constants.roomAddressTextFieldTag, placeholder: VectorL10n.createRoomPlaceholderAddress, delegate: self), text: viewModel.roomCreationParameters.address, accessoryType: .none) {
                
            }
            let section6 = Section(header: VectorL10n.createRoomSectionHeaderAddress,
                                   rows: [row_6_0],
                                   footer: nil)
            
            tmpSections.append(contentsOf: [section5, section6])
        }
        
        if viewModel.roomCreationParameters.joinRule == .restricted {
            let row_5_0 = Row(type: .withSwitch(isOn: viewModel.roomCreationParameters.isRoomSuggested, onValueChanged: { [weak self] (theSwitch) in
                self?.viewModel.roomCreationParameters.isRoomSuggested = theSwitch.isOn
            }), text: VectorL10n.createRoomSuggestRoom, accessoryType: .none) {
                // no-op
            }
            let section5 = Section(header: VectorL10n.createRoomPromotionHeader,
                                   rows: [row_5_0],
                                   footer: VectorL10n.createRoomSuggestRoomFooter)
            tmpSections.append(section5)
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
        self.userIndicatorPresenter = UserIndicatorTypePresenter(presentingViewController: self)
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self
        
        self.viewModel.process(viewAction: .loadData)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.keyboardAvoider?.startAvoiding()
        screenTracker.trackScreen()
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
        
        mainTableView.reloadData()
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
        
        self.title = VectorL10n.createRoomTitle
        
        mainTableView.keyboardDismissMode = .interactive
        mainTableView.register(cellType: ChooseAvatarTableViewCell.self)
        mainTableView.register(cellType: MXKTableViewCellWithLabelAndSwitch.self)
        mainTableView.register(cellType: MXKTableViewCellWithTextView.self)
        mainTableView.register(cellType: TextFieldTableViewCell.self)
        mainTableView.register(cellType: TextViewTableViewCell.self)
        mainTableView.register(headerFooterViewType: TextViewTableViewHeaderFooterView.self)
        mainTableView.sectionHeaderHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionHeaderHeight = 50
        mainTableView.sectionFooterHeight = UITableView.automaticDimension
        mainTableView.estimatedSectionFooterHeight = 50
    }
    
    private func render(viewState: EnterNewRoomDetailsViewState) {
        switch viewState {
        case .loading:
            renderLoading()
        case .loaded:
            updateSections()
        case .error(let error):
            render(error: error)
        }
        
        updateCreateButtonState()
    }
    
    private func renderLoading() {
        loadingIndicator = userIndicatorPresenter.present(.loading(label: VectorL10n.createRoomProcessing, isInteractionBlocking: true))
    }
    
    private func render(error: Error) {
        loadingIndicator = nil
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    // MARK: - Actions
    
    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
    
    private func createButtonAction() {
        self.viewModel.process(viewAction: .create)
    }
    
    private func updateCreateButtonState() {
        switch viewModel.viewState {
        case .loading:
            createBarButtonItem.isEnabled = false
        default:
            createBarButtonItem.isEnabled = (viewModel.roomCreationParameters.name?.count ?? 0 > Constants.roomNameMinimumNumberOfChars)
        }
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
            
            switch tag {
            case Constants.roomAddressTextFieldTag:
                cell.textField.autocapitalizationType = .none
            default: break
            }
            
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
            cell.mxkSwitch.vc_addAction(for: .valueChanged) { [weak cell] in
                guard let cell = cell else {
                    return
                }
                onValueChanged?(cell.mxkSwitch)
            }
            cell.mxkLabelLeadingConstraint.constant = tableView.vc_separatorInset.left
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

        let view: TextViewTableViewHeaderFooterView? = tableView.dequeueReusableHeaderFooterView()

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

        let view: TextViewTableViewHeaderFooterView? = tableView.dequeueReusableHeaderFooterView()

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
            return Constants.chooseAvatarTableViewCellHeight
        case .textView:
            return Constants.textViewTableViewCellHeight
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
    
    func chooseAvatarTableViewCellDidTapChooseAvatar(_ cell: ChooseAvatarTableViewCell, sourceView: UIView) {
        viewModel.process(viewAction: .chooseAvatar(sourceView: sourceView))
    }

    func chooseAvatarTableViewCellDidTapRemoveAvatar(_ cell: ChooseAvatarTableViewCell) {
        viewModel.process(viewAction: .removeAvatar)
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
        case Constants.roomAddressTextFieldTag:
            viewModel.roomCreationParameters.address = textField.text
        default:
            break
        }
        
        updateSections()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text: NSString = (textField.text ?? "") as NSString
        let resultString = text.replacingCharacters(in: range, with: string)
        let resultCount = resultString.count
        
        switch textField.tag {
        case Constants.roomNameTextFieldTag:
            createBarButtonItem.isEnabled = resultCount >= Constants.roomNameMinimumNumberOfChars
            let result = resultCount <= Constants.roomNameMaximumNumberOfChars
            if result {
                viewModel.roomCreationParameters.name = resultString
                updateCreateButtonState()
            }
            return result
        case Constants.roomAddressTextFieldTag:
            let result = resultCount <= Constants.roomAddressMaximumNumberOfChars
            if result {
                viewModel.roomCreationParameters.address = resultString
            }
            return result
        default:
            return true
        }
    }
    
}

// MARK: - UITextViewDelegate

extension EnterNewRoomDetailsViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        switch textView.tag {
        case Constants.roomTopicTextViewTag:
            viewModel.roomCreationParameters.topic = textView.text
        default:
            break
        }
    }
    
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
