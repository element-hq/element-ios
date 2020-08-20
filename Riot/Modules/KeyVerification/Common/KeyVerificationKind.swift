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

enum KeyVerificationKind {
    case otherSession // An other session
    case thisSession  // My current session is new
    case newSession   // My other session is new
    case user         // Another user
    
    var verificationTitle: String {
        
        let title: String
        
        switch self {
        case .otherSession:
            title = VectorL10n.keyVerificationOtherSessionTitle
        case .thisSession:
            title = VectorL10n.keyVerificationThisSessionTitle
        case .newSession:
            title = VectorL10n.keyVerificationNewSessionTitle
        case .user:
            title = VectorL10n.keyVerificationUserTitle
        }
        
        return title
    }
}
