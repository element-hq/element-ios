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

@objc final class MemberEventFormatter: NSObject {
    
    @objc func aggregateAndGenerateSummary(events: [MXEvent]) -> String? {
        JavaScriptService.shared.aggregateAndGenerateSummary(userEvents: makeUserEvents(for: events), summaryLength: 1)
    }
    
    private func makeUserEvents(for events: [MXEvent]) -> [AnyHashable: Any] {
        var result = [String: [[String: Any]]]()
        for (index, event) in events.enumerated() {
            guard let userID = event.stateKey else {
                continue
            }
            
            if result[userID] == nil {
                result[userID] = []
            }

            result[userID]?.append([
                "mxEvent": event,
                "displayName": targetDisplayName(for: event) as Any,
                "index": index
            ])
        }
        return result
    }
    
    private func targetDisplayName(for event: MXEvent) -> String! {
        if event.type == "m.room.third_party_invite", let name = event.content["display_name"] as? String {
            return name
        }
        return (event.content?["displayname"] as? String) ?? event.stateKey
    }
    
}
