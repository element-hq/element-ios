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

import DSBottomSheet
import SwiftUI

struct LiveLocationSharingViewer: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @Environment(\.openURL) var openURL
    
    @State private var isBottomSheetExpanded = false
    
    var bottomSheetCollapsedHeight: CGFloat = 150.0
    
    // MARK: Public
    
    @ObservedObject var viewModel: LiveLocationSharingViewerViewModel.Context
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if !viewModel.viewState.showMapLoadingError {
                LocationSharingMapView(tileServerMapURL: viewModel.viewState.mapStyleURL,
                                       annotations: viewModel.viewState.annotations,
                                       highlightedAnnotation: viewModel.viewState.highlightedAnnotation,
                                       userAvatarData: nil,
                                       showsUserLocation: false,
                                       userAnnotationCanShowCallout: true,
                                       userLocation: Binding.constant(nil),
                                       mapCenterCoordinate: Binding.constant(nil),
                                       onCalloutTap: { annotation in
                                           if let userLocationAnnotation = annotation as? UserLocationAnnotation {
                                               viewModel.send(viewAction: .share(userLocationAnnotation))
                                           }
                                       },
                                       errorSubject: viewModel.viewState.errorSubject)
                
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
        .bottomSheet(sheet, if: viewModel.viewState.isBottomSheetVisible)
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
                        // Push bottom sheet down on item tap
                        isBottomSheetExpanded = false
                        viewModel.send(viewAction: .tapListItem(userId))
                    })
                }
            }
            .padding()
        }
        .background(theme.colors.background.ignoresSafeArea())
    }
}

// MARK: - Bottom sheet

extension LiveLocationSharingViewer {
    var sheetStyle: BottomSheetStyle {
        var bottomSheetStyle = BottomSheetStyle.standard

        bottomSheetStyle.snapRatio = 0.16
        
        let backgroundColor = theme.colors.background

        let handleStyle = BottomSheetHandleStyle(backgroundColor: backgroundColor, dividerColor: backgroundColor)
        bottomSheetStyle.handleStyle = handleStyle

        return bottomSheetStyle
    }

    var sheet: some BottomSheetView {
        BottomSheet(
            isExpanded: $isBottomSheetExpanded,
            minHeight: .points(bottomSheetCollapsedHeight),
            maxHeight: .available,
            style: sheetStyle
        ) {
            userLocationList
        }
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
