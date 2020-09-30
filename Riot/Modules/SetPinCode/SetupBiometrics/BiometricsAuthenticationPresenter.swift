// 
// Copyright 2020 New Vector Ltd
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
