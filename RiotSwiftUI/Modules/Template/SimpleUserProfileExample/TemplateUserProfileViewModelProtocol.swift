//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

protocol TemplateUserProfileViewModelProtocol {
    var completion: ((TemplateUserProfileViewModelResult) -> Void)? { get set }
    static func makeTemplateUserProfileViewModel(templateUserProfileService: TemplateUserProfileServiceProtocol) -> TemplateUserProfileViewModelProtocol
    var context: TemplateUserProfileViewModelType.Context { get }
}
