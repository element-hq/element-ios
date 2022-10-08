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

import Foundation
import WysiwygComposer
import SwiftUI

@available(iOS 15.0, *)
enum MockComposerScreenState: MockScreenState, CaseIterable {
    case composer
    
    var screenType: Any.Type {
        Composer.self
    }
    
//    var screenContainer: some View {
//        VStack{
//            Spacer()
//            Composer(viewModel: viewModel)
//        }
//    }
    var screenView: ([Any], AnyView)  {
        let viewModel = WysiwygComposerViewModel(minHeight: 20, maxHeight: 360)
        
        return (
            [viewModel],
            AnyView(VStack{
                Spacer()
                Composer(viewModel: viewModel, sendMessageAction: { _ in }, showSendMediaActions: { })
            }.frame(
                minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading
            ))
        )
    }
}