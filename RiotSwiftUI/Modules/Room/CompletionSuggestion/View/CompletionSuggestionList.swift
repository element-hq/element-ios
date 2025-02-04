//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct CompletionSuggestionList: View {
    private enum Constants {
        static let topPadding: CGFloat = 8.0
        static let listItemPadding: CGFloat = 4.0
        static let lineSpacing: CGFloat = 10.0
        static let maxHeight: CGFloat = 300.0
        static let maxVisibleRows = 4

        /*
         As of iOS 16.0, SwiftUI's List uses `UICollectionView` instead
         of `UITableView` internally, this value is an adjustment to apply
         to the list items in order to be as close as possible as the
         `UITableView` display.
         */
        @available(iOS 16.0, *)
        static let collectionViewPaddingCorrection: CGFloat = -5.0
    }

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @State private var prototypeListItemFrame: CGRect = .zero
    
    // MARK: Public
    
    @ObservedObject var viewModel: CompletionSuggestionViewModel.Context
    var showBackgroundShadow = true
    
    var body: some View {
        if viewModel.viewState.items.isEmpty {
            EmptyView()
        } else {
            ZStack {
                CompletionSuggestionListItem(content: CompletionSuggestionViewStateItem.user(id: "Prototype", avatar: AvatarInput(mxContentUri: "", matrixItemId: "", displayName: "Prototype"), displayName: "Prototype"))
                    .background(ViewFrameReader(frame: $prototypeListItemFrame))
                    .hidden()
                if showBackgroundShadow {
                    BackgroundView {
                        list()
                    }
                } else {
                    list()
                }
            }
        }
    }
    
    private func contentHeightForRowCount(_ count: Int) -> CGFloat {
        (prototypeListItemFrame.height + (Constants.listItemPadding * 2) + Constants.lineSpacing) * CGFloat(count) + Constants.topPadding
    }

    private func list() -> some View {
        List(viewModel.viewState.items) { item in
            Button {
                viewModel.send(viewAction: .selectedItem(item))
            } label: {
                CompletionSuggestionListItem(content: item)
                    .modifier(ListItemPaddingModifier(isFirst: viewModel.viewState.items.first?.id == item.id))
            }
        }
        .listStyle(PlainListStyle())
        .frame(height: min(Constants.maxHeight,
                           min(contentHeightForRowCount(Constants.maxVisibleRows),
                               contentHeightForRowCount(viewModel.viewState.items.count))))
        .id(UUID()) // Rebuild the whole list on item changes. Fixes performance issues.
    }

    private struct ListItemPaddingModifier: ViewModifier {
        private let isFirst: Bool

        init(isFirst: Bool) {
            self.isFirst = isFirst
        }

        func body(content: Content) -> some View {
            var topPadding: CGFloat = isFirst ? Constants.listItemPadding + Constants.topPadding : Constants.listItemPadding
            var bottomPadding: CGFloat = Constants.listItemPadding
            if #available(iOS 16.0, *) {
                topPadding += Constants.collectionViewPaddingCorrection
                bottomPadding += Constants.collectionViewPaddingCorrection
            }

            return content
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
        }
    }
}

private struct BackgroundView<Content: View>: View {
    var content: () -> Content
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    private let shadowRadius: CGFloat = 20.0
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .background(theme.colors.background)
            .clipShape(RoundedCornerShape(radius: shadowRadius, corners: [.topLeft, .topRight]))
            .shadow(color: .black.opacity(0.20), radius: 20.0, x: 0.0, y: 3.0)
            .mask(Rectangle().padding(.init(top: -(shadowRadius * 2), leading: 0.0, bottom: 0.0, trailing: 0.0)))
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Previews

struct CompletionSuggestion_Previews: PreviewProvider {
    static let stateRenderer = MockCompletionSuggestionScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
