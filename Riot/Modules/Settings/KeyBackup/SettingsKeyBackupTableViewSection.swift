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
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showVerifyDevice deviceId:String)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showKeyBackupRecover keyBackupVersion:MXKeyBackupVersion)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showKeyBackupDeleteConfirm keyBackupVersion:MXKeyBackupVersion)

    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showActivityIndicator show:Bool)
    func settingsKeyBackup(_ settingsKeyBackupTableViewSection: SettingsKeyBackupTableViewSection, showError error:Error)
}

@objc class SettingsKeyBackupTableViewSection: NSObject {

    // MARK: - Properties

    @objc weak var delegate: SettingsKeyBackupTableViewSectionDelegate?
    @objc var tableViewCells: [UITableViewCell]

    // MARK: Private

    // This view class holds the model because the model is in pure Swift
    // whereas this class can be used from objC
    private var viewModel: SettingsKeyBackupViewModelType!

    // MARK: - Public

    @objc init(withKeyBackup keyBackup: MXKeyBackup) {
        self.tableViewCells = []
        self.viewModel = SettingsKeyBackupViewModel(keyBackup: keyBackup)
        super.init()
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .load)
    }

    @objc func reload() {
        self.viewModel.process(viewAction: .load)
    }

    @objc func delete(keyBackupVersion: MXKeyBackupVersion) {
        self.viewModel.process(viewAction: .delete(keyBackupVersion))
    }

    // MARK: - Private

    private func render(viewState: SettingsKeyBackupViewState) {

        guard let delegate = self.delegate else {
            return
        }

        switch viewState {
        case .checkingBackup:
            self.renderLoading()

        case .noBackup:
            self.renderNoKeyBackup()

        case .backup(let keyBackupVersion, let keyBackupVersionTrust):
            self.renderKeyBackup(keyBackupVersion, keyBackupVersionTrust: keyBackupVersionTrust)

        case .backupAndRunning(let keyBackupVersion, let keyBackupVersionTrust, let backupProgress):
            self.renderRunningKeyBackup(keyBackupVersion, keyBackupVersionTrust: keyBackupVersionTrust, backupProgress: backupProgress)

        case .backupButNotTrusted(let keyBackupVersion, let keyBackupVersionTrust):
            self.renderNotTrustedKeyBackup(keyBackupVersion, keyBackupVersionTrust: keyBackupVersionTrust)
        }

        delegate.settingsKeyBackupTableViewSectionDidUpdate(self)
    }

    private func renderLoading() {
        // TODO: loading wheel
        self.tableViewCells = []
    }

    private func renderNoKeyBackup() {
        guard let delegate = self.delegate else {
            return
        }

        let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: 0)
        infoCell.mxkTextView.text = VectorL10n.settingsKeyBackupInfoNone

        self.tableViewCells = [infoCell]

        // Add buttons
        self.tableViewCells = [infoCell] + self.buttonCellForCreate(fromCellIndex: self.tableViewCells.count)
    }

    private func renderKeyBackup(_ keyBackupVersion:MXKeyBackupVersion, keyBackupVersionTrust:MXKeyBackupVersionTrust) {

        guard let delegate = self.delegate,
            let keyBackupVersionVersion = keyBackupVersion.version else {
            return
        }

        let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: 0)

        let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersionVersion)
        let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)
        let backupStatus = VectorL10n.settingsKeyBackupInfoValid
        let uploadStatus = VectorL10n.settingsKeyBackupInfoProgressDone
        let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust);

        let strings = [version, algorithm, backupStatus, uploadStatus] + backupTrust
        infoCell.mxkTextView.text = strings.joined(separator: "\n")

        // Add buttons
        self.tableViewCells = [infoCell] + self.buttonCellsForRestoreAndDelete(keyBackupVersion, fromCellIndex: self.tableViewCells.count)
    }

    private func renderRunningKeyBackup(_ keyBackupVersion:MXKeyBackupVersion, keyBackupVersionTrust:MXKeyBackupVersionTrust, backupProgress:Progress) {

        guard let delegate = self.delegate,
            let keyBackupVersionVersion = keyBackupVersion.version else {
                return
        }

        let remaining = backupProgress.totalUnitCount - backupProgress.completedUnitCount

        let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: 0)

        let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersionVersion)
        let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)
        let backupStatus = VectorL10n.settingsKeyBackupInfoValid
        let uploadStatus = VectorL10n.settingsKeyBackupInfoProgress(String(remaining))
        let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust);

        let strings = [version, algorithm, backupStatus, uploadStatus] + backupTrust
        infoCell.mxkTextView.text = strings.joined(separator: "\n")

        // Add buttons
        self.tableViewCells = [infoCell] + self.buttonCellsForRestoreAndDelete(keyBackupVersion, fromCellIndex: 1)
    }


    private func renderNotTrustedKeyBackup(_ keyBackupVersion:MXKeyBackupVersion, keyBackupVersionTrust:MXKeyBackupVersionTrust) {

        guard let delegate = self.delegate,
            let keyBackupVersionVersion = keyBackupVersion.version else {
                return
        }

        let infoCell: MXKTableViewCellWithTextView = delegate.settingsKeyBackupTableViewSection(self, textCellForRow: 0)

        let version = VectorL10n.settingsKeyBackupInfoVersion(keyBackupVersionVersion)
        let algorithm = VectorL10n.settingsKeyBackupInfoAlgorithm(keyBackupVersion.algorithm)
        let backupStatus = VectorL10n.settingsKeyBackupInfoNotValid
        let backupTrust = self.stringForKeyBackupTrust(keyBackupVersionTrust);

        let strings = [version, algorithm, backupStatus] + backupTrust
        infoCell.mxkTextView.text = strings.joined(separator: "\n")

        self.tableViewCells = [infoCell]

        // Display a verify button for the last non verified device only
        let deviceId = self.lastNonVerifiedDevice(keyBackupVersionTrust)
        self.tableViewCells = self.tableViewCells + self.buttonCellForVerifyingDevice(deviceId, fromCellIndex: self.tableViewCells.count)

        // Add buttons
        self.tableViewCells = self.tableViewCells + self.buttonCellsForRestoreAndDelete(keyBackupVersion, fromCellIndex: self.tableViewCells.count)
    }


    // MARK: - Data Computing

    private func stringForKeyBackupTrust(_ keyBackupVersionTrust: MXKeyBackupVersionTrust) -> [String] {

        return keyBackupVersionTrust.signatures.map { (signature) -> String in
            guard let device = signature.device else {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureUnknown(signature.deviceId)
            }

            let displayName = device.displayName ?? device.deviceId ?? ""

            if device.fingerprint == "" { // TODO
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValid
            }
            else if signature.valid && (device.verified == MXDeviceVerified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValidDeviceVerified(displayName)
            }
            else if signature.valid && (device.verified != MXDeviceVerified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureValidDeviceUnverified(displayName)
            }
            else if !signature.valid && (device.verified == MXDeviceVerified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureInvalidDeviceVerified(displayName)
            }
            else if !signature.valid && (device.verified != MXDeviceVerified) {
                return VectorL10n.settingsKeyBackupInfoTrustSignatureInvalidDeviceUnverified(displayName)
            }

            return "";
        }
    }

    private func lastNonVerifiedDevice(_ keyBackupVersionTrust:MXKeyBackupVersionTrust) -> String?
    {
        var lastNonVerifiedDeviceId: String?
        for signature in keyBackupVersionTrust.signatures.reversed() {

            guard let device = signature.device else {
                continue
            }

            if device.verified != MXDeviceVerified
            {
                lastNonVerifiedDeviceId = device.deviceId
                break
            }
        }
        return lastNonVerifiedDeviceId
    }

    // MARK: - Cells

    private func buttonCellForCreate(fromCellIndex: Int = 0) -> [MXKTableViewCellWithButton] {

        guard let delegate = self.delegate else {
            return []
        }

        let verifyCell:MXKTableViewCellWithButton = delegate.settingsKeyBackupTableViewSection(self, buttonCellForRow: self.tableViewCells.count)

        let btnTitle = "Start a new backup"
        verifyCell.mxkButton.setTitle(btnTitle, for: .normal)
        verifyCell.mxkButton.setTitle(btnTitle, for: .highlighted)

        verifyCell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .create)
        }

        return [verifyCell]
    }

    private func buttonCellForVerifyingDevice(_ deviceId: String?, fromCellIndex: Int = 0) -> [MXKTableViewCellWithButton] {

        guard let deviceId = deviceId, let delegate = self.delegate else {
            return []
        }

        let verifyCell:MXKTableViewCellWithButton = delegate.settingsKeyBackupTableViewSection(self, buttonCellForRow: self.tableViewCells.count)

        let btnTitle = "Verify..."
        verifyCell.mxkButton.setTitle(btnTitle, for: .normal)
        verifyCell.mxkButton.setTitle(btnTitle, for: .highlighted)

        verifyCell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .verify(deviceId))
        }

        return [verifyCell]
    }

    private func buttonCellsForRestoreAndDelete(_ keyBackupVersion: MXKeyBackupVersion, fromCellIndex: Int = 0) -> [MXKTableViewCellWithButton] {
        guard let delegate = self.delegate else {
            return []
        }

        let restoreCell:MXKTableViewCellWithButton = delegate.settingsKeyBackupTableViewSection(self, buttonCellForRow: fromCellIndex)
        let restoreTitle = "Restore backup"
        restoreCell.mxkButton.setTitle(restoreTitle, for: .normal)
        restoreCell.mxkButton.setTitle(restoreTitle, for: .highlighted)
        restoreCell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .restore(keyBackupVersion))
        }

        let deleteCell:MXKTableViewCellWithButton = delegate.settingsKeyBackupTableViewSection(self, buttonCellForRow: fromCellIndex + 1)
        let deleteTitle = VectorL10n.settingsKeyBackupButtonDelete
        deleteCell.mxkButton.setTitle(deleteTitle, for: .normal)
        deleteCell.mxkButton.setTitle(deleteTitle, for: .highlighted)
        deleteCell.mxkButton.tintColor = ThemeService.shared().theme.warningColor
        deleteCell.mxkButton.vc_addAction {
            self.viewModel.process(viewAction: .confirmDelete(keyBackupVersion))
        }

        return [restoreCell, deleteCell]
    }
}

