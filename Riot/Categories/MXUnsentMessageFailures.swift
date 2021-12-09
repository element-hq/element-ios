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

extension MXUnsentMessageFailures {
    var localizedFailureSummary: String {
        guard uniqueErrors.count == 1, let error = uniqueErrors.first else {
            return VectorL10n.roomUnsentMessagesTapMessage
        }
        
        return Self.localizedDescription(of: error)
    }
    
    static func localizedDescription(of error: NSError) -> String {
        // Check if the error is due to unknown devices
        if error.domain == MXEncryptingErrorDomain && error.code == MXEncryptingErrorUnknownDeviceCode.rawValue {
            return VectorL10n.roomUnsentMessagesErrorUnknownDevices
        }
        
        if let response = MXHTTPOperation.urlResponse(fromError: error) {
            if response.statusCode == 413 {
                return VectorL10n.roomUnsentMessagesErrorFileSize
            } else {
                return VectorL10n.roomUnsentMessagesErrorNetwork
            }
        }
        
        if error.domain == AVFoundationErrorDomain {
            return UIDevice.current.isPhone ? VectorL10n.roomUnsentMessagesErrorConvertPhone : VectorL10n.roomUnsentMessagesErrorConvertDevice
        }
        
        return VectorL10n.roomUnsentMessagesErrorUnknown
    }
}
