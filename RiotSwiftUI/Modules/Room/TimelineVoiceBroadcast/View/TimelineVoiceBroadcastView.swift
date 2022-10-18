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

struct TimelineVoiceBroadcastView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: TimelineVoiceBroadcastViewModel.Context
    
    var body: some View {
        let voiceBroadcast = viewModel.viewState.voiceBroadcast
        
        VStack(alignment: .leading, spacing: 16.0) {
            Text(VectorL10n.voiceBroadcastInTimelineTitle)
                .font(theme.fonts.bodySB)
                .foregroundColor(theme.colors.primaryContent)
            Text(VectorL10n.voiceBroadcastInTimelineBody)
                .font(theme.fonts.body)
                .foregroundColor(theme.colors.primaryContent)
        }
        .padding([.horizontal, .top], 2.0)
        .padding([.bottom])
        .alert(item: $viewModel.alertInfo) { info in
            info.alert
        }
    }
}

// MARK: - Previews

// TODO: Add Voice broadcast preview
