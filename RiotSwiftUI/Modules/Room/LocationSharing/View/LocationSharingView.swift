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
import CoreLocation

@available(iOS 14.0, *)
struct LocationSharingView: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var context: LocationSharingViewModel.Context
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                mapView
                VStack(spacing: 0) {
                    MapCreditsView()
                    buttonsView
                        .background(theme.colors.background)
                        .clipShape(RoundedCornerShape(radius: 8, corners: [.topLeft, .topRight]))
                }
            }
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
                                       showsUserLocation: context.viewState.showsUserLocation,
                                       userLocation: $context.userLocation,
                                       mapCenterCoordinate: $context.pinLocation,
                                       errorSubject: context.viewState.errorSubject)
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
                        context.send(viewAction: .shareLiveLocation)
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

@available(iOS 14.0, *)
struct LocationSharingView_Previews: PreviewProvider {
    static let stateRenderer = MockLocationSharingScreenState.stateRenderer
    static var previews: some View {
        Group {
            stateRenderer.screenGroup().theme(.light).preferredColorScheme(.light)
            stateRenderer.screenGroup().theme(.dark).preferredColorScheme(.dark)
        }
    }
}
