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

import XCTest
@testable import Element

class PasswordValidatorTests: XCTestCase {

    func testOnlyLength() throws {
        let minLengthRule = PasswordValidatorRule.minLength(8)
        let validator = PasswordValidator(withRules: [minLengthRule])

        //  this should pass
        try validator.validate(password: "abcdefgh")

        do {
            //  this should fail
            try validator.validate(password: "abcdefg")
            XCTFail("Should not pass")
        } catch let error as PasswordValidatorError {
            XCTAssertEqual(error.unmetRules.count, 1)
            XCTAssertEqual(error.unmetRules.first, minLengthRule)
        }
    }

    func testComplexWithMinimumRequirements() throws {
        let validator = PasswordValidator(withRules: [
            .minLength(4),
            .maxLength(4),
            .containUppercaseLetter,
            .containLowercaseLetter,
            .containNumber,
            .containSymbol
        ])

        //  this should pass
        try validator.validate(password: "Ab1!")

        do {
            //  this should fail with only maxLength rule
            try validator.validate(password: "Ab1!E")
            XCTFail("Should fail with only maxLength rule")
        } catch let error as PasswordValidatorError {
            XCTAssertEqual(error.unmetRules.count, 1)
            XCTAssertEqual(error.unmetRules.first, .maxLength(4))
        }

        do {
            //  this should fail with only uppercase rule
            try validator.validate(password: "ab1!")
            XCTFail("Should fail with only uppercase rule")
        } catch let error as PasswordValidatorError {
            XCTAssertEqual(error.unmetRules.count, 1)
            XCTAssertEqual(error.unmetRules.first, .containUppercaseLetter)
        }
        
        do {
            //  this should fail with only lowercase rule
            try validator.validate(password: "AB1!")
            XCTFail("Should fail with only lowercase rule")
        } catch let error as PasswordValidatorError {
            XCTAssertEqual(error.unmetRules.count, 1)
            XCTAssertEqual(error.unmetRules.first, .containLowercaseLetter)
        }

        do {
            //  this should fail with only number rule
            try validator.validate(password: "Abc!")
            XCTFail("Should fail with only number rule")
        } catch let error as PasswordValidatorError {
            XCTAssertEqual(error.unmetRules.count, 1)
            XCTAssertEqual(error.unmetRules.first, .containNumber)
        }

        do {
            //  this should fail with only symbol rule
            try validator.validate(password: "Abc1")
            XCTFail("Should fail with only symbol rule")
        } catch let error as PasswordValidatorError {
            XCTAssertEqual(error.unmetRules.count, 1)
            XCTAssertEqual(error.unmetRules.first, .containSymbol)
        }
    }

}
