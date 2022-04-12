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

enum CustomSchemeURLConstants {
    
    enum Parameters {
        static let transactionId = "transaction_id"
        static let customServerUrl = "custom_server_url"
        static let autoSignIn = "auto_sign_in"
    }
    
    enum Hosts {
        static let connect = "connect"
        static let customServer = "custom_server"
    }
}
