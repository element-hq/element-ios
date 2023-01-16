// 
// Copyright 2023 New Vector Ltd
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

final class MockPollHistoryService: PollHistoryServiceProtocol {
    var pollListData: [PollListData] = (1..<10)
        .map { index in
            PollListData(startDate: .init().addingTimeInterval(-CGFloat(index) * 3600), question: "Do you like the poll number \(index)?")
        }
        .sorted { poll1, poll2 in
            poll1.startDate > poll2.startDate
        }
    
    func fetchHistory() async throws -> [PollListData] {
        pollListData
    }
}
