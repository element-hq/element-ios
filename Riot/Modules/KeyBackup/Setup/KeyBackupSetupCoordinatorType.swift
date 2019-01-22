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

@objc protocol KeyBackupSetupCoordinatorDelegate: class {
    func keyBackupSetupCoordinatorDidCancel(_ keyBackupSetupCoordinator: KeyBackupSetupCoordinator)
    func keyBackupSetupCoordinatorDidSetupRecoveryKey(_ keyBackupSetupCoordinator: KeyBackupSetupCoordinator)
}

/// `KeyBackupSetupCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol KeyBackupSetupCoordinatorType: Coordinator, Presentable {
    var delegate: KeyBackupSetupCoordinatorDelegate? { get }
}
