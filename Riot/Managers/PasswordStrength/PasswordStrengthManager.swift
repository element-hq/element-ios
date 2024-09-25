/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

import Foundation
import zxcvbn_ios

/// PasswordStrengthManager computes password strength for a given string.
final class PasswordStrengthManager {
    
    // MARK: - Properties
    
    private let zxcvbn = DBZxcvbn()
    
    // MARK: - Public
    
    func passwordStrength(for password: String) -> PasswordStrength {
        guard let result = zxcvbn.passwordStrength(password) else {
            return .tooGuessable
        }
        return self.passwordStrength(from: result.score)
    }
    
    // MARK: - Private
    
    private func passwordStrength(from zxcvbnScore: Int32) -> PasswordStrength {
        let passwordStrengthRawValue = UInt(zxcvbnScore)
        
        guard let passwordStrength = PasswordStrength(rawValue: passwordStrengthRawValue) else {
            return .tooGuessable
        }
        
        return passwordStrength
    }
}
