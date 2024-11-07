/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import UIKit

@objc protocol SettingsKeyBackupTableViewSectionDelegate: AnyObject {
    func settingsKeyBackupTableViewSectionDidUpdate(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection)

    func settingsKeyBackupTableViewSection(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, textCellForRow: Int) -> MXKTableViewCellWithTextView
    func settingsKeyBackupTableViewSection(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, buttonCellForRow: Int) -> MXKTableViewCellWithButton


    func settingsKeyBackupTableViewSectionShowKeyBackupSetup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion)

    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showActivityIndicator show: Bool)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showError error: Error)
}

private enum BackupRows {
    case info(text: String)
    case createAction
    case restoreAction(keyBackupVersion: MXKeyBackupVersion, title: String)
    case deleteAction(keyBackupVersion: MXKeyBackupVersion)
}

@objc final class SettingsKeyBackupTableViewSection: NSObject {

    // MARK: - Properties

    @objc weak var delegate: SettingsKeyBackupTableViewSectionDelegate?

    // MARK: Private

    // This view class holds the model because the model is in pure Swift
    // whereas this class can be used from objC
    private var viewModel: SettingsKeyBackupViewModelType!

    // Need to know the state to make `cellForRow` deliver cells accordingly
    private var viewState: SettingsKeyBackupViewState = .checkingBackup {
        didSet {
            self.updateBackupRows()
        }
    }

    private var userDevice: MXDeviceInfo
    
    private var backupRows: [BackupRows] = []

    // MARK: - Public

