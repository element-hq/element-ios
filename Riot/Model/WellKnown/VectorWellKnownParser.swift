// 
// Copyright 2020 New Vector Ltd
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
