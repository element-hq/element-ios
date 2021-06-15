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

@objc protocol SettingsSecureBackupTableViewSectionDelegate: class {
    func settingsSecureBackupTableViewSectionDidUpdate(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection)

    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, textCellForRow: Int) -> MXKTableViewCellWithTextView
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, buttonCellForRow: Int) -> MXKTableViewCellWithButton


    func settingsSecureBackupTableViewSectionShowKeyBackupSetup(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection)
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion)
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion)

    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, showActivityIndicator show: Bool)
    func settingsSecureBackupTableViewSection(_ settingsSecureBackupTableViewSection: SettingsSecureBackupTableViewSection, showError error: Error)
}

private enum BackupRows {
    case info(text: String)
    case setupAction
    case restoreFromKeyBackupAction(keyBackupVersion: MXKeyBackupVersion, title: String)
    case deleteKeyBackupAction(keyBackupVersion: MXKeyBackupVersion)
}

@objc final class SettingsSecureBackupTableViewSection: NSObject {

    // MARK: - Properties

    @objc weak var delegate: SettingsSecureBackupTableViewSectionDelegate?

    // MARK: Private

    // This view class holds the model because the model is in pure Swift
    // whereas this class can be used from objC
    private var viewModel: SettingsSecureBackupViewModelType!

    // Need to know the state to make `cellForRow` deliver cells accordingly
    private var viewState: SettingsSecureBackupViewState = .checkingBackup {
        didSet {
            self.updateBackupRows()
        }
    }

    private var userDevice: MXDeviceInfo
    
    private var backupRows: [BackupRows] = []

    // MARK: - Public

    @objc init(withKeyBackup keyBackup: MXKeyBackup, userDevice: MXDeviceInfo) {
        self.viewModel = SettingsSecureBackupViewModel(keyBackup: keyBackup)
        self.userDevice = userDevice
        super.init()
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .load)
    }
    
    @objc func numberOfRows() -> Int {
        return self.backupRows.count
    }
    
    @objc func cellForRow(atRow row: Int) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }
        
        let backupRow = self.backupRows[row]
        
        var cell: UITableViewCell
        switch backupRow {
        case .info(let infoText):
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsSecureBackupTableViewSection(self, textCellForRow: row)
            infoCell.mxkTextView.text = infoText
            cell = infoCell
        case .setupAction:
            cell = self.buttonCellForSetup(atRow: row)
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
        case .checkingBackup:
            
            let info = VectorL10n.securitySettingsSecureBackupDescription
            let checking = VectorL10n.securitySettingsSecureBackupInfoChecking
            let strings = [info, "", checking]
            let text = strings.joined(separator: "\n")
            
            backupRows = [
                .info(text: text)
            ]
            
        case .noBackup:
            
//            let noBackup = VectorL10n.settingsSecureBackupInfoNone
//            let info = VectorL10n.settingsSecureBackupInfo
//            let signoutWarning = VectorL10n.settingsSecureBackupInfoSignoutWarning
//            let strings = [noBackup, "", info, "", signoutWarning]
//            let backupInfoText = strings.joined(separator: "\n")
            let backupInfoText = "TODO"
            
            backupRows = [
                .info(text: backupInfoText),
                .setupAction
            ]
            
        case .backup(let keyBackupVersion, let keyBackupVersionTrust),
             .backupAndRunning(let keyBackupVersion, let keyBackupVersionTrust, _):
            
            let info = VectorL10n.securitySettingsSecureBackupDescription
            let backupStatus = VectorL10n.securitySettingsSecureBackupInfoValid
            let backupStrings = [info, "", backupStatus]
            let backupInfoText = backupStrings.joined(separator: "\n")
            
//            let version = VectorL10n.settingsSecureBackupInfoVersion(keyBackupVersion.version ?? "")
//            let algorithm = VectorL10n.settingsSecureBackupInfoAlgorithm(keyBackupVersion.algorithm)
//            let uploadStatus = VectorL10n.settingsSecureBackupInfoProgressDone
//            let additionalStrings = [version, algorithm, uploadStatus]
//            let additionalInfoText = additionalStrings.joined(separator: "\n")
//
//            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
//            let backupTrustInfoText = backupTrust.joined(separator: "\n")
            
            var backupViewStateRows: [BackupRows] = [
                .info(text: backupInfoText),
//                .info(text: additionalInfoText),
//                .info(text: backupTrustInfoText)
            ]
            
            // TODO: Do not display restore button if all keys are stored on the device
            if true {
                backupViewStateRows.append(.restoreFromKeyBackupAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.securitySettingsSecureBackupRestore))
            }
            
            backupViewStateRows.append(.deleteKeyBackupAction(keyBackupVersion: keyBackupVersion))
            
            backupRows = backupViewStateRows
            
