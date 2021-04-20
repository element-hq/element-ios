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

import Foundation

final class EnterNewRoomDetailsViewModel: EnterNewRoomDetailsViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private var currentOperation: MXHTTPOperation?
    
    private var mediaUploader: MXMediaLoader?
    
    // MARK: Public

    weak var viewDelegate: EnterNewRoomDetailsViewModelViewDelegate?
    weak var coordinatorDelegate: EnterNewRoomDetailsViewModelCoordinatorDelegate?
    var roomCreationParameters: RoomCreationParameters = RoomCreationParameters()
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        roomCreationParameters.isEncrypted = session.vc_isE2EByDefaultEnabledByHSAdmin() &&  RiotSettings.shared.roomCreationScreenRoomIsEncrypted
        roomCreationParameters.isPublic = RiotSettings.shared.roomCreationScreenRoomIsPublic
    }
    
    deinit {
        self.cancelOperations()
    }
    
    // MARK: - Public
    
    func process(viewAction: EnterNewRoomDetailsViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .chooseAvatar(let sourceView):
            self.chooseAvatar(sourceView: sourceView)
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.enterNewRoomDetailsViewModelDidCancel(self)
        case .create:
            self.createRoom()
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        update(viewState: .loaded)
    }
    
    private func chooseAvatar(sourceView: UIView) {
        self.coordinatorDelegate?.enterNewRoomDetailsViewModel(self, didTapChooseAvatar: sourceView)
    }
    
    private func fixRoomAlias(alias: String?) -> String? {
        guard var alias = alias else { return nil }
        
        //  drop prefix # from room alias
        while alias.hasPrefix("#") {
            alias = String(alias.dropFirst())
        }
        
        //  TODO: Fix below somehow
        alias = alias.replacingOccurrences(of: ":matrix.org", with: "")
        if let homeserver = session.credentials.homeServer {
            alias = alias.replacingOccurrences(of: ":" + homeserver, with: "")
        }
        
        return alias
    }
    
    private func createRoom() {
        //  compose room creation parameters in Matrix level
        let parameters = MXRoomCreationParameters()
        parameters.name = roomCreationParameters.name
        parameters.topic = roomCreationParameters.topic
        parameters.roomAlias = fixRoomAlias(alias: roomCreationParameters.address)
        
        if roomCreationParameters.isPublic {
            parameters.preset = kMXRoomPresetPublicChat
            if roomCreationParameters.showInDirectory {
                parameters.visibility = kMXRoomDirectoryVisibilityPublic
            } else {
                parameters.visibility = kMXRoomDirectoryVisibilityPrivate
            }
        } else {
            parameters.preset = kMXRoomPresetPrivateChat
            parameters.visibility = kMXRoomDirectoryVisibilityPrivate
        }
        
        if roomCreationParameters.isEncrypted {
            parameters.initialStateEvents = [MXRoomCreationParameters.initialStateEventForEncryption(withAlgorithm: kMXCryptoMegolmAlgorithm)]
        }
        
        update(viewState: .loading)
        
        currentOperation = session.createRoom(parameters: parameters) { (response) in
            switch response {
            case .success(let room):
                self.uploadAvatarIfRequired(ofRoom: room)
                self.currentOperation = nil
            case .failure(let error):
                self.update(viewState: .error(error))
                self.currentOperation = nil
            }
        }
    }
    
    private func uploadAvatarIfRequired(ofRoom room: MXRoom) {
        guard let avatar = roomCreationParameters.userSelectedAvatar else {
            //  no avatar set, continue
            self.coordinatorDelegate?.enterNewRoomDetailsViewModel(self, didCreateNewRoom: room)
            return
        }
        
        let avatarUp = MXKTools.forceImageOrientationUp(avatar)
        
        mediaUploader = MXMediaManager.prepareUploader(withMatrixSession: session, initialRange: 0, andRange: 1.0)
        mediaUploader?.uploadData(avatarUp?.jpegData(compressionQuality: 0.5),
                                  filename: nil,
                                  mimeType: "image/jpeg",
                                  success: { [weak self] (urlString) in
                                    guard let self = self else { return }
                                    guard let urlString = urlString else { return }
                                    guard let url = URL(string: urlString) else { return }
                                    self.setAvatar(ofRoom: room, withURL: url)
        }, failure: { [weak self] (error) in
            guard let self = self else { return }
            guard let error = error else { return }
            self.update(viewState: .error(error))
        })
    }
    
    private func setAvatar(ofRoom room: MXRoom, withURL url: URL) {
        currentOperation = room.setAvatar(url: url) { (response) in
            switch response {
            case .success:
                self.coordinatorDelegate?.enterNewRoomDetailsViewModel(self, didCreateNewRoom: room)
                self.currentOperation = nil
            case .failure(let error):
                self.update(viewState: .error(error))
                self.currentOperation = nil
            }
        }
    }
    
    private func update(viewState: EnterNewRoomDetailsViewState) {
        self.viewDelegate?.enterNewRoomDetailsViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
