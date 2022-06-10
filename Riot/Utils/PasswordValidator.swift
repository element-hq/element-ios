// 
// Copyright 2022 New Vector Ltd
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

struct PasswordValidatorError: LocalizedError {
    /// Unmet rules
    let unmetRules: [PasswordValidatorRule]

    /// Error description for the error
    var errorDescription: String? {
        var result = VectorL10n.passwordValidationErrorHeader + "\n"
        result += unmetRules.map { $0.descriptionInList }.joined(separator: "\n")
        return result
    }
}

/// Validation rule for a password
enum PasswordValidatorRule: CustomStringConvertible, Hashable {
    case minLength(_ value: Int)
    case maxLength(_ value: Int)
    case containLowercaseLetter
    case containUppercaseLetter
    case containNumber
    case containSymbol

    var description: String {
        switch self {
        case .minLength(let value):
            return VectorL10n.passwordValidationErrorMinLength(value)
        case .maxLength(let value):
            return VectorL10n.passwordValidationErrorMaxLength(value)
        case .containLowercaseLetter:
            return VectorL10n.passwordValidationErrorContainLowercaseLetter
        case .containUppercaseLetter:
            return VectorL10n.passwordValidationErrorContainUppercaseLetter
        case .containNumber:
            return VectorL10n.passwordValidationErrorContainNumber
        case .containSymbol:
            return VectorL10n.passwordValidationErrorContainSymbol
        }
    }

    var descriptionInList: String {
        return "• " + description
    }

    func metBy(password: String) -> Bool {
        switch self {
        case .minLength(let value):
            return password.count >= value
        case .maxLength(let value):
            return password.count <= value
        case .containLowercaseLetter:
            return password.range(of: "[a-z]", options: .regularExpression) != nil
        case .containUppercaseLetter:
            return password.range(of: "[A-Z]", options: .regularExpression) != nil
        case .containNumber:
            return password.range(of: "[0-9]", options: .regularExpression) != nil
        case .containSymbol:
            return password.range(of: "[!\"#$%&'()*+,-.:;<=>?@\\_`{|}~\\[\\]]",
                                  options: .regularExpression) != nil
        }
    }
}

/// A utility class to validate a password against some rules.
class PasswordValidator {

    /// Validation rules
    let rules: [PasswordValidatorRule]

    /// Initializer
    /// - Parameter rules: validation rules
    init(withRules rules: [PasswordValidatorRule]) {
        self.rules = rules
    }

    /// Validate a given password.
    /// - Parameter password: Password to be validated
    func validate(password: String) throws {
        var unmetRules: [PasswordValidatorRule] = []
        for rule in rules {
            if !rule.metBy(password: password) {
                unmetRules.append(rule)
            }
        }
        if !unmetRules.isEmpty {
            throw PasswordValidatorError(unmetRules: unmetRules)
        }
    }

    /// Creates a description text with current rules
    /// - Parameter header: Header text to include in the result
    /// - Returns: Description text containing `header` and rules
    func description(with header: String) -> String {
        var result = header
        if !rules.isEmpty {
            result += "\n"
        }
        result += rules.map { $0.descriptionInList }.joined(separator: "\n")
        return result
    }

}
