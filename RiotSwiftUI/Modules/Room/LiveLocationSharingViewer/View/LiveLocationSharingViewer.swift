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
import DSBottomSheet

@available(iOS 14.0, *)
struct LiveLocationSharingViewer: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    var isBottomSheetVisible = true
    @State private var isBottomSheetExpanded = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: LiveLocationSharingViewerViewModel.Context
    
    var body: some View {
        ZStack(alignment: .bottom) {
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
            VStack(alignment: .center) {
                Spacer()
                MapCreditsView()
                    .offset(y: -130)
            }
        }
        .navigationTitle(VectorL10n.locationSharingLiveViewerTitle)
        .accentColor(theme.colors.accent)
        .bottomSheet(sheet, if: isBottomSheetVisible)
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
    }
}

// MARK: - Bottom sheet
@available(iOS 14.0, *)
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
            minHeight: .points(150),
            maxHeight: .available,
            style: sheetStyle) {
                userLocationList
            }
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct LiveLocationSharingViewer_Previews: PreviewProvider {
    static let stateRenderer = MockLiveLocationSharingViewerScreenState.stateRenderer
    static var previews: some View {
        Group {
            stateRenderer.screenGroup().theme(.light).preferredColorScheme(.light)
            stateRenderer.screenGroup().theme(.dark).preferredColorScheme(.dark)
        }
    }
}
