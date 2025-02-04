//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import SwiftUI

struct LocationSharingView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @Environment(\.openURL) var openURL
    
    // MARK: Public
    
    @ObservedObject var context: LocationSharingViewModel.Context
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                if !context.viewState.showMapLoadingError {
                    mapView
                }
                
                VStack(spacing: 0) {
                    if context.viewState.showMapLoadingError {
                        MapLoadingErrorView()
                    } else {
                        // Show map credits only if map is visible
                        
                        MapCreditsView(action: {
                            context.send(viewAction: .mapCreditsDidTap)
                        })
                        .padding(.bottom, 10.0)
                        .actionSheet(isPresented: $context.showMapCreditsSheet) {
                            MapCreditsActionSheet(openURL: { url in
                                openURL(url)
                            }).sheet
                        }
                    }
                    
                    buttonsView
                        .background(theme.colors.background)
                        .clipShape(RoundedCornerShape(radius: 8, corners: [.topLeft, .topRight]))
                }
            }
            .background(theme.colors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(VectorL10n.cancel, action: {
                        context.send(viewAction: .cancel)
                    })
                }
                ToolbarItem(placement: .principal) {
                    Text(VectorL10n.locationSharingTitle)
                        .font(.headline)
                        .foregroundColor(theme.colors.primaryContent)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .introspectNavigationController { navigationController in
                ThemeService.shared().theme.applyStyle(onNavigationBar: navigationController.navigationBar)
            }
            .alert(item: $context.alertInfo) { info in
                info.alert
            }
        }
        .accentColor(theme.colors.accent)
        .activityIndicator(show: context.viewState.showLoadingIndicator)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var mapView: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .center) {
                LocationSharingMapView(tileServerMapURL: context.viewState.mapStyleURL,
                                       annotations: context.viewState.annotations,
                                       highlightedAnnotation: context.viewState.highlightedAnnotation,
                                       userAvatarData: context.viewState.userAvatarData,
                                       showsUserLocationMode: context.viewState.showsUserLocationMode,
                                       userLocation: $context.userLocation,
                                       mapCenterCoordinate: $context.pinLocation,
                                       errorSubject: context.viewState.errorSubject,
                                       userDidPan: {
                                           context.send(viewAction: .userDidPan)
                                       })
                if context.viewState.isPinDropSharing {
                    LocationSharingMarkerView(backgroundColor: theme.colors.accent) {
                        Image(uiImage: Asset.Images.locationPinIcon.image)
                            .resizable()
                            .shapedBorder(color: theme.colors.accent, borderWidth: 3, shape: Circle())
                    }
                }
            }
            Button {
                context.send(viewAction: .goToUserLocation)
            } label: {
                Image(uiImage: Asset.Images.locationCenterMapIcon.image)
                    .foregroundColor(theme.colors.accent)
            }
            .padding(6.0)
            .background(theme.colors.background)
            .clipShape(RoundedCornerShape(radius: 4, corners: [.allCorners]))
            .shadow(radius: 2.0)
            .offset(x: -11.0, y: 52)
        }
    }
    
    var buttonsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            if !context.viewState.isPinDropSharing {
                LocationSharingOptionButton(text: VectorL10n.locationSharingStaticShareTitle) {
                    context.send(viewAction: .share)
                } buttonIcon: {
                    AvatarImage(avatarData: context.viewState.userAvatarData, size: .medium)
                        .border()
                }
                .disabled(!context.viewState.shareButtonEnabled)
                // Hide for now until live location sharing is finished
                if context.viewState.isLiveLocationSharingEnabled {
                    LocationSharingOptionButton(text: VectorL10n.locationSharingLiveShareTitle) {
                        context.send(viewAction: .startLiveSharing)
                    } buttonIcon: {
                        Image(uiImage: Asset.Images.locationLiveIcon.image)
                            .resizable()
                    }
                    .disabled(!context.viewState.shareButtonEnabled)
                }
            } else {
                LocationSharingOptionButton(text: VectorL10n.locationSharingPinDropShareTitle) {
                    context.send(viewAction: .sharePinLocation)
                } buttonIcon: {
                    Image(uiImage: Asset.Images.locationPinIcon.image)
                        .resizable()
                }
                .disabled(!context.viewState.shareButtonEnabled)
            }
        }
        .actionSheet(isPresented: $context.showingTimerSelector) {
            ActionSheet(title: Text(VectorL10n.locationSharingLiveTimerSelectorTitle),
                        buttons: [
                            .default(Text(VectorL10n.locationSharingLiveTimerSelectorShort)) {
                                context.send(viewAction: .shareLiveLocation(timeout: .short))
                                
                            },
                            .default(Text(VectorL10n.locationSharingLiveTimerSelectorMedium)) {
                                context.send(viewAction: .shareLiveLocation(timeout: .medium))
                                
                            },
                            .default(Text(VectorL10n.locationSharingLiveTimerSelectorLong)) {
                                context.send(viewAction: .shareLiveLocation(timeout: .long))
                                
                            },
                            .cancel()
                        ])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    @ViewBuilder
    private var activityIndicator: some View {
        if context.viewState.showLoadingIndicator {
            ActivityIndicator()
        }
    }
}

// MARK: - Previews

struct LocationSharingView_Previews: PreviewProvider {
    static let stateRenderer = MockLocationSharingScreenState.stateRenderer
    static var previews: some View {
        Group {
            stateRenderer.screenGroup().theme(.light).preferredColorScheme(.light)
            stateRenderer.screenGroup().theme(.dark).preferredColorScheme(.dark)
        }
    }
}
