// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreData

/// A `ValueTransformer` for ``URLPreviewCacheData``'s `image` field.
/// This class transforms between `UIImage` and it's `pngData()` representation.
class URLPreviewImageTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        UIImage.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        true
    }
    
    /// Transforms a `UIImage` into it's `pngData()` representation.
    override func transformedValue(_ value: Any?) -> Any? {
        guard let image = value as? UIImage else { return nil }
        return image.pngData()
    }
    
    /// Transforms `Data` into a `UIImage`
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return UIImage(data: data)
    }
}

extension NSValueTransformerName {
    static let urlPreviewImageTransformer = NSValueTransformerName("URLPreviewImageTransformer")
}
