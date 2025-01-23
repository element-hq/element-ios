//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A visual cue to user that something is in progress.
struct ActivityIndicator: View {
    private enum Constants {
        static let backgroundColor = Color(UIColor(white: 0.8, alpha: 0.9))
    }
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
            .padding()
            .background(Constants.backgroundColor)
            .cornerRadius(5)
    }
}

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Text("Hello World!")
                .activityIndicator(show: true)
            Text("Hello World!")
                .activityIndicator(show: false)
        }
    }
}
