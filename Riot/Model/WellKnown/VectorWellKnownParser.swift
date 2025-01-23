// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

final class VectorWellKnownParser {
    
    func parse(jsonDictionary: [AnyHashable: Any]) -> VectorWellKnown? {
        let serializationService = SerializationService()
        let vectorWellKnown: VectorWellKnown?
                        
        do {
            vectorWellKnown = try serializationService.deserialize(jsonDictionary)
        } catch {
            vectorWellKnown = nil
            MXLog.debug("[VectorWellKnownParser] Fail to parse application Well Known keys with error: \(error)")
        }
        
        return vectorWellKnown
    }
}
