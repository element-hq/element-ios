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
