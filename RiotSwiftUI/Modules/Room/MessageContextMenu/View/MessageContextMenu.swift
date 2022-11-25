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
extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

@available(iOS 14.0, *)
struct SizeModifier: ViewModifier {
    @Binding var size: CGSize

    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
        }
        .onPreferenceChange(SizePreferenceKey.self) {
            size = $0
        }
    }

    func body(content: Content) -> some View {
        content.overlay(sizeView)
    }
}

@available(iOS 14.0, *)
struct MessageContextMenu: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var containerSize: CGSize = .zero
    @State private var menuSize: CGSize = .zero
    @State private var subMenus: [MessageContextMenuItem] = []
    @State private var previewFrame: CGRect = .zero
    @State private var menuFrame: CGRect = .zero
    @State private var menuScale: CGFloat = 0
    @State private var backgroundAlpha: CGFloat = 0
    
    // MARK: Public
    
    @ObservedObject var viewModel: MessageContextMenuViewModel.Context
    
    var body: some View {
        let _ = print("[MessageContextMenu] initialFrame = \(viewModel.viewState.intialFrame)")
//        let _ = print("[MessageContextMenu] menuSize = \(menuSize)")
        GeometryReader { reader in
            ZStack(alignment: .topLeading) {
                VisualEffectView(effect: UIBlurEffect(style: .regular))
                    .opacity(backgroundAlpha)
                Color.black.opacity(0.2)
                    .opacity(backgroundAlpha)

                if let image = viewModel.viewState.previewImage {
                    Image(uiImage: image)
                        .background(theme.colors.background)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.7), radius: 60, x: 0, y: 5)
                        .position(x: previewFrame.midX, y: previewFrame.midY)
                        .frame(width: previewFrame.width, height: previewFrame.height)
                }
                
                reactionView
                    .position(x: reader.size.width / 2, y: 60)
                    .scaleEffect(menuScale)

                ZStack {
                    menuView(with: viewModel.viewState.menu)
                        .frame(maxWidth: reader.size.width * 2 / 3, maxHeight: reader.size.height * 2 / 3)
                    ForEach(subMenus) { subItem in
                        menuView(with: subItem.children)
                            .frame(maxWidth: reader.size.width * 2 / 3, maxHeight: reader.size.height * 2 / 3)
                            .transition(.scale)
                    }
//                        .transition(.scale)
                }
                .position(x: menuFrame.midX, y: menuFrame.midY)
                .scaleEffect(menuScale)
//                .transition(.scale)
            }
            .modifier(SizeModifier(size: $containerSize))
            .ignoresSafeArea()
            .frame(maxHeight: .infinity)
            .onTapGesture {
                viewModel.send(viewAction: .cancel)
            }
            .onAppear {
                self.previewFrame = viewModel.viewState.intialFrame
                let ratio = min((containerSize.width - 64) / previewFrame.width, 1)
                let newPreviewFrame = CGRect(x: 32, y: 96, width: previewFrame.width * ratio, height: previewFrame.height * ratio)
                self.menuFrame = CGRect(x: 32, y: newPreviewFrame.maxY + 16, width: menuSize.width, height: menuSize.height)
                withAnimation {
                    self.computeLayout()
                }
            }

        }
    }
    
    private func computeLayout() {
        let _ = print("[MessageContextMenu] computeLayout: containerSize = \(self.containerSize)")
        let _ = print("[MessageContextMenu] computeLayout: menuSize = \(menuSize)")

        let ratio = min((containerSize.width - 64) / previewFrame.width, 1)
        self.previewFrame = CGRect(x: 32, y: 96, width: previewFrame.width * ratio, height: previewFrame.height * ratio)
        self.menuScale = 1
        self.backgroundAlpha = 1
    }
    
    private func menuView(with items: [MessageContextMenuItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    MessageContextMenuListRow(item: item)
                        .onTapGesture {
                            if item.type == .more {
                                withAnimation {
                                    subMenus.append(item)
                                }
                            } else if !item.attributes.contains(.disabled) {
                                viewModel.send(viewAction: .menuItemPressed(item))
                            }
                        }
                }
            }
            .cornerRadius(12)
            .modifier(SizeModifier(size: $menuSize))
        }
        .cornerRadius(12)
        .frame(maxHeight: menuSize.height)
    }
    
    var reactionView: some View {
        HStack (spacing: 4) {
            reactionListView
            Image(uiImage: Asset.Images.moreReactions.image)
                .renderingMode(.template)
                .padding(10)
                .foregroundColor(theme.colors.primaryContent)
                .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
                .clipShape(Circle())
                .onTapGesture {
                    viewModel.send(viewAction: .moreReactionsItemPressed)
                }
        }
    }
    
    var reactionListView: some View {
        HStack (spacing: 2) {
            ForEach(viewModel.viewState.reactions) { reaction in
                Text(reaction.emoji)
                    .font(theme.fonts.callout)
                    .padding(6)
                    .background(reaction.isSelected ? theme.colors.quarterlyContent : Color.clear)
                    .clipShape(Circle())
                    .onTapGesture {
                        viewModel.send(viewAction: .reactionItemPressed(reaction))
                    }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)))
        .clipShape(Capsule())
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct MessageContextMenu_Previews: PreviewProvider {
    static let stateRenderer = MockMessageContextMenuScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
