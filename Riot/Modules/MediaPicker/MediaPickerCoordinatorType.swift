// File created from FlowTemplate
// $ createRootCoordinator.sh Test MediaPicker
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

protocol MediaPickerCoordinatorDelegate: AnyObject {
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectImageData imageData: Data, withUTI uti: MXKUTI?)
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectVideo videoAsset: AVAsset)
    func mediaPickerCoordinator(_ coordinator: MediaPickerCoordinatorType, didSelectAssets assets: [PHAsset])
    func mediaPickerCoordinatorDidCancel(_ coordinator: MediaPickerCoordinatorType)
}

/// `MediaPickerCoordinatorType` is a protocol describing a Coordinator that handle keybackup setup navigation flow.
protocol MediaPickerCoordinatorType: Coordinator, Presentable {
    var delegate: MediaPickerCoordinatorDelegate? { get }
}