// MARK: - KeyBackupSetupRecoveryKeyViewModelViewDelegate
extension SettingsKeyBackupTableViewSection: SettingsKeyBackupViewModelViewDelegate {
    func settingsKeyBackupViewModel(_ viewModel: SettingsKeyBackupViewModelType, didUpdateViewState viewSate: SettingsKeyBackupViewState) {
        self.render(viewState: viewSate)
    }
    func settingsKeyBackupViewModel(_ viewModel: SettingsKeyBackupViewModelType, didUpdateNetworkRequestViewState networkRequestViewSate: SettingsKeyBackupNetworkRequestViewState) {
        switch networkRequestViewSate {
        case .loading:
            self.delegate?.settingsKeyBackup(self, showActivityIndicator: true)
        case .loaded:
            self.delegate?.settingsKeyBackup(self, showActivityIndicator: false)
        case .error(let error):
            self.delegate?.settingsKeyBackup(self, showError: error)
            break
        }
    }

    func settingsKeyBackupViewModelShowKeyBackupSetup(_ viewModel: SettingsKeyBackupViewModelType) {
        self.delegate?.settingsKeyBackupTableViewSectionShowKeyBackupSetup(self)
    }
    func settingsKeyBackup(_ viewModel: SettingsKeyBackupViewModelType, showVerifyDevice deviceId: String) {
        self.delegate?.settingsKeyBackup(self, showVerifyDevice: deviceId)
    }
    func settingsKeyBackup(_ viewModel: SettingsKeyBackupViewModelType, showKeyBackupRecover keyBackupVersion: MXKeyBackupVersion) {
        self.delegate?.settingsKeyBackup(self, showKeyBackupRecover: keyBackupVersion)
    }
    func settingsKeyBackup(_ viewModel: SettingsKeyBackupViewModelType, showKeyBackupDeleteConfirm keyBackupVersion: MXKeyBackupVersion) {
        self.delegate?.settingsKeyBackup(self, showKeyBackupDeleteConfirm: keyBackupVersion)
    }
}
