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
    private let parentSpace: MXSpace?
    private var currentOperation: MXHTTPOperation?
    
    private var mediaUploader: MXMediaLoader?
    
    // MARK: Public

    weak var viewDelegate: EnterNewRoomDetailsViewModelViewDelegate?
    weak var coordinatorDelegate: EnterNewRoomDetailsViewModelCoordinatorDelegate?
    var roomCreationParameters: RoomCreationParameters = RoomCreationParameters()
    
    private(set) var viewState: EnterNewRoomDetailsViewState {
        didSet {
            self.viewDelegate?.enterNewRoomDetailsViewModel(self, didUpdateViewState: viewState)
        }
    }
    
    var actionType: EnterNewRoomActionType {
        parentSpace != nil ? .createAndAddToSpace : .createOnly
    }
    
    // MARK: - Setup
    
    init(session: MXSession, parentSpace: MXSpace?) {
        self.session = session
        self.parentSpace = parentSpace
        roomCreationParameters.isEncrypted = session.vc_homeserverConfiguration().encryption.isE2EEByDefaultEnabled &&  RiotSettings.shared.roomCreationScreenRoomIsEncrypted
        roomCreationParameters.joinRule = RiotSettings.shared.roomCreationScreenRoomIsPublic ? .public : .private
        viewState = .loaded
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
        case .removeAvatar:
            self.removeAvatar()
        case .cancel:
            self.cancelOperations()
            self.coordinatorDelegate?.enterNewRoomDetailsViewModelDidCancel(self)
        case .create:
            self.createRoom()
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        viewState = .loaded
    }
    
    private func chooseAvatar(sourceView: UIView) {
        self.coordinatorDelegate?.enterNewRoomDetailsViewModel(self, didTapChooseAvatar: sourceView)
    }

    private func removeAvatar() {
        self.roomCreationParameters.userSelectedAvatar = nil
        self.process(viewAction: .loadData)
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
        guard let roomName = roomCreationParameters.name else {
            fatalError("[EnterNewRoomDetailsViewModel] createRoom: room name cannot be nil.")
        }
        
        viewState = .loading
        currentOperation = session.createRoom(
            withName: roomName,
            joinRule: roomCreationParameters.joinRule,
            topic: roomCreationParameters.topic,
            parentRoomId: parentSpace?.spaceId,
            aliasLocalPart: fixRoomAlias(alias: roomCreationParameters.address),
            isEncrypted: roomCreationParameters.isEncrypted,
            completion: { response in
              switch response {
              case .success(let room):
                  self.viewState = .loaded
                  
                  if let parentSpace = self.parentSpace {
                      self.add(room, to: parentSpace)
                  } else {
                      self.uploadAvatarIfRequired(ofRoom: room)
                      self.currentOperation = nil
                  }
              case .failure(let error):
                  self.viewState = .error(error)
                  self.currentOperation = nil
              }
          })
    }
    
    private func add(_ room: MXRoom, to space: MXSpace) {
        currentOperation = space.addChild(roomId: room.roomId, suggested: roomCreationParameters.isRoomSuggested) { response in
            switch response {
            case .success:
                self.uploadAvatarIfRequired(ofRoom: room)
                self.currentOperation = nil
            case .failure(let error):
                self.viewState = .error(error)
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
            self.viewState = .error(error)
        })
    }
    
    private func setAvatar(ofRoom room: MXRoom, withURL url: URL) {
        currentOperation = room.setAvatar(url: url) { (response) in
            switch response {
            case .success:
                self.coordinatorDelegate?.enterNewRoomDetailsViewModel(self, didCreateNewRoom: room)
                self.currentOperation = nil
            case .failure(let error):
                self.viewState = .error(error)
                self.currentOperation = nil
            }
        }
    }
        
    private func cancelOperations() {
        self.currentOperation?.cancel()
    }
}
