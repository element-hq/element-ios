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

import SwiftUI

struct MapCreditsActionSheet {
    // Open URL action
    let openURL: (URL) -> Void
    
    // Map credits action sheet
    var sheet: ActionSheet {
        ActionSheet(title: Text(VectorL10n.locationSharingMapCreditsTitle),
                    buttons: [
                        .default(Text("© MapTiler")) {
                            openURL(URL(string: "https://www.maptiler.com/copyright/")!)
                        },
                        .default(Text("© OpenStreetMap")) {
                            openURL(URL(string: "https://www.openstreetmap.org/copyright")!)
                        },
                        .cancel()
                    ])
    }
}