//        case .backupAndRunning(let keyBackupVersion, let keyBackupVersionTrust, let backupProgress):
//
//            let info = VectorL10n.securitySettingsSecureBackupDescription
//            let backupStatus = VectorL10n.securitySettingsSecureBackupInfoValid
//            let backupStrings = [info, "", backupStatus]
//            let backupInfoText = backupStrings.joined(separator: "\n")
//
//            let remaining = backupProgress.totalUnitCount - backupProgress.completedUnitCount
//            let version = VectorL10n.settingsSecureBackupInfoVersion(keyBackupVersion.version ?? "")
//            let algorithm = VectorL10n.settingsSecureBackupInfoAlgorithm(keyBackupVersion.algorithm)
//            let uploadStatus = VectorL10n.settingsSecureBackupInfoProgress(String(remaining))
//            let additionalStrings = [version, algorithm, uploadStatus]
//            let additionalInfoText = additionalStrings.joined(separator: "\n")
//
//            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
//            let backupTrustInfoText = backupTrust.joined(separator: "\n")
//
//            var backupAndRunningViewStateRows: [BackupRows] = [
//                .info(text: backupInfoText),
//                .info(text: additionalInfoText),
//                .info(text: backupTrustInfoText)
//            ]
//
//            // TODO: Do not display restore button if all keys are stored on the device
//            if true {
//                backupAndRunningViewStateRows.append(.restoreAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.settingsSecureBackupButtonRestore))
//            }
//
//            backupAndRunningViewStateRows.append(.deleteAction(keyBackupVersion: keyBackupVersion))
//
//            backupRows = backupAndRunningViewStateRows
            
        case .backupNotTrusted(let keyBackupVersion, let keyBackupVersionTrust):
            
            // TODO: What?
            let info = VectorL10n.securitySettingsSecureBackupDescription
            backupRows =  [
                .info(text: info)
            ]
            
//            let info = VectorL10n.securitySettingsSecureBackupDescription
//            let backupStatus = VectorL10n.settingsSecureBackupInfoNotValid
//            let signoutWarning = VectorL10n.settingsSecureBackupInfoSignoutWarning
//            let backupStrings = [info, "", backupStatus, "", signoutWarning]
//            let backupInfoText = backupStrings.joined(separator: "\n")
//
//            let version = VectorL10n.settingsSecureBackupInfoVersion(keyBackupVersion.version ?? "")
//            let algorithm = VectorL10n.settingsSecureBackupInfoAlgorithm(keyBackupVersion.algorithm)
//            let additionalStrings = [version, algorithm]
//            let additionalInfoText = additionalStrings.joined(separator: "\n")
//
//            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
//            let backupTrustInfoText = backupTrust.joined(separator: "\n")
//
//            var backupNotTrustedViewStateRows: [BackupRows] = [
//                .info(text: backupInfoText),
//                .info(text: additionalInfoText),
//                .info(text: backupTrustInfoText)
//            ]
//
//            // TODO: Do not display restore button if all keys are stored on the device
//            if true {
//                backupNotTrustedViewStateRows.append(.restoreAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.settingsSecureBackupButtonConnect))
//            }
//
//            backupNotTrustedViewStateRows.append(.deleteAction(keyBackupVersion: keyBackupVersion))
//
//            backupRows = backupNotTrustedViewStateRows
        }
        
        self.backupRows = backupRows
    }

    // MARK: - Button cells

    private func buttonCellForSetup(atRow row: Int) -> UITableViewCell {

        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        let cell: MXKTableViewCellWithButton = delegate.settingsSecureBackupTableViewSection(self, buttonCellForRow: row)

        let btnTitle = VectorL10n.securitySettingsSecureBackupSetup
        cell.mxkButton.setTitle(btnTitle, for: .normal)
        cell.mxkButton.setTitle(btnTitle, for: .highlighted)

        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .setup)
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

    func settingsSecureBackupViewModelShowKeyBackupSetup(_ viewModel: SettingsSecureBackupViewModelType) {
        self.delegate?.settingsSecureBackupTableViewSectionShowKeyBackupSetup(self)
    }

    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion) {
        self.delegate?.settingsSecureBackupTableViewSection(self, showKeyBackupRecover: keyBackupVersion)
    }
    
    func settingsSecureBackupViewModel(_ viewModel: SettingsSecureBackupViewModelType, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion) {
        self.delegate?.settingsSecureBackupTableViewSection(self, showKeyBackupDeleteConfirm: keyBackupVersion)
    }
}
