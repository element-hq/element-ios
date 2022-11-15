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

@objc protocol SettingsSecureBackupTableViewSectionDelegate: AnyObject {
    // Table view rendering
    func settingsSecureBackupTableViewSectionDidUpdate(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection)

    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, textCellForRow: Int) -> MXKTableViewCellWithTextView
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, buttonCellForRow: Int) -> MXKTableViewCellWithButton

    // Secure backup
    func settingsSecureBackupTableViewSectionShowSecureBackupReset(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection)

    // Key backup
    func settingsSecureBackupTableViewSectionShowKeyBackupCreate(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection)
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion)
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion)

    // Life cycle
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, showActivityIndicator show: Bool)
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, showError error: Error)
}

private enum BackupRows {
    case info(text: String)
    case createSecureBackupAction
    case resetSecureBackupAction
    case createKeyBackupAction
    case restoreFromKeyBackupAction(keyBackupVersion: MXKeyBackupVersion, title: String)
    case deleteKeyBackupAction(keyBackupVersion: MXKeyBackupVersion)
}

/// SettingsSecureBackupTableViewSection provides UITableViewCells to manage secure backup and key backup.
///
/// All states are described in SettingsSecureBackupViewState.
/// All actions in SettingsSecureBackupViewAction.
@objc final class SettingsSecureBackupTableViewSection: NSObject {

    // MARK: - Properties

    @objc weak var delegate: SettingsSecureBackupTableViewSectionDelegate?

    // MARK: Private

    // This view class holds the model because the model is in pure Swift
    // whereas this class can be used from objC
    private var viewModel: SettingsSecureBackupViewModelType!

    // Need to know the state to make `cellForRow` deliver cells accordingly
    private var viewState: SettingsSecureBackupViewState = .loading {
        didSet {
            self.updateBackupRows()
        }
    }

    private var userDevice: MXDeviceInfo
    
    private var backupRows: [BackupRows] = []

    // MARK: - Public

