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

/// A type that describes an alert to be shown to the user.
///
/// The alert info can be added to the view state bindings and used as an alert's `item`:
/// ```
/// MyView
///     .alert(item: $viewModel.alertInfo) { $0.alert }
/// ```
struct AlertInfo<T: Hashable>: Identifiable {
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

extension AlertInfo {
    /// Initialises the type with the title and message from an `NSError` along with the default Ok button.
    init?(error: NSError? = nil) where T == Int {
        self.init(id: error?.code ?? -1, error: error)
    }
    
    /// Initialises the type with the title and message from an `NSError` along with the default Ok button.
    /// - Parameters:
    ///   - id: An ID that identifies the error.
    ///   - error: The Error that occurred.
    init?(id: T, error: NSError? = nil) {
        guard error?.domain != NSURLErrorDomain && error?.code != NSURLErrorCancelled else { return nil }
        
        self.id = id
        title = error?.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? VectorL10n.error
        message = error?.userInfo[NSLocalizedDescriptionKey] as? String ?? VectorL10n.errorCommonMessage
    }
}

@available(iOS 13.0, *)
extension AlertInfo {
    private var messageText: Text? {
        guard let message = message else { return nil }
        return Text(message)
    }
    
    /// Returns a SwiftUI `Alert` created from this alert info, using default button
    /// styles for both primary and (if set) secondary buttons.
    var alert: Alert {
        if let secondaryButton = secondaryButton {
            return Alert(title: Text(title),
                         message: messageText,
                         primaryButton: alertButton(for: primaryButton),
                         secondaryButton: alertButton(for: secondaryButton))
        } else {
            return Alert(title: Text(title),
                         message: messageText,
                         dismissButton: alertButton(for: primaryButton))
        }
    }
    
    private func alertButton(for buttonParameters: (title: String, action: (() -> Void)?)) -> Alert.Button {
        guard let action = buttonParameters.action else {
            return .default(Text(buttonParameters.title))
        }
        
        return .default(Text(buttonParameters.title), action: action)
    }
}
