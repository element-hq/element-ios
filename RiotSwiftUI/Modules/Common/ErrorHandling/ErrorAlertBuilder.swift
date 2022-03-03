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

import SwiftUI

/// A type that describes an alert to be shown after an error occurred.
struct ErrorAlertInfo<T: Hashable>: Identifiable {
    /// An identifier that can be used to distinguish one error from another.
    let id: T
    /// The alert's title.
    let title: String
    /// The alert's message (optional).
    var message: String? = nil
    /// The alert's primary button title and action. Defaults to an Ok button with no action.
    var primaryButton: (title: String, action: (() -> Void)?) = (VectorL10n.ok, nil)
    /// The alert's secondary button title and action.
    var secondaryButton: (title: String, action: (() -> Void)?)? = nil
}

extension ErrorAlertInfo where T == Int {
    /// Initialises the type with the title and message from an `NSError` along with the default Ok button.
    init?(error: NSError? = nil) {
        guard error?.domain != NSURLErrorDomain && error?.code != NSURLErrorCancelled else { return nil }
        
        id = error?.code ?? -1
        title = error?.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? VectorL10n.error
        message = error?.userInfo[NSLocalizedDescriptionKey] as? String ?? VectorL10n.errorCommonMessage
    }
}

@available(iOS 13.0, *)
extension ErrorAlertInfo {
    var messageText: Text? {
        guard let message = message else { return nil }
        return Text(message)
    }
}
