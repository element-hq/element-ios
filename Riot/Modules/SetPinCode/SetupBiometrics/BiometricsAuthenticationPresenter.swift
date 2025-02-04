// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import LocalAuthentication

enum BiometricsAuthenticationPresenterError: Error {
    case unknown
}

/// Presenter for user authentication with biometry.
@objcMembers
final class BiometricsAuthenticationPresenter: NSObject {

    /// Whether the presenter currently showing the biometrics setup or unlock dialog.
    /// Showing biometrics dialog will cause the app to resign active.
    /// This property can be used in order to distinguish real resignations and biometrics case.
    static private(set) var isPresenting: Bool = false
    
    /// Presents the user authentication with biometry.
    /// - Parameters:
    ///   - message: The app-provided reason for requesting authentication, which displays in the authentication dialog presented to the user.
    ///   - completion: A closure that is executed when policy evaluation finishes. Will be called in main thread.
    func present(with message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        //  do not present if already presented
        guard !BiometricsAuthenticationPresenter.isPresenting else {
            return
        }
        BiometricsAuthenticationPresenter.isPresenting = true

        LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: message) { (success, error) in
            if success {
                // Complete after a little delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    BiometricsAuthenticationPresenter.isPresenting = false
                    completion(.success(Void()))
                }
            } else {
                let finalError: Error
                
                if let error = error {
                    finalError = error
                } else {
                    finalError = BiometricsAuthenticationPresenterError.unknown
                }
                
                DispatchQueue.main.async {
                    BiometricsAuthenticationPresenter.isPresenting = false
                    completion(.failure(finalError))
                }
            }
        }
    }
}