    @objc init(withKeyBackup keyBackup: MXKeyBackup, userDevice: MXDeviceInfo) {
        self.viewModel = SettingsKeyBackupViewModel(keyBackup: keyBackup)
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
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)
            infoCell.mxkTextView.text = infoText
            cell = infoCell
        case .createAction:
            cell = self.buttonCellForCreate(atRow: row)
        case .restoreAction(keyBackupVersion: let keyBackupVersion, let title):
            cell = self.buttonCellForRestore(keyBackupVersion: keyBackupVersion, title: title, atRow: row)
        case .deleteAction(keyBackupVersion: let keyBackupVersion):
            cell = self.buttonCellForDelete(keyBackupVersion: keyBackupVersion, atRow: row)
        }
        
        return cell
    }

    @objc func reload() {
        self.viewModel.process(viewAction: .load)
    }

    @objc func delete(keyBackupVersion: MXKeyBackupVersion) {
        self.viewModel.process(viewAction: .delete(keyBackupVersion))
    }

    // MARK: - Data Computing
    
    private func updateBackupRows() {
        
        let backupRows: [BackupRows]
        
        switch self.viewState {
        case .checkingBackup:
            
            let info = VectorL10n.settingsKeyBackupInfo
            let checking = VectorL10n.settingsKeyBackupInfoChecking
            let strings = [info, "", checking]
            let text = strings.joined(separator: "\n")
            
            backupRows = [
                .info(text: text)
            ]
            
        case .noBackup:
            
            let noBackup = VectorL10n.settingsKeyBackupInfoNone
            let info = VectorL10n.settingsKeyBackupInfo
            let signoutWarning = VectorL10n.settingsKeyBackupInfoSignoutWarning
            let strings = [noBackup, "", info, "", signoutWarning]
            let backupInfoText = strings.joined(separator: "\n")
            
            backupRows = [
                .info(text: backupInfoText),
                .createAction
            ]
            
        case .backup(let keyBackupVersion, let keyBackupVersionTrust):
            
            let info = VectorL10n.settingsKeyBackupInfo
            let backupStatus = VectorL10n.settingsKeyBackupInfoValid
            let backupStrings = [info, "", backupStatus]
            let backupInfoText = backupStrings.joined(separator: "\n")
            
            let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersion.version ?? "")
            let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)
            let uploadStatus = VectorL10n.settingsKeyBackupInfoProgressDone
            let additionalStrings = [version, algorithm, uploadStatus]
            let additionalInfoText = additionalStrings.joined(separator: "\n")
            
            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
            let backupTrustInfoText = backupTrust.joined(separator: "\n")
            
            var backupViewStateRows: [BackupRows] = [
                .info(text: backupInfoText),
                .info(text: additionalInfoText),
                .info(text: backupTrustInfoText)
            ]
            
            // TODO: Do not display restore button if all keys are stored on the device
            if true {
                backupViewStateRows.append(.restoreAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.settingsKeyBackupButtonRestore))
            }
            
            backupViewStateRows.append(.deleteAction(keyBackupVersion: keyBackupVersion))
            
            backupRows = backupViewStateRows
            
        case .backupAndRunning(let keyBackupVersion, let keyBackupVersionTrust, let backupProgress):
            
            let info = VectorL10n.settingsKeyBackupInfo
            let backupStatus = VectorL10n.settingsKeyBackupInfoValid
            let backupStrings = [info, "", backupStatus]
            let backupInfoText = backupStrings.joined(separator: "\n")
            
            let remaining = backupProgress.totalUnitCount - backupProgress.completedUnitCount
            let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersion.version ?? "")
            let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)
            let uploadStatus = VectorL10n.settingsKeyBackupInfoProgress(String(remaining))
            let additionalStrings = [version, algorithm, uploadStatus]
            let additionalInfoText = additionalStrings.joined(separator: "\n")
            
            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
            let backupTrustInfoText = backupTrust.joined(separator: "\n")
            
            var backupAndRunningViewStateRows: [BackupRows] = [
                .info(text: backupInfoText),
                .info(text: additionalInfoText),
                .info(text: backupTrustInfoText)
            ]
            
            // TODO: Do not display restore button if all keys are stored on the device
            if true {
                backupAndRunningViewStateRows.append(.restoreAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.settingsKeyBackupButtonRestore))
            }
            
            backupAndRunningViewStateRows.append(.deleteAction(keyBackupVersion: keyBackupVersion))
            
            backupRows = backupAndRunningViewStateRows
            
        case .backupNotTrusted(let keyBackupVersion, let keyBackupVersionTrust):
            
            let info = VectorL10n.settingsKeyBackupInfo
            let backupStatus = VectorL10n.settingsKeyBackupInfoNotValid
            let signoutWarning = VectorL10n.settingsKeyBackupInfoSignoutWarning
            let backupStrings = [info, "", backupStatus, "", signoutWarning]
            let backupInfoText = backupStrings.joined(separator: "\n")
            
            let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersion.version ?? "")
            let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)
            let additionalStrings = [version, algorithm]
            let additionalInfoText = additionalStrings.joined(separator: "\n")
            
            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
            let backupTrustInfoText = backupTrust.joined(separator: "\n")
            
            var backupNotTrustedViewStateRows: [BackupRows] = [
                .info(text: backupInfoText),
                .info(text: additionalInfoText),
                .info(text: backupTrustInfoText)
            ]
            
            // TODO: Do not display restore button if all keys are stored on the device
            if true {
                backupNotTrustedViewStateRows.append(.restoreAction(keyBackupVersion: keyBackupVersion, title: VectorL10n.settingsKeyBackupButtonConnect))
            }
            
            backupNotTrustedViewStateRows.append(.deleteAction(keyBackupVersion: keyBackupVersion))
            
            backupRows = backupNotTrustedViewStateRows
        }
        
        self.backupRows = backupRows
    }

    private func stringForKeyBackupTrust(_ keyBackupVersionTrust: MXKeyBackupVersionTrust) -> [String] {

        return keyBackupVersionTrust.signatures.map { (signature) -> String in
            guard let device = signature.device else {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureUnknown(signature.deviceId)
            }

            let displayName = device.displayName ?? device.deviceId ?? ""

            if device.fingerprint == self.userDevice.fingerprint {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValid
            } else if signature.valid
                && (device.trustLevel.localVerificationStatus == .verified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValidDeviceVerified(displayName)
            } else if signature.valid
                && (device.trustLevel.localVerificationStatus != .verified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValidDeviceUnverified(displayName)
            } else if !signature.valid
                && (device.trustLevel.localVerificationStatus == .verified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureInvalidDeviceVerified(displayName)
            } else if !signature.valid
                && (device.trustLevel.localVerificationStatus != .verified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureInvalidDeviceUnverified(displayName)
            }

            return ""
        }
    }

    // MARK: - Button cells

    private func buttonCellForCreate(atRow row: Int) -> UITableViewCell {

        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        let cell: MXKTableViewCellWithButton = delegate.settingsKeyBackupTableViewSection(self, buttonCellForRow: row)

        let btnTitle = VectorL10n.settingsKeyBackupButtonCreate
        cell.mxkButton.setTitle(btnTitle, for: .normal)
        cell.mxkButton.setTitle(btnTitle, for: .highlighted)

        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .create)
        }

        return cell
    }

    private func buttonCellForRestore(keyBackupVersion: MXKeyBackupVersion, title: String, atRow row: Int) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        let cell: MXKTableViewCellWithButton = delegate.settingsKeyBackupTableViewSection(self, buttonCellForRow: row)
        cell.mxkButton.setTitle(title, for: .normal)
        cell.mxkButton.setTitle(title, for: .highlighted)
        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .restore(keyBackupVersion))
        }
        return cell
    }

    private func buttonCellForDelete(keyBackupVersion: MXKeyBackupVersion, atRow row: Int) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        let cell: MXKTableViewCellWithButton = delegate.settingsKeyBackupTableViewSection(self, buttonCellForRow: row)
        let btnTitle = VectorL10n.settingsKeyBackupButtonDelete
        cell.mxkButton.setTitle(btnTitle, for: .normal)
        cell.mxkButton.setTitle(btnTitle, for: .highlighted)
        cell.mxkButton.tintColor = ThemeService.shared().theme.warningColor
        cell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .confirmDelete(keyBackupVersion))
        }

        return cell
    }
}


