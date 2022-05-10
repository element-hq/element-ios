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

class TemplateUserProfileService: TemplateUserProfileServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var listenerReference: Any?
    
    // MARK: Public
    
    var userId: String {
        session.myUser.userId
    }
    
    var displayName: String? {
        session.myUser.displayname
    }
    
    var avatarUrl: String? {
        session.myUser.avatarUrl
    }
    
    private(set) var presenceSubject: CurrentValueSubject<TemplateUserProfilePresence, Never>
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        self.presenceSubject = CurrentValueSubject(TemplateUserProfilePresence(mxPresence: session.myUser.presence))
        self.listenerReference = setupPresenceListener()
    }

    deinit {
        guard let reference = listenerReference else { return }
        session.myUser.removeListener(reference)
    }
    
    func setupPresenceListener() -> Any? {
        let reference = session.myUser.listen { [weak self] event in
            guard let self = self,
                  let event = event,
                  case .presence = MXEventType(identifier: event.eventId)
            else { return }
            self.presenceSubject.send(TemplateUserProfilePresence(mxPresence: self.session.myUser.presence))
        }
        if reference == nil {
            UILog.error("[TemplateUserProfileService] Did not recieve a lisenter reference.")
        }
        return reference
    }
}

fileprivate extension TemplateUserProfilePresence {
    
    init(mxPresence: MXPresence) {
        switch mxPresence {
        case .online:
            self = .online
        case .unavailable:
            self = .idle
        case .offline, .unknown:
            self = .offline
        default:
            self = .offline
        }
    }
}
