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

import UIKit

@objc protocol SettingsKeyBackupTableViewSectionDelegate: class {
    func settingsKeyBackupTableViewSectionDidUpdate(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection)

    func settingsKeyBackupTableViewSection(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, textCellForRow: Int) -> MXKTableViewCellWithTextView
    func settingsKeyBackupTableViewSection(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, buttonCellForRow: Int) -> MXKTableViewCellWithButton


    func settingsKeyBackupTableViewSectionShowKeyBackupSetup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion)

    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showActivityIndicator show: Bool)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showError error: Error)
}

@objc final class SettingsKeyBackupTableViewSection: NSObject {

    // MARK: - Properties

    @objc weak var delegate: SettingsKeyBackupTableViewSectionDelegate?

    // MARK: Private

    // This view class holds the model because the model is in pure Swift
    // whereas this class can be used from objC
    private var viewModel: SettingsKeyBackupViewModelType!

    // Need to know the state to make `cellForRow` deliver cells accordingly
    private var viewState: SettingsKeyBackupViewState = .checkingBackup

    private var userDevice: MXDeviceInfo

    // MARK: - Public

    @objc init(withKeyBackup keyBackup: MXKeyBackup, userDevice: MXDeviceInfo) {
        self.viewModel = SettingsKeyBackupViewModel(keyBackup: keyBackup)
        self.userDevice = userDevice
        super.init()
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .load)
    }

    @objc func numberOfRows() -> Int {
        var numberOfRows: Int

        switch self.viewState {
        case .checkingBackup:
            numberOfRows = self.numberOfCheckingBackupRows()
        case .noBackup:
            numberOfRows = self.numberOfNoBackupRows()
        case .backup:
            numberOfRows = self.numberOfBackupRows()
        case .backupAndRunning:
            numberOfRows = self.numberOfBackupAndRunningRows()
        case .backupNotTrusted:
            numberOfRows = self.numberOfBackupNotTrustedRows()
        }

        return numberOfRows
    }

    @objc func cellForRow(atRow row: Int) -> UITableViewCell {
        var cell: UITableViewCell

        switch self.viewState {
        case .checkingBackup:
            cell = self.renderCheckingBackupCell(atRow: row)

        case .noBackup:
            cell = self.renderNoBackupCell(atRow: row)

        case .backup(let keyBackupVersion, let keyBackupVersionTrust):
            cell = self.renderBackupCell(atRow: row,
                                         keyBackupVersion: keyBackupVersion,
                                         keyBackupVersionTrust: keyBackupVersionTrust)

        case .backupAndRunning(let keyBackupVersion, let keyBackupVersionTrust, let backupProgress):
            cell = self.renderBackupAndRunningCell(atRow: row,
                                                   keyBackupVersion: keyBackupVersion,
                                                   keyBackupVersionTrust: keyBackupVersionTrust,
                                                   backupProgress: backupProgress)

        case .backupNotTrusted(let keyBackupVersion, let keyBackupVersionTrust):
            cell = self.renderBackupNotTrustedCell(atRow: row,
                                                   keyBackupVersion: keyBackupVersion,
                                                   keyBackupVersionTrust: keyBackupVersionTrust)
        }

        return cell
    }

    @objc func reload() {
        self.viewModel.process(viewAction: .load)
    }

    @objc func delete(keyBackupVersion: MXKeyBackupVersion) {
        self.viewModel.process(viewAction: .delete(keyBackupVersion))
    }


    // MARK: - Pseudo TableView datasource

    private func numberOfCheckingBackupRows() -> Int {
        return 1
    }

    private func renderCheckingBackupCell(atRow row: Int) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        let cell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

        let info = VectorL10n.settingsKeyBackupInfo
        let checking = VectorL10n.settingsKeyBackupInfoChecking

        let strings = [info, "", checking]
        cell.mxkTextView.text = strings.joined(separator: "\n")

        return cell
    }


    private func numberOfNoBackupRows() -> Int {
        return 2
    }

    private func renderNoBackupCell(atRow row: Int) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        var cell: UITableViewCell
        switch row {
        case 0:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let noBackup = VectorL10n.settingsKeyBackupInfoNone
            let info = VectorL10n.settingsKeyBackupInfo
            let signoutWarning = VectorL10n.settingsKeyBackupInfoSignoutWarning

            let strings = [noBackup, "", info, "", signoutWarning]
            infoCell.mxkTextView.text = strings.joined(separator: "\n")

            cell = infoCell

        case 1:
            cell = self.buttonCellForCreate(atRow: row)

        default:
            cell = UITableViewCell()
        }

        return cell
    }


    private func numberOfBackupRows() -> Int {
        return 5
    }

    private func renderBackupCell(atRow row: Int, keyBackupVersion: MXKeyBackupVersion, keyBackupVersionTrust: MXKeyBackupVersionTrust) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        var cell: UITableViewCell
        switch row {
        case 0:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let info = VectorL10n.settingsKeyBackupInfo
            let backupStatus = VectorL10n.settingsKeyBackupInfoValid

            let strings = [info, "", backupStatus]
            infoCell.mxkTextView.text = strings.joined(separator: "\n")

            cell = infoCell

        case 1:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersion.version ?? "")
            let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)
            let uploadStatus = VectorL10n.settingsKeyBackupInfoProgressDone

            let strings = [version, algorithm, uploadStatus]
            infoCell.mxkTextView.text = strings.joined(separator: "\n")

            cell = infoCell

        case 2:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
            infoCell.mxkTextView.text = backupTrust.joined(separator: "\n")

            cell = infoCell

        case 3:
            cell = self.buttonCellForRestore(keyBackupVersion: keyBackupVersion, atRow: row)

        case 4:
            cell = self.buttonCellForDelete(keyBackupVersion: keyBackupVersion, atRow: row)

        default:
            cell = UITableViewCell()
        }

        return cell
    }


    private func numberOfBackupAndRunningRows() -> Int {
        return 5
    }

    private func renderBackupAndRunningCell(atRow row: Int, keyBackupVersion: MXKeyBackupVersion, keyBackupVersionTrust: MXKeyBackupVersionTrust, backupProgress: Progress) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        var cell: UITableViewCell
        switch row {
        case 0:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: 0)

            let info = VectorL10n.settingsKeyBackupInfo
            let backupStatus = VectorL10n.settingsKeyBackupInfoValid

            let strings = [info, "", backupStatus]
            infoCell.mxkTextView.text = strings.joined(separator: "\n")

            cell = infoCell

        case 1:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let remaining = backupProgress.totalUnitCount - backupProgress.completedUnitCount

            let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersion.version ?? "")
            let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)
            let uploadStatus = VectorL10n.settingsKeyBackupInfoProgress(String(remaining))

            let strings = [version, algorithm, uploadStatus]
            infoCell.mxkTextView.text = strings.joined(separator: "\n")

            cell = infoCell

        case 2:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
            infoCell.mxkTextView.text = backupTrust.joined(separator: "\n")

            cell = infoCell

        case 3:
            cell = self.buttonCellForRestore(keyBackupVersion: keyBackupVersion, atRow: row)

        case 4:
            cell = self.buttonCellForDelete(keyBackupVersion: keyBackupVersion, atRow: row)

        default:
            cell = UITableViewCell()
        }

        return cell
    }


    private func numberOfBackupNotTrustedRows() -> Int {
        return 5
    }

    private func renderBackupNotTrustedCell(atRow row: Int, keyBackupVersion: MXKeyBackupVersion, keyBackupVersionTrust: MXKeyBackupVersionTrust) -> UITableViewCell {
        guard let delegate = self.delegate else {
            return UITableViewCell()
        }

        var cell: UITableViewCell
        switch row {
        case 0:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let info = VectorL10n.settingsKeyBackupInfo
            let backupStatus = VectorL10n.settingsKeyBackupInfoNotValid
            let signoutWarning = VectorL10n.settingsKeyBackupInfoSignoutWarning

            let strings = [info, "", backupStatus, "", signoutWarning]
            infoCell.mxkTextView.text = strings.joined(separator: "\n")

            cell = infoCell

        case 1:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersion.version ?? "")
            let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)

            let strings = [version, algorithm]
            infoCell.mxkTextView.text = strings.joined(separator: "\n")

            cell = infoCell

        case 2:
            let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: row)

            let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust)
            infoCell.mxkTextView.text = backupTrust.joined(separator: "\n")

            cell = infoCell

        case 3:
            cell = self.buttonCellForRestore(keyBackupVersion: keyBackupVersion, atRow: row, title: VectorL10n.settingsKeyBackupButtonUse)

        case 4:
            cell = self.buttonCellForDelete(keyBackupVersion: keyBackupVersion, atRow: row)

        default:
            cell = UITableViewCell()
        }

        return cell
    }


    // MARK: - Data Computing

    private func stringForKeyBackupTrust(_ keyBackupVersionTrust: MXKeyBackupVersionTrust) -> [String] {

        return keyBackupVersionTrust.signatures.map { (signature) -> String in
            guard let device = signature.device else {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureUnknown(signature.deviceId)
            }

            let displayName = device.displayName ?? device.deviceId ?? ""

            if device.fingerprint == self.userDevice.fingerprint {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValid
            } else if signature.valid && (device.verified == MXDeviceVerified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValidDeviceVerified(displayName)
            } else if signature.valid && (device.verified != MXDeviceVerified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValidDeviceUnverified(displayName)
            } else if !signature.valid && (device.verified == MXDeviceVerified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureInvalidDeviceVerified(displayName)
            } else if !signature.valid && (device.verified != MXDeviceVerified) {
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

    private func buttonCellForRestore(keyBackupVersion: MXKeyBackupVersion, atRow row: Int, title: String = VectorL10n.settingsKeyBackupButtonRestore) -> UITableViewCell {
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
