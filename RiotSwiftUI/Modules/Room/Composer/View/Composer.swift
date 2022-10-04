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

import SwiftUI
import WysiwygComposer
import DSBottomSheet

@available(iOS 16.0, *)
struct Composer: View {
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: WysiwygComposerViewModel
    let sendMessageAction: (WysiwygComposerContent) -> Void
    let startModuleAction: (ComposerModule) -> Void
    
    @State private var isBottomSheetExpanded = false
    @State private var showSendButton = false
    
    private let borderHeight: CGFloat = 44
    private let minTextViewHeight: CGFloat = 20
    
    private var verticalPadding: CGFloat {
        (borderHeight - minTextViewHeight) / 2
    }
    
    private var formatItems: [FormatItem] {
        FormatType.allCases.map { type in
            return FormatItem(
                type: type,
                active: viewModel.reversedActions.contains(type.composerAction),
                disabled: viewModel.disabledActions.contains(type.composerAction)
            )
        }
    }
    
    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                let rect = RoundedRectangle(cornerRadius: borderHeight / 2)
                WysiwygComposerView(
                    content: viewModel.content,
                    replaceText: viewModel.replaceText,
                    select: viewModel.select,
                    didUpdateText: viewModel.didUpdateText
                )
                .frame(height: viewModel.idealHeight)
                .padding(.horizontal, 12)
                .onAppear {
                    viewModel.setup()
                }
// TODO Fix maximise in integrated composer.
//                .overlay(alignment: .topTrailing) {
//                    Button {
//                        withAnimation(.easeInOut(duration: 0.25)) {
//                            viewModel.maximised.toggle()
//                        }
//                    } label: {
//                        Image(viewModel.maximised ? Asset.Images.minimiseComposer.name : Asset.Images.maximiseComposer.name)
//                            .foregroundColor(theme.colors.tertiaryContent)
//                    }
//                    .padding(.top, 4)
//                    .padding(.trailing, 12)
//                }
                .padding(.vertical, verticalPadding)
                .clipShape(rect)
                .overlay(rect.stroke(theme.colors.quinaryContent, lineWidth: 2))
                .padding(.horizontal, 12)
                HStack{
                    Button {
                        isBottomSheetExpanded = true
                    } label: {
                        Image(Asset.Images.startComposeModule.name)
                            .foregroundColor(theme.colors.tertiaryContent)
                    }
                    FormattingToolbar(formatItems: formatItems) { type in
                        viewModel.apply(type.action)
                    }
                    Spacer()
                    ZStack{
                        Button {
                            
                        } label: {
                            Image(Asset.Images.voiceMessageRecordButtonDefault.name)
                                .foregroundColor(theme.colors.tertiaryContent)
                        }
// TODO Add support for voice messages
//                        .isHidden(showSendButton)
                        .isHidden(true)
                        Button {
                            sendMessageAction(viewModel.content)
                            viewModel.clearContent()
                        } label: {
                            Image(Asset.Images.sendIcon.name)
                                .foregroundColor(theme.colors.tertiaryContent)
                        }
                        .isHidden(!showSendButton)
                    }.onChange(of: viewModel.isContentEmpty) { (empty) in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showSendButton = !empty
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .sheet(isPresented: $isBottomSheetExpanded) {
                moduleSelectionList
                    .presentationDetents([.medium])
            }
//            .sheetWithDetents(
//                isPresented: $isBottomSheetExpanded,
//                detents: [.medium()]
//            ) {
//                guard let module = selectedModule else { return }
//                self.startModuleAction(module)
//                self.selectedModule = nil
//                print("The sheet has been dismissed")
//            } content: {
//
//            }
    }
    
    var moduleSelectionList: some View {
        VStack {
            VStack(alignment: .leading) {
                ForEach(ComposerModule.allCases) { module in
                    HStack(spacing: 16) {
                        Image(module.icon)
                            .renderingMode(.template)
                            .foregroundColor(theme.colors.accent)
                        Text(module.title)
                            .foregroundColor(theme.colors.primaryContent)
                            .font(theme.fonts.body)
                        Spacer()
                    }
                    .onTapGesture {
                        isBottomSheetExpanded = false
                        self.startModuleAction(module)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .padding(.top, 16)
            .background(theme.colors.background.ignoresSafeArea())
            Spacer()
        }
    }
}

@available(iOS 16.0, *)
struct Composer_Previews: PreviewProvider {
    static let stateRenderer = MockComposerScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
