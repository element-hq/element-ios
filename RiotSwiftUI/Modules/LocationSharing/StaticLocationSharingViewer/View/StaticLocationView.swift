//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct StaticLocationView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    // MARK: Public
    
    @ObservedObject var viewModel: StaticLocationViewingViewModel.Context
    
    // MARK: Views
    
    var mapView: LocationSharingMapView {
        LocationSharingMapView(tileServerMapURL: viewModel.viewState.mapStyleURL,
                               annotations: [viewModel.viewState.sharedAnnotation],
                               highlightedAnnotation: viewModel.viewState.sharedAnnotation,
                               userAvatarData: nil,
                               showsUserLocationMode: viewModel.viewState.showsUserLocationMode,
                               userLocation: Binding.constant(nil),
                               mapCenterCoordinate: Binding.constant(nil),
                               errorSubject: viewModel.viewState.errorSubject)
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                mapView
                MapCreditsView()
            }
            .overlay(CenterToUserLocationButton(action: {
                viewModel.send(viewAction: .showUserLocation)
            }).offset(x: -11.0, y: 52), alignment: .topTrailing)
            .ignoresSafeArea(.all, edges: [.bottom])
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(VectorL10n.cancel, action: {
                        viewModel.send(viewAction: .close)
                    })
                }
                ToolbarItem(placement: .principal) {
                    Text(VectorL10n.locationSharingTitle)
                        .font(.headline)
                        .foregroundColor(theme.colors.primaryContent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.send(viewAction: .share)
                    } label: {
                        Image(uiImage: Asset.Images.locationShareIcon.image)
                    }
                    .disabled(!viewModel.viewState.shareButtonEnabled)
                    .accessibilityIdentifier("shareButton")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .introspectNavigationController { navigationController in
                ThemeService.shared().theme.applyStyle(onNavigationBar: navigationController.navigationBar)
            }
            .alert(item: $viewModel.alertInfo) { info in
                info.alert
            }
        }
        .accentColor(theme.colors.accent)
        .activityIndicator(show: viewModel.viewState.showLoadingIndicator)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private var activityIndicator: some View {
        if viewModel.viewState.showLoadingIndicator {
            ActivityIndicator()
        }
    }
}

// MARK: - Previews

struct StaticLocationSharingViewer_Previews: PreviewProvider {
    static let stateRenderer = MockStaticLocationViewingScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
