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

import SwiftUI

@available(iOS 14.0, *)
struct TemplateUserProfile: View {
    
    @ObservedObject var viewModel: TemplateUserProfileViewModel
    
    var header: some View {
        VStack {
            if let avatar = viewModel.viewState.avatar {
                HStack{
                    Spacer()
                    AvatarImage(avatarData: avatar, size: .xxLarge)
                    Spacer()
                }
            }
            Text(viewModel.viewState.displayName ?? "")
        }

    }
    var body: some View {
        VectorForm {
            header
        }
    }
}

@available(iOS 14.0, *)
struct TemplateUserProfile_Previews: PreviewProvider {
    static var previews: some View {
        TemplateUserProfile(viewModel: TemplateUserProfileViewModel(userService: TemplateMockUserService.example))
            .addDependency(MockAvatarService.example)
    }
}