    @objc init(withRecoveryService recoveryService: MXRecoveryService, keyBackup: MXKeyBackup, userDevice: MXDeviceInfo) {
        self.viewModel = SettingsSecureBackupViewModel(recoveryService: recoveryService, keyBackup: keyBackup)
        self.userDevice = userDevice
        super.init()
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .load)
    }
    
    @objc func numberOfRows() -> Int {
        return self.backupRows.count
    }
    
    @objc func cellForRow(atRow row: Int) -> UITableViewCell {
        let backupRow = self.backupRows[row]
        
        var cell: UITableViewCell
        switch backupRow {
        case .info(let text):
            cell = self.textCell(atRow: row, text: text)
        case .createSecureBackupAction:
            cell = self.buttonCellForCreateSecureBackup(atRow: row)
        case .resetSecureBackupAction:
            cell = self.buttonCellForResetSecureBackup(atRow: row)
        case .createKeyBackupAction:
            cell = self.buttonCellForCreateKeyBackup(atRow: row)
        case .restoreFromKeyBackupAction(keyBackupVersion: let keyBackupVersion, let title):
            cell = self.buttonCellForRestoreFromKeyBackup(keyBackupVersion: keyBackupVersion, title: title, atRow: row)
        case .deleteKeyBackupAction(keyBackupVersion: let keyBackupVersion):
            cell = self.buttonCellForDeleteKeyBackup(keyBackupVersion: keyBackupVersion, atRow: row)
        }
        
        return cell
    }

    @objc func reload() {
        self.viewModel.process(viewAction: .load)
    }

    @objc func deleteKeyBackup(keyBackupVersion: MXKeyBackupVersion) {
        self.viewModel.process(viewAction: .deleteKeyBackup(keyBackupVersion))
    }

    // MARK: - Data Computing
    
    private func updateBackupRows() {
        
        let backupRows: [BackupRows]
        
        switch self.viewState {
        case .loading:
            backupRows = [
                .info(text: VectorL10n.securitySettingsSecureBackupInfoChecking)
            ]
            
        case .noSecureBackup(let keyBackupState):
            switch keyBackupState {
            case .noKeyBackup:
                let noBackup = VectorL10n.settingsKeyBackupInfoNone
                let signoutWarning = VectorL10n.settingsKeyBackupInfoSignoutWarning
                let infoText = [noBackup, signoutWarning].joined(separator: "\n")
                
                backupRows = [
                    .info(text: infoText),
                    .createSecureBackupAction
                ]
            case .keyBackup(let keyBackupVersion, _, let progress):
                if let progress = progress {
                    backupRows = [
                        .info(text: importProgressText(for: progress)),
                        .deleteKeyBackupAction(keyBackupVersion: keyBackupVersion)
                    ]
                } else {
                    backupRows = [
                        .info(text: VectorL10n.securitySettingsSecureBackupInfoValid),
                        .restoreFromKeyBackupAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.securitySettingsSecureBackupRestore),
                        .deleteKeyBackupAction(keyBackupVersion: keyBackupVersion)
                    ]
                }
            case .keyBackupNotTrusted(let keyBackupVersion, _):
                backupRows = [
                    .info(text: VectorL10n.securitySettingsSecureBackupInfoValid),
                    .restoreFromKeyBackupAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.securitySettingsSecureBackupRestore),
                    .deleteKeyBackupAction(keyBackupVersion: keyBackupVersion)
                ]
            }
        case .secureBackup(let keyBackupState):
            switch keyBackupState {
            case .noKeyBackup:
                let noBackup = VectorL10n.settingsKeyBackupInfoNone
                let signoutWarning = VectorL10n.settingsKeyBackupInfoSignoutWarning
                let infoText = [noBackup, signoutWarning].joined(separator: "\n")
                
                backupRows = [
                    .info(text: infoText),
                    .createKeyBackupAction,
                    .resetSecureBackupAction
                ]
            case .keyBackup(let keyBackupVersion, _, let progress):
                if let progress = progress {
                    backupRows = [
                        .info(text: importProgressText(for: progress)),
                        .deleteKeyBackupAction(keyBackupVersion: keyBackupVersion),
                        .resetSecureBackupAction
                    ]
                } else {
                    backupRows = [
                        .info(text: VectorL10n.securitySettingsSecureBackupInfoValid),
                        .restoreFromKeyBackupAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.securitySettingsSecureBackupRestore),
                        .deleteKeyBackupAction(keyBackupVersion: keyBackupVersion),
                        .resetSecureBackupAction
                    ]
                }
            case .keyBackupNotTrusted(let keyBackupVersion, _):
                backupRows = [
                    .info(text: VectorL10n.securitySettingsSecureBackupInfoValid),
                    .restoreFromKeyBackupAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.securitySettingsSecureBackupRestore),
                    .deleteKeyBackupAction(keyBackupVersion: keyBackupVersion),
                    .resetSecureBackupAction
                ]
            }
        }
        self.backupRows = backupRows
    }
    
    private func importProgressText(for progress: Progress) -> String {
        let percentage = Int(round(progress.fractionCompleted * 100))
        return VectorL10n.keyBackupRecoverFromPrivateKeyInfo + " \(percentage)%"
    }

    // MARK: - Cells -
    
    private func textCell(atRow row: Int, text: String) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }
        
        let cell = delegate.settingsSecureBackupTableViewSection(self, textCellForRow: row)
        cell.mxkTextView.text = text
        return cell
    }
    
    // MARK: - Button cells
    
    private func buttonCellForCreateSecureBackup(atRow row: Int) -> UITableViewCell {
        
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }
        
        let cell: MXKTableViewCellWithButton = delegate.settingsSecureBackupTableViewSection(self, buttonCellForRow: row)
        
        let btnTitle = VectorL10n.securitySettingsSecureBackupSetup
        cell.mxkButton.setTitle(btnTitle, for: .normal)
        cell.mxkButton.setTitle(btnTitle, for: .highlighted)
        
        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .createSecureBackup)
        }
        
        return cell
    }
    
    private func buttonCellForResetSecureBackup(atRow row: Int) -> UITableViewCell {
        
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }
        
        let cell: MXKTableViewCellWithButton = delegate.settingsSecureBackupTableViewSection(self, buttonCellForRow: row)
        
        let btnTitle = VectorL10n.securitySettingsSecureBackupReset
        cell.mxkButton.setTitle(btnTitle, for: .normal)
        cell.mxkButton.setTitle(btnTitle, for: .highlighted)
        cell.mxkButton.tintColor = ThemeService.shared().theme.warningColor
        
        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .resetSecureBackup)
        }
        
        return cell
    }

    private func buttonCellForCreateKeyBackup(atRow row: Int) -> UITableViewCell {

        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        let cell: MXKTableViewCellWithButton = delegate.settingsSecureBackupTableViewSection(self, buttonCellForRow: row)

        let btnTitle = VectorL10n.securitySettingsSecureBackupSetup
        cell.mxkButton.setTitle(btnTitle, for: .normal)
        cell.mxkButton.setTitle(btnTitle, for: .highlighted)

        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .createKeyBackup)
        }

        return cell
    }

    private func buttonCellForRestoreFromKeyBackup(keyBackupVersion: MXKeyBackupVersion, title: String, atRow row: Int) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        let cell: MXKTableViewCellWithButton = delegate.settingsSecureBackupTableViewSection(self, buttonCellForRow: row)
        cell.mxkButton.setTitle(title, for: .normal)
        cell.mxkButton.setTitle(title, for: .highlighted)
        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .restoreFromKeyBackup(keyBackupVersion))
        }
        return cell
    }

    private func buttonCellForDeleteKeyBackup(keyBackupVersion: MXKeyBackupVersion, atRow row: Int) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        let cell: MXKTableViewCellWithButton = delegate.settingsSecureBackupTableViewSection(self, buttonCellForRow: row)
        let btnTitle = VectorL10n.securitySettingsSecureBackupDelete
        cell.mxkButton.setTitle(btnTitle, for: .normal)
        cell.mxkButton.setTitle(btnTitle, for: .highlighted)
        cell.mxkButton.tintColor = ThemeService.shared().theme.warningColor
        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .confirmDeleteKeyBackup(keyBackupVersion))
        }

        return cell
    }
}


