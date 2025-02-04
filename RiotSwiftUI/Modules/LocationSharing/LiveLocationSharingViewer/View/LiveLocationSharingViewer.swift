//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct LiveLocationSharingViewer: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @Environment(\.openURL) var openURL
        
    var bottomSheetCollapsedHeight: CGFloat = 150.0
    
    // MARK: Public
    
    @ObservedObject var viewModel: LiveLocationSharingViewerViewModel.Context
    
    var mapView: LocationSharingMapView {
        LocationSharingMapView(tileServerMapURL: viewModel.viewState.mapStyleURL,
                               annotations: viewModel.viewState.annotations,
                               highlightedAnnotation: viewModel.viewState.highlightedAnnotation,
                               userAvatarData: nil,
                               showsUserLocationMode: viewModel.viewState.showsUserLocationMode,
                               userAnnotationCanShowCallout: true,
                               userLocation: Binding.constant(nil),
                               mapCenterCoordinate: Binding.constant(nil),
                               onCalloutTap: { annotation in
                                   if let userLocationAnnotation = annotation as? UserLocationAnnotation {
                                       viewModel.send(viewAction: .share(userLocationAnnotation))
                                   }
                               },
                               errorSubject: viewModel.viewState.errorSubject)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if !viewModel.viewState.showMapLoadingError {
                    
                if !viewModel.viewState.isCurrentUserShared {
                    mapView
                        .overlay(CenterToUserLocationButton(action: {
                            viewModel.send(viewAction: .showUserLocation)
                        }).offset(x: -11.0, y: 52), alignment: .topTrailing)
                } else {
                    mapView
                }
                
                // Show map credits above collapsed bottom sheet height if bottom sheet is visible
                if viewModel.viewState.isBottomSheetVisible {
                    VStack(alignment: .center) {
                        Spacer()
                        MapCreditsView(action: {
                            viewModel.send(viewAction: .mapCreditsDidTap)
                        })
                        .offset(y: -bottomSheetCollapsedHeight) // Put the copyright action above the collapsed bottom sheet
                        .padding(.bottom, 10)
                    }
                    .ignoresSafeArea()
                }
                
            } else {
                MapLoadingErrorView()
                    .padding(.bottom, viewModel.viewState.isBottomSheetVisible ? bottomSheetCollapsedHeight : 0)
            }
            
            if viewModel.viewState.isAllLocationSharingEnded {
                VStack(alignment: .center) {
                    Spacer()
                    
                    // Show map credits only if map is visible
                    if !viewModel.viewState.showMapLoadingError {
                        MapCreditsView(action: {
                            viewModel.send(viewAction: .mapCreditsDidTap)
                        })
                        .padding(.bottom, 5)
                    }
                    
                    HStack(spacing: 10) {
                        Image(uiImage: Asset.Images.locationLiveCellIcon.image)
                            .renderingMode(.template)
                            .foregroundColor(theme.colors.quarterlyContent)
                            .frame(width: 40, height: 40)
                        Text(VectorL10n.liveLocationSharingEnded)
                            .font(theme.fonts.body)
                            .foregroundColor(theme.colors.tertiaryContent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(theme.colors.background.ignoresSafeArea())
                }
            }
        }
        .navigationTitle(VectorL10n.locationSharingLiveViewerTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(VectorL10n.close) {
                    viewModel.send(viewAction: .done)
                }
            }
        }
        .accentColor(theme.colors.accent)
        .background(theme.colors.system.ignoresSafeArea())
        .sheet(isPresented: .constant(viewModel.viewState.isBottomSheetVisible)) {
            if #available(iOS 16.4, *) {
                userLocationList
                    .presentationBackgroundInteraction(.enabled)
                    .presentationBackground(theme.colors.background)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.height(bottomSheetCollapsedHeight), .large])
                    .interactiveDismissDisabled()
            } else {
                userLocationList
                    .interactiveDismissDisabled()
            }
        }
        .actionSheet(isPresented: $viewModel.showMapCreditsSheet) {
            MapCreditsActionSheet(openURL: { url in
                openURL(url)
            }).sheet
        }
        .alert(item: $viewModel.alertInfo) { info in
            info.alert
        }
        .activityIndicator(show: viewModel.viewState.showLoadingIndicator)
    }
    
    var userLocationList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(viewModel.viewState.listItemsViewData) { viewData in
                    LiveLocationListItem(viewData: viewData, onStopSharingAction: {
                        viewModel.send(viewAction: .stopSharing)
                    }, onBackgroundTap: { userId in
                        viewModel.send(viewAction: .tapListItem(userId))
                    })
                }
            }
            .padding()
        }
        .background(theme.colors.background.ignoresSafeArea())
    }
}

// MARK: - Previews

struct LiveLocationSharingViewer_Previews: PreviewProvider {
    static let stateRenderer = MockLiveLocationSharingViewerScreenState.stateRenderer
    static var previews: some View {
        Group {
            stateRenderer.screenGroup().theme(.light).preferredColorScheme(.light)
            stateRenderer.screenGroup().theme(.dark).preferredColorScheme(.dark)
        }
    }
}

struct CenterToUserLocationButton: View {
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(uiImage: Asset.Images.locationCenterMapIcon.image)
                .foregroundColor(theme.colors.accent)
        }
        .padding(8.0)
        .background(theme.colors.background)
        .clipShape(Circle())
        .shadow(radius: 2.0)
    }
}
