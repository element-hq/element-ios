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

import Foundation

@objc protocol SettingsDiscoveryTableViewSectionDelegate: AnyObject {
    
    func settingsDiscoveryTableViewSection(_ settingsDiscoveryTableViewSection: SettingsDiscoveryTableViewSection, tableViewCellClass: MXKTableViewCell.Type, forRow: Int) -> MXKTableViewCell
    func settingsDiscoveryTableViewSectionDidUpdate(_ settingsDiscoveryTableViewSection: SettingsDiscoveryTableViewSection)
}

private enum DiscoverySectionRows {
    case button(title: String, action: () -> Void)
    case threePid(threePid: MX3PID)
}

@objc final class SettingsDiscoveryTableViewSection: NSObject, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let defaultFont = UIFont.systemFont(ofSize: 17.0)
    }
    
    // MARK: - Properties
    
    @objc weak var delegate: SettingsDiscoveryTableViewSectionDelegate?
    
    @objc var attributedFooterTitle: NSAttributedString?
    @objc var footerShouldScrollToUserSettings = false
    
    // MARK: Private
    
    private var theme: Theme!
    private var viewModel: SettingsDiscoveryViewModel
    
    // Need to know the state to make `cellForRow` deliver cells accordingly
    private var viewState: SettingsDiscoveryViewState = .loading {
        didSet {
            self.updateRows()
        }
    }
    
    private var discoveryRows: [DiscoverySectionRows] = []
    
    // MARK: - Setup
    
    @objc init(viewModel: SettingsDiscoveryViewModel) {
        self.theme = ThemeService.shared().theme
        self.viewModel = viewModel
        super.init()
        self.viewModel.viewDelegate = self
        
        self.viewModel.process(viewAction: .load)
        
        self.registerThemeServiceDidChangeThemeNotification()
    }
    
    // MARK: - Public
    
    @objc func numberOfRows() -> Int {
        return self.discoveryRows.count
    }
    
    @objc func cellForRow(atRow row: Int) -> UITableViewCell {

        let discoveryRow = self.discoveryRows[row]

        var cell: UITableViewCell?
        
        let enableInteraction: Bool
        
        if case .loading = self.viewState {
            enableInteraction = false
        } else {
            enableInteraction = true
        }
        
        switch discoveryRow {
        case .button(title: let title, action: let action):
            if let buttonCell: MXKTableViewCellWithButton = self.cellType(at: row) {
                buttonCell.mxkButton.setTitle(title, for: .normal)
                buttonCell.mxkButton.setTitle(title, for: .highlighted)
                buttonCell.mxkButton.vc_addAction(action: action)
                buttonCell.mxkButton.isEnabled = enableInteraction
                cell = buttonCell
            }
        case .threePid(let threePid):
            if let detailCell: MXKTableViewCell = self.cellType(at: row) {
                detailCell.vc_setAccessoryDisclosureIndicator(withTheme: self.theme)
                
                let formattedThreePid: String?
                
                switch threePid.medium {
                case .email:
                    formattedThreePid = threePid.address                  
                case .msisdn:
                    formattedThreePid = MXKTools.readableMSISDN(threePid.address)
                default:
                    formattedThreePid = nil
                }
                
                detailCell.textLabel?.text = formattedThreePid
                detailCell.isUserInteractionEnabled = enableInteraction
                cell = detailCell
            }
        }
        
        return cell ?? UITableViewCell()
    }
    
    @objc func reload() {
        self.viewModel.process(viewAction: .load)
    }
    
    @objc func selectRow(_ row: Int) {
        let discoveryRow = self.discoveryRows[row]
        
        switch discoveryRow {
        case .threePid(threePid: let threePid):
            self.viewModel.process(viewAction: .select(threePid: threePid))
        default:
            break
        }
    }
    
    func update(theme: Theme) {
        self.theme = theme
        
        self.updateRows()
    }
    
    // MARK: - Private
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func cellType<T: MXKTableViewCell>(at row: Int) -> T? {
        let klass: T.Type = T.self
        let tableViewCell = delegate?.settingsDiscoveryTableViewSection(self, tableViewCellClass: klass, forRow: row)
        return tableViewCell as? T
    }
    
    private func updateRows() {
        
        // reset the footer
        attributedFooterTitle = nil
        footerShouldScrollToUserSettings = false
        
        let discoveryRows: [DiscoverySectionRows]
        
        switch self.viewState {
        case .loading:
            discoveryRows = self.discoveryRows
        case .loaded(let displayMode):
            switch displayMode {
            case .noIdentityServer:
                discoveryRows = []
                attributedFooterTitle = NSAttributedString(string: VectorL10n.settingsDiscoveryNoIdentityServer)
            case .termsNotSigned(let host):
                discoveryRows = [
                    .button(title: VectorL10n.settingsDiscoveryAcceptTerms, action: { [weak self] in
                        self?.viewModel.process(viewAction: .acceptTerms)
                    })
                ]
                
                attributedFooterTitle = NSAttributedString(string: VectorL10n.settingsDiscoveryTermsNotSigned(host))
            case .noThreePidsAdded:
                discoveryRows = []
                
                attributedFooterTitle = threePidsManagementInfoAttributedString()
                footerShouldScrollToUserSettings = true
            case .threePidsAdded(let emails, let phoneNumbers):
                
                let emailThreePids = emails.map { (email) -> DiscoverySectionRows in
                    return .threePid(threePid: email)
                }
                
                let phoneNumbersThreePids = phoneNumbers.map { (phoneNumber) -> DiscoverySectionRows in
                    return .threePid(threePid: phoneNumber)
                }
                
                discoveryRows = emailThreePids + phoneNumbersThreePids
                
                attributedFooterTitle = threePidsManagementInfoAttributedString()
                footerShouldScrollToUserSettings = true
            }
        case .error:
            discoveryRows = [
                .button(title: VectorL10n.retry, action: { [weak self] in
                    self?.viewModel.process(viewAction: .load)
                })
            ]
            attributedFooterTitle = NSAttributedString(string: VectorL10n.settingsDiscoveryErrorMessage)
        }
        
        self.discoveryRows = discoveryRows
    }
    
    private func threePidsManagementInfoAttributedString() -> NSAttributedString {
        let attributedInfoString = NSMutableAttributedString(string: VectorL10n.settingsDiscoveryThreePidsManagementInformationPart1)
        attributedInfoString.append(NSAttributedString(string: VectorL10n.settingsDiscoveryThreePidsManagementInformationPart2,
                                                       attributes: [.foregroundColor: self.theme.tintColor]))
        attributedInfoString.append(NSAttributedString(string: VectorL10n.settingsDiscoveryThreePidsManagementInformationPart3))
        return attributedInfoString
    }
}

// MARK: - SettingsDiscoveryViewModelViewDelegate
extension SettingsDiscoveryTableViewSection: SettingsDiscoveryViewModelViewDelegate {
    
    func settingsDiscoveryViewModel(_ viewModel: SettingsDiscoveryViewModelType, didUpdateViewState viewState: SettingsDiscoveryViewState) {
        self.viewState = viewState
        
        // The tableview datasource will call `self.cellForRow()`
        self.delegate?.settingsDiscoveryTableViewSectionDidUpdate(self)
    }
}
