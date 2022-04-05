// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// `RoomContextActionService` implements all the possible actions for a room not owned by the user (e.g. `MXPublicRoom`, `MXSpaceChildInfo`)
class UnownedRoomContextActionService: NSObject, RoomContextActionServiceProtocol {
    
    // MARK: - RoomContextActionServiceProtocol

    internal let roomId: String
    internal let session: MXSession
    internal weak var delegate: RoomContextActionServiceDelegate?
    
    // MARK: - Properties

    private let canonicalAlias: String?
    
    // MARK: - Setup
    
    init(roomId: String, canonicalAlias: String?, session: MXSession, delegate: RoomContextActionServiceDelegate?) {
        self.roomId = roomId
        self.canonicalAlias = canonicalAlias
        self.session = session
        self.delegate = delegate
    }
    
    // MARK: - Public
    
    func joinRoom() {
        self.delegate?.roomContextActionService(self, updateActivityIndicator: true)
        if let canonicalAlias = canonicalAlias {
            self.session.matrixRestClient.resolveRoomAlias(canonicalAlias) { [weak self] (response) in
                guard let self = self else { return }
                switch response {
                case .success(let resolution):
                    self.joinRoom(withId: resolution.roomId, via: resolution.servers)
                case .failure(let error):
                    MXLog.warning("[UnownedRoomContextActionService] joinRoom: failed to resolve room alias due to error \(error).")
                    self.joinRoom(withId: self.roomId, via: nil)
                }
            }
        } else {
            MXLog.warning("[UnownedRoomContextActionService] joinRoom: no canonical alias provided.")
            joinRoom(withId: self.roomId, via: nil)
        }
    }
    
    // MARK: - Private
    
    private func joinRoom(withId roomId: String, via viaServers: [String]?) {
        self.session.joinRoom(roomId, viaServers: viaServers, withSignUrl: nil) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success:
                self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
                self.delegate?.roomContextActionServiceDidJoinRoom(self)
            case .failure(let error):
                self.delegate?.roomContextActionService(self, updateActivityIndicator: false)
                self.delegate?.roomContextActionService(self, presentAlert: self.roomJoinFailedAlert(with: error))
            }
        }
    }
    
    private func roomJoinFailedAlert(with error: Error) -> UIAlertController {
        var message = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String
        if message == "No known servers" {
            // minging kludge until https://matrix.org/jira/browse/SYN-678 is fixed
            // 'Error when trying to join an empty room should be more explicit'
            message = VectorL10n.roomErrorJoinFailedEmptyRoom
        }
        
        let alertController = UIAlertController(title: VectorL10n.roomErrorJoinFailedTitle, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: VectorL10n.ok, style: .default, handler: nil))
        return alertController
    }
}
