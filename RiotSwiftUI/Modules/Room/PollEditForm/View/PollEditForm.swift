// File created from SimpleUserProfileExample
// $ createScreen.sh Room/PollEditForm PollEditForm
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
struct PollEditForm: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: PollEditFormViewModel.Context
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32.0) {
                        
                        VStack(alignment: .leading, spacing: 16.0) {
                            Text(VectorL10n.pollEditFormPollQuestionOrTopic)
                                .font(theme.fonts.title3SB)
                                .foregroundColor(theme.colors.primaryContent)
                            
                            VStack(alignment: .leading, spacing: 8.0) {
                                Text(VectorL10n.pollEditFormQuestionOrTopic)
                                    .font(theme.fonts.subheadline)
                                    .foregroundColor(theme.colors.primaryContent)
                                
                                MultilineTextField(VectorL10n.pollEditFormInputPlaceholder, text: $viewModel.question.text)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16.0) {
                            Text(VectorL10n.pollEditFormCreateOptions)
                                .font(theme.fonts.title3SB)
                                .foregroundColor(theme.colors.primaryContent)
                            
                            ForEach(0..<viewModel.answerOptions.count, id: \.self) { index in
                                SafeBindingCollectionEnumerator($viewModel.answerOptions, index: index) { binding in
                                    AnswerOptionGroup(text: binding.text, index: index) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.send(viewAction: .deleteAnswerOption(viewModel.answerOptions[index]))
                                        }
                                    }
                                }
                            }
                        }
                        
                        Button(VectorL10n.pollEditFormAddOption) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.send(viewAction: .addAnswerOption)
                            }
                        }
                        .disabled(!viewModel.viewState.addAnswerOptionButtonEnabled)
                        
                        Spacer()
                        
                        Button(VectorL10n.pollEditFormCreatePoll) {
                            viewModel.send(viewAction: .create)
                        }
                        .buttonStyle(PrimaryActionButtonStyle(enabled: viewModel.viewState.confirmationButtonEnabled))
                        .disabled(!viewModel.viewState.confirmationButtonEnabled)
                    }
                    .padding()
                    .activityIndicator(show: viewModel.viewState.showLoadingIndicator)
                    .alert(isPresented: $viewModel.showsFailureAlert) {
                        Alert(title: Text(VectorL10n.pollEditFormPostFailureTitle),
                              message: Text(VectorL10n.pollEditFormPostFailureSubtitle),
                              dismissButton: .default(Text(VectorL10n.pollEditFormPostFailureAction)))
                    }
                    .frame(minHeight: proxy.size.height) // Make the VStack fill the ScrollView's parent
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(VectorL10n.cancel, action: {
                                viewModel.send(viewAction: .cancel)
                            })
                        }
                        ToolbarItem(placement: .principal) {
                            Text(VectorL10n.pollEditFormCreatePoll)
                                .font(.headline)
                                .foregroundColor(theme.colors.primaryContent)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .accentColor(theme.colors.accent)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

@available(iOS 14.0, *)
private struct AnswerOptionGroup: View {
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var focused = false
    
    @Binding var text: String
    
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(VectorL10n.pollEditFormOptionNumber(index + 1))
                .font(theme.fonts.subheadline)
                .foregroundColor(theme.colors.primaryContent)
            
            HStack(spacing: 16.0) {
                TextField(VectorL10n.pollEditFormInputPlaceholder, text: $text, onEditingChanged: { edit in
                    self.focused = edit
                })
                .textFieldStyle(BorderedInputFieldStyle(theme: _theme, isEditing: focused))
                Button {
                    onDelete()
                } label: {
                    Image(uiImage:Asset.Images.pollDeleteOptionIcon.image)
                }
                .accessibilityIdentifier("Delete answer option")
            }
        }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct PollEditForm_Previews: PreviewProvider {
    static let stateRenderer = MockPollEditFormScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