// MARK: - KeyBackupSetupRecoveryKeyViewModelViewDelegate
extension SettingsSecureBackupTableViewSection: SettingsSecureBackupViewModelViewDelegate {
    
    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, didUpdateViewState viewState: SettingsSecureBackupViewState) {
        self.viewState = viewState

        // The tableview datasource will call `self.cellForRow()`
        self.delegate?.settingsSecureBackupTableViewSectionDidUpdate(self)
    }

    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, didUpdateNetworkRequestViewState networkRequestViewSate: SettingsSecureBackupNetworkRequestViewState) {
        switch networkRequestViewSate {
        case .loading:
            self.delegate?.settingsSecureBackupTableViewSection(self, showActivityIndicator: true)
        case .loaded:
            self.delegate?.settingsSecureBackupTableViewSection(self, showActivityIndicator: false)
        case .error(let error):
            self.delegate?.settingsSecureBackupTableViewSection(self, showError: error)
        }
    }
    
    func settingsSecureBackupViewModelShowSecureBackupReset(_ viewModel: SettingsSecureBackupViewModelType) {
        self.delegate?.settingsSecureBackupTableViewSectionShowSecureBackupReset(self)
    }

    func settingsSecureBackupViewModelShowKeyBackupCreate(_ viewModel: SettingsSecureBackupViewModelType) {
        self.delegate?.settingsSecureBackupTableViewSectionShowKeyBackupCreate(self)
    }

    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion) {
        self.delegate?.settingsSecureBackupTableViewSection(self, showKeyBackupRecover: keyBackupVersion)
    }
    
    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion) {
        self.delegate?.settingsSecureBackupTableViewSection(self, showKeyBackupDeleteConfirm: keyBackupVersion)
    }
}
