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

import DSBottomSheet
import SwiftUI
import WysiwygComposer

struct Composer: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let borderHeight: CGFloat = 44
    private let minTextViewHeight: CGFloat = 20
    private var verticalPadding: CGFloat {
        (borderHeight - minTextViewHeight) / 2
    }
    
    private var formatItems: [FormatItem] {
        FormatType.allCases.map { type in
            FormatItem(
                type: type,
                active: viewModel.reversedActions.contains(type.composerAction),
                disabled: viewModel.disabledActions.contains(type.composerAction)
            )
        }
    }
    
    // MARK: Public
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: WysiwygComposerViewModel
    let sendMessageAction: (WysiwygComposerContent) -> Void
    let showSendMediaActions: () -> Void
    var textColor = Color(.label)
    
    @State private var showSendButton = false
    
    var body: some View {
        VStack {
            let rect = RoundedRectangle(cornerRadius: borderHeight / 2)
            // TODO: Fix maximise animation bugs before re-enabling
//            ZStack(alignment: .topTrailing) {
            WysiwygComposerView(
                content: viewModel.content,
                replaceText: viewModel.replaceText,
                select: viewModel.select,
                didUpdateText: viewModel.didUpdateText
            )
            .textColor(theme.colors.primaryContent)
            .frame(height: viewModel.idealHeight)
            .padding(.horizontal, 12)
            .onAppear {
                viewModel.setup()
            }
//                Button {
//                    withAnimation(.easeInOut(duration: 0.25)) {
//                        viewModel.maximised.toggle()
//                    }
//                } label: {
//                    Image(viewModel.maximised ? Asset.Images.minimiseComposer.name : Asset.Images.maximiseComposer.name)
//                        .foregroundColor(theme.colors.tertiaryContent)
//                }
//                .padding(.top, 4)
//                .padding(.trailing, 12)
//            }
            .padding(.vertical, verticalPadding)
            .clipShape(rect)
            .overlay(rect.stroke(theme.colors.quinaryContent, lineWidth: 2))
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
            HStack {
                Button {
                    showSendMediaActions()
                } label: {
                    Image(Asset.Images.startComposeModule.name)
                        .foregroundColor(theme.colors.tertiaryContent)
                        .padding(11)
                        .background(Circle().fill(theme.colors.system))
                }
                FormattingToolbar(formatItems: formatItems) { type in
                    viewModel.apply(type.action)
                }
                Spacer()
                ZStack {
                    // TODO: Add support for voice messages
//                    Button {
//
//                    } label: {
//                        Image(Asset.Images.voiceMessageRecordButtonDefault.name)
//                            .foregroundColor(theme.colors.tertiaryContent)
//                    }
                    //                        .isHidden(showSendButton)
//                    .isHidden(true)
                    Button {
                        sendMessageAction(viewModel.content)
                        viewModel.clearContent()
                    } label: {
                        Image(Asset.Images.sendIcon.name)
                            .foregroundColor(theme.colors.tertiaryContent)
                    }
                    .isHidden(!showSendButton)
                }
                .onChange(of: viewModel.isContentEmpty) { empty in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showSendButton = !empty
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
            .animation(.none)
        }
    }
}

// MARK: Previews
struct Composer_Previews: PreviewProvider {
    static let stateRenderer = MockComposerScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
