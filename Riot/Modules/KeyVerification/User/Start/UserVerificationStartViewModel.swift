// File created from ScreenTemplate
// $ createScreen.sh Start UserVerificationStart
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

enum UserVerificationStartViewModelError: Error {
    case keyVerificationRequestExpired
}

struct UserVerificationStartViewData {
    let userId: String
    let userDisplayName: String?
    let userAvatarURL: String?
}

final class UserVerificationStartViewModel: UserVerificationStartViewModelType {
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let roomMember: MXRoomMember
    private let verificationManager: MXKeyVerificationManager
    private let keyVerificationService: KeyVerificationService
    
    private var keyVerificationRequest: MXKeyVerificationRequest?
    
    private var viewData: UserVerificationStartViewData {
        return UserVerificationStartViewData(userId: self.roomMember.userId, userDisplayName: self.roomMember.displayname, userAvatarURL: self.roomMember.avatarUrl)
    }
    
    // MARK: Public        

    weak var viewDelegate: UserVerificationStartViewModelViewDelegate?
    weak var coordinatorDelegate: UserVerificationStartViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, roomMember: MXRoomMember) {
        self.session = session
        self.verificationManager = session.crypto.keyVerificationManager
        self.roomMember = roomMember
        self.keyVerificationService = KeyVerificationService()
    }
    
    // MARK: - Public
    
    func process(viewAction: UserVerificationStartViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .startVerification:
            self.startVerification()
        case .cancel:
            self.cancelKeyVerificationRequest()
            self.coordinatorDelegate?.userVerificationStartViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func loadData() {
        self.update(viewState: .loaded(self.viewData))
    }
    
    private func startVerification() {
        self.update(viewState: .verificationPending)
        
        self.verificationManager.requestVerificationByDM(withUserId: self.roomMember.userId,
                                                         roomId: nil,
                                                         fallbackText: "",
                                                         methods: self.keyVerificationService.supportedKeyVerificationMethods(),
                                                         success: { [weak self] (keyVerificationRequest) in
                                                            guard let self = self else {
                                                                return
                                                            }
                                                            
                                                            self.keyVerificationRequest = keyVerificationRequest
                                                            self.update(viewState: .loaded(self.viewData))
                                                            self.registerKeyVerificationRequestDidChangeNotification(for: keyVerificationRequest)
        }, failure: { [weak self]  error in
            self?.update(viewState: .error(error))
        })
    }
    
    private func update(viewState: UserVerificationStartViewState) {
        self.viewDelegate?.userVerificationStartViewModel(self, didUpdateViewState: viewState)
    }
    
    private func cancelKeyVerificationRequest() {
        guard let keyVerificationRequest = self.keyVerificationRequest  else {
            return
        }

        keyVerificationRequest.cancel(with: MXTransactionCancelCode.user(), success: nil, failure: nil)
    }
    
    // MARK: - MXKeyVerificationRequestDidChange
    
    private func registerKeyVerificationRequestDidChangeNotification(for keyVerificationRequest: MXKeyVerificationRequest) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyVerificationRequestDidChange(notification:)), name: .MXKeyVerificationRequestDidChange, object: keyVerificationRequest)
    }
    
    private func unregisterKeyVerificationRequestDidChangeNotification() {
        NotificationCenter.default.removeObserver(self, name: .MXKeyVerificationRequestDidChange, object: nil)
    }
    
    @objc private func keyVerificationRequestDidChange(notification: Notification) {
        guard let keyVerificationRequest = notification.object as? MXKeyVerificationRequest else {
            return
        }
        
        guard let currentKeyVerificationRequest = self.keyVerificationRequest, keyVerificationRequest.requestId == currentKeyVerificationRequest.requestId else {
            return
        }
        
        switch keyVerificationRequest.state {
        case MXKeyVerificationRequestStateAccepted:            
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.coordinatorDelegate?.userVerificationStartViewModel(self, otherDidAcceptRequest: currentKeyVerificationRequest)
        case MXKeyVerificationRequestStateReady:
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.coordinatorDelegate?.userVerificationStartViewModel(self, otherDidAcceptRequest: currentKeyVerificationRequest)
        case MXKeyVerificationRequestStateCancelled:
            guard let reason = keyVerificationRequest.reasonCancelCode else {
                return
            }
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .cancelled(reason))
        case MXKeyVerificationRequestStateCancelledByMe:
            guard let reason = keyVerificationRequest.reasonCancelCode else {
                return
            }
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .cancelledByMe(reason))
        case MXKeyVerificationRequestStateExpired:
            self.unregisterKeyVerificationRequestDidChangeNotification()
            self.update(viewState: .error(UserVerificationStartViewModelError.keyVerificationRequestExpired))
        default:
            break
        }
    }
}
