// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// SourceImage represents a local or remote image.
enum SourceImage {
    case local(_ image: UIImage)
    case remote(_ url: URL)
}
