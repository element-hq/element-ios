//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

// MARK: View model

enum UserSessionDetailsViewModelResult { }

// MARK: View

enum UserSessionDetailsViewAction { }

struct UserSessionDetailsViewState: BindableState, Equatable {
    let sections: [UserSessionDetailsSectionViewData]
}

struct UserSessionDetailsSectionViewData: Identifiable {
    let id = UUID()
    let header: String
    let footer: String?
    let items: [UserSessionDetailsSectionItemViewData]
}

struct UserSessionDetailsSectionItemViewData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

extension UserSessionDetailsSectionViewData: Equatable {
    static func == (lhs: UserSessionDetailsSectionViewData, rhs: UserSessionDetailsSectionViewData) -> Bool {
        lhs.header == rhs.header &&
            lhs.footer == rhs.footer &&
            lhs.items == rhs.items
    }
}

extension UserSessionDetailsSectionItemViewData: Equatable {
    static func == (lhs: UserSessionDetailsSectionItemViewData, rhs: UserSessionDetailsSectionItemViewData) -> Bool {
        lhs.title == rhs.title &&
            lhs.value == rhs.value
    }
}
