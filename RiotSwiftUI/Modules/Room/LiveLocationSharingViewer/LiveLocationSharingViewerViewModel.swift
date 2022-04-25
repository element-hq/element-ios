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
import Combine
import Mapbox

@available(iOS 14, *)
typealias LiveLocationSharingViewerViewModelType = StateStoreViewModel<LiveLocationSharingViewerViewState,
                                                                 Never,
                                                                 LiveLocationSharingViewerViewAction>
@available(iOS 14, *)
class LiveLocationSharingViewerViewModel: LiveLocationSharingViewerViewModelType, LiveLocationSharingViewerViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let liveLocationSharingViewerService: LiveLocationSharingViewerServiceProtocol
    
    private var mapViewErrorAlertInfoBuilder: MapViewErrorAlertInfoBuilder

    // MARK: Public

    var completion: ((LiveLocationSharingViewerViewModelResult) -> Void)?

    // MARK: - Setup
    
    init(mapStyleURL: URL, service: LiveLocationSharingViewerServiceProtocol) {

        let viewState = LiveLocationSharingViewerViewState(mapStyleURL: mapStyleURL, annotations: [], highlightedAnnotation: nil, listItemsViewData: [])
        
        liveLocationSharingViewerService = service
        mapViewErrorAlertInfoBuilder = MapViewErrorAlertInfoBuilder()
        
        super.init(initialViewState: viewState)
        
        state.errorSubject.sink { [weak self] error in
            guard let self = self else { return }
            self.processError(error)
        }.store(in: &cancellables)
        
        self.update(with: service.usersLiveLocation)
    }
    
    // MARK: - Public

    override func process(viewAction: LiveLocationSharingViewerViewAction) {
        switch viewAction {
        case .done:
            completion?(.done)
        case .stopSharing:
            completion?(.stopLocationSharing)
        case .tapListItem(let userId):
            self.highlighAnnotation(with: userId)
        case .share(let userLocationAnnotation):
            completion?(.share(userLocationAnnotation.coordinate))
        }
    }
    
    // MARK: - Private
    
    private func processError(_ error: LocationSharingViewError) {
        guard state.bindings.alertInfo == nil else {
            return
        }
        
        let alertInfo = mapViewErrorAlertInfoBuilder.build(with: error) { [weak self] in
         
            switch error {
            case .invalidLocationAuthorization:
                if let applicationSettingsURL = URL(string:UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(applicationSettingsURL)
                } else {
                    self?.completion?(.done)
                }
            default:
                self?.completion?(.done)
            }
        }
        
        state.bindings.alertInfo = alertInfo
    }
    
    private func userLocationAnnotations(from usersLiveLocation: [UserLiveLocation]) -> [UserLocationAnnotation] {
        
        return usersLiveLocation.map { userLiveLocation in
            return UserLocationAnnotation(avatarData: userLiveLocation.avatarData, coordinate: userLiveLocation.coordinate)
        }
    }
    
    private func currentUserLocationAnnotation(from annotations: [UserLocationAnnotation]) -> UserLocationAnnotation? {
        annotations.first { annotation in
            return liveLocationSharingViewerService.isCurrentUserId(annotation.userId)
        }
    }
    
    private func getHighlightedAnnotation(from annotations: [UserLocationAnnotation]) -> UserLocationAnnotation? {
        
        if let userAnnotation = self.currentUserLocationAnnotation(from: annotations) {
            return userAnnotation
        } else {
            return annotations.first
        }
    }
    
    private func listItemsViewData(from usersLiveLocation: [UserLiveLocation]) -> [LiveLocationListItemViewData] {
        
        var listItemsViewData: [LiveLocationListItemViewData] = []
        
        let sortedUsersLiveLocation = usersLiveLocation.sorted { userLiveLocation1, userLiveLocation2 in
            return userLiveLocation1.displayName > userLiveLocation2.displayName
        }
        
        listItemsViewData = sortedUsersLiveLocation.map({ userLiveLocation in
            return self.listItemViewData(from: userLiveLocation)
        })
        
        
        let currentUserIndex = listItemsViewData.firstIndex { viewData in
            return viewData.isCurrentUser
        }
        
        // Move current user as first item
        if let currentUserIndex = currentUserIndex {
            
            let currentUserViewData = listItemsViewData[currentUserIndex]
            listItemsViewData.remove(at: currentUserIndex)
            listItemsViewData.insert(currentUserViewData, at: 0)
        }
        
        return listItemsViewData
    }
    
    private func listItemViewData(from userLiveLocation: UserLiveLocation) -> LiveLocationListItemViewData {
        
        let isCurrentUser =  self.liveLocationSharingViewerService.isCurrentUserId(userLiveLocation.userId)
        
        let expirationDate = userLiveLocation.timestamp +  userLiveLocation.timeout
                
        return LiveLocationListItemViewData(userId: userLiveLocation.userId, isCurrentUser: isCurrentUser, avatarData: userLiveLocation.avatarData, displayName: userLiveLocation.displayName, expirationDate: expirationDate, lastUpdate: userLiveLocation.lastUpdate)
    }
    
    private func update(with usersLiveLocation: [UserLiveLocation]) {
        
        let annotations: [UserLocationAnnotation] = self.userLocationAnnotations(from: usersLiveLocation)
        
        let highlightedAnnotation = self.getHighlightedAnnotation(from: annotations)
        
        let listViewItems = self.listItemsViewData(from: usersLiveLocation)
        
        self.state.annotations = annotations
        self.state.highlightedAnnotation = highlightedAnnotation
        self.state.listItemsViewData = listViewItems
    }
    
    private func highlighAnnotation(with userId: String) {
        let foundUserAnnotation = self.state.annotations.first { annotation in
            annotation.userId == userId
        }
        
        guard let foundUserAnnotation = foundUserAnnotation else {
            return
        }
        
        self.state.highlightedAnnotation = foundUserAnnotation
    }
}
