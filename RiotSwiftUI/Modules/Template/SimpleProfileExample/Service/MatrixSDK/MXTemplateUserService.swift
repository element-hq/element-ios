// 
// Copyright 2021 New Vector Ltd
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
import Combine

@available(iOS 14.0, *)
class MXTemplateUserService: TemplateUserServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var listenerReference: Any!
    @Published private var presence: TemplatePresence = .offline
    
    // MARK: Public
    
    var userId: String {
        return session.myUser.userId
    }
    
    var displayName: String? {
        session.myUser.displayname
    }
    
    var avatarUrl: String? {
        session.myUser.avatarUrl
    }
    
    var presencePublisher: AnyPublisher<TemplatePresence, Never> {
        $presence.eraseToAnyPublisher()
    }
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        let listenerReference = session.myUser.listen { [weak self] event in
            guard let self = self,
                  let event = event,
                  case .presence = MXEventType(identifier: event.eventId)
            else { return }
            self.presence = TemplatePresence(mxPresence: self.session.myUser.presence)
        }
        self.listenerReference = listenerReference
    }

    deinit {
        session.myUser.removeListener(listenerReference)
    }
}

fileprivate extension TemplatePresence {
    
    init(mxPresence: MXPresence) {
        switch mxPresence {
        case MXPresenceOnline:
            self = .online
        case MXPresenceUnavailable:
            self = .idle
        case MXPresenceOffline, MXPresenceUnknown:
            self = .offline
        default:
            self = .offline
        }
    }
}
