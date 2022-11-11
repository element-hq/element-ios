import SwiftUI

struct UserSessionName: View {
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ObservedObject var viewModel: UserSessionNameViewModel.Context
    
    var body: some View {
        List {
            SwiftUI.Section {
                TextField(VectorL10n.manageSessionName, text: $viewModel.sessionName)
                    .autocapitalization(.words)
                    .listRowBackground(theme.colors.background)
                    .introspectTextField {
                        $0.becomeFirstResponder()
                        $0.clearButtonMode = .whileEditing
                    }
            } header: {
                Text(VectorL10n.manageSessionName)
                    .foregroundColor(theme.colors.secondaryContent)
            } footer: {
                textFieldFooter
            }
        }
        .background(theme.colors.system.ignoresSafeArea())
        .frame(maxHeight: .infinity)
        .listStyle(.grouped)
        .listBackgroundColor(theme.colors.system)
        .navigationTitle(VectorL10n.manageSessionRename)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .accentColor(theme.colors.accent)
    }
    
    private var textFieldFooter: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(VectorL10n.manageSessionNameHint)
                .foregroundColor(theme.colors.secondaryContent)
            
            InlineTextButton(VectorL10n.manageSessionNameInfo("%@"),
                             tappableText: VectorL10n.manageSessionNameInfoLink) {
                viewModel.send(viewAction: .learnMore)
            }
            .foregroundColor(theme.colors.secondaryContent)
            .accessibility(identifier: "LearnMore")
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(VectorL10n.cancel) {
                viewModel.send(viewAction: .cancel)
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(VectorL10n.done) {
                viewModel.send(viewAction: .done)
            }
            .disabled(!viewModel.viewState.canUpdateName)
        }
    }
}

// MARK: - Previews

struct UserSessionName_Previews: PreviewProvider {
    static let stateRenderer = MockUserSessionNameScreenState.stateRenderer
    
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.light)
            .preferredColorScheme(.light)
        stateRenderer.screenGroup(addNavigation: true)
            .theme(.dark)
            .preferredColorScheme(.dark)
    }
}
