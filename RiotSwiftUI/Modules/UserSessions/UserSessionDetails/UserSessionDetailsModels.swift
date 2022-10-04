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