// MARK: - KeyBackupSetupRecoveryKeyViewModelViewDelegate
extension SettingsKeyBackupTableViewSection: SettingsKeyBackupViewModelViewDelegate {
    func settingsKeyBackupViewModel(_ viewModel: SettingsKeyBackupViewModelType, didUpdateViewState viewState: SettingsKeyBackupViewState) {
        self.viewState = viewState

        // The tableview datasource will call `self.cellForRow()`
        self.delegate?.settingsKeyBackupTableViewSectionDidUpdate(self)
    }

    func settingsKeyBackupViewModel(_ viewModel: SettingsKeyBackupViewModelType, didUpdateNetworkRequestViewState networkRequestViewSate: SettingsKeyBackupNetworkRequestViewState) {
        switch networkRequestViewSate {
        case .loading:
            self.delegate?.settingsKeyBackup(self, showActivityIndicator: true)
        case .loaded:
            self.delegate?.settingsKeyBackup(self, showActivityIndicator: false)
        case .error(let error):
            self.delegate?.settingsKeyBackup(self, showError: error)
        }
    }

    func settingsKeyBackupViewModelShowKeyBackupSetup(_ viewModel: SettingsKeyBackupViewModelType) {
        self.delegate?.settingsKeyBackupTableViewSectionShowKeyBackupSetup(self)
    }

    func settingsKeyBackup(_ viewModel: SettingsKeyBackupViewModelType, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion) {
        self.delegate?.settingsKeyBackup(self, showKeyBackupRecover: keyBackupVersion)
    }
    
    func settingsKeyBackup(_ viewModel: SettingsKeyBackupViewModelType, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion) {
        self.delegate?.settingsKeyBackup(self, showKeyBackupDeleteConfirm: keyBackupVersion)
    }
}
