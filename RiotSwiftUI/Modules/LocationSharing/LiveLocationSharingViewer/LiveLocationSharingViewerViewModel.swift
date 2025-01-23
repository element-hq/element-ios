//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Mapbox
import SwiftUI

typealias LiveLocationSharingViewerViewModelType = StateStoreViewModel<LiveLocationSharingViewerViewState, LiveLocationSharingViewerViewAction>

class LiveLocationSharingViewerViewModel: LiveLocationSharingViewerViewModelType, LiveLocationSharingViewerViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private var liveLocationSharingViewerService: LiveLocationSharingViewerServiceProtocol
    
    private var mapViewErrorAlertInfoBuilder: MapViewErrorAlertInfoBuilder
    
    private var screenUpdateTimer: Timer?
    
    // Last annotation that could be highlighted
    // Used to set map position when location sharing is ended
    private var lastHighlightableAnnotation: LocationAnnotation?

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
        
        setupLocationSharingService()
        setupScreenUpdateTimer()
    }
    
    // MARK: - Public

    override func process(viewAction: LiveLocationSharingViewerViewAction) {
        switch viewAction {
        case .done:
            completion?(.done)
        case .stopSharing:
            stopUserLocationSharing()
        case .tapListItem(let userId):
            highlighAnnotation(with: userId)
        case .share(let userLocationAnnotation):
            completion?(.share(userLocationAnnotation.coordinate))
        case .mapCreditsDidTap:
            state.bindings.showMapCreditsSheet.toggle()
        case .showUserLocation:
            showsCurrentUserLocation()
        }
    }
    
    // MARK: - Private
    
    private func setupLocationSharingService() {
        updateUsersLiveLocation(highlightFirstLocation: true)
        
        liveLocationSharingViewerService.didUpdateUsersLiveLocation = { [weak self] liveLocations in
            self?.update(with: liveLocations, highlightFirstLocation: false)
        }
        liveLocationSharingViewerService.startListeningLiveLocationUpdates()
    }
    
    private func updateUsersLiveLocation(highlightFirstLocation: Bool) {
        update(with: liveLocationSharingViewerService.usersLiveLocation, highlightFirstLocation: highlightFirstLocation)
    }
    
    private func setupScreenUpdateTimer() {
        screenUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            
            self?.updateUsersLiveLocation(highlightFirstLocation: false)
        }
    }
    
    private func processError(_ error: LocationSharingViewError) {
        guard state.bindings.alertInfo == nil else {
            return
        }
        
        if case .failedLoadingMap = error {
            state.showMapLoadingError = true
        }
        
        let alertInfo = mapViewErrorAlertInfoBuilder.build(with: error) { [weak self] in
         
            switch error {
            case .invalidLocationAuthorization:
                if let applicationSettingsURL = URL(string: UIApplication.openSettingsURLString) {
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
        usersLiveLocation.map { userLiveLocation in
            UserLocationAnnotation(avatarData: userLiveLocation.avatarData, coordinate: userLiveLocation.coordinate)
        }
    }
    
    private func currentUserLocationAnnotation(from annotations: [UserLocationAnnotation]) -> UserLocationAnnotation? {
        annotations.first { annotation in
            liveLocationSharingViewerService.isCurrentUserId(annotation.userId)
        }
    }
    
    private func getHighlightedAnnotation(from annotations: [UserLocationAnnotation]) -> UserLocationAnnotation? {
        if let userAnnotation = currentUserLocationAnnotation(from: annotations) {
            return userAnnotation
        } else {
            return annotations.first
        }
    }
    
    private func listItemsViewData(from usersLiveLocation: [UserLiveLocation]) -> [LiveLocationListItemViewData] {
        var listItemsViewData: [LiveLocationListItemViewData] = []
        
        let sortedUsersLiveLocation = usersLiveLocation.sorted { userLiveLocation1, userLiveLocation2 in
            userLiveLocation1.displayName > userLiveLocation2.displayName
        }
        
        listItemsViewData = sortedUsersLiveLocation.map { userLiveLocation in
            self.listItemViewData(from: userLiveLocation)
        }
        
        let currentUserIndex = listItemsViewData.firstIndex { viewData in
            viewData.isCurrentUser
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
        let isCurrentUser = liveLocationSharingViewerService.isCurrentUserId(userLiveLocation.userId)
        
        let expirationDate = userLiveLocation.timestamp + userLiveLocation.timeout
                
        return LiveLocationListItemViewData(userId: userLiveLocation.userId, isCurrentUser: isCurrentUser, avatarData: userLiveLocation.avatarData, displayName: userLiveLocation.displayName, expirationDate: expirationDate, lastUpdate: userLiveLocation.lastUpdate)
    }
    
    private func update(with usersLiveLocation: [UserLiveLocation], highlightFirstLocation: Bool) {
        let annotations: [UserLocationAnnotation] = userLocationAnnotations(from: usersLiveLocation)
        
        var highlightedAnnotation: LocationAnnotation?
        
        if highlightFirstLocation {
            highlightedAnnotation = getHighlightedAnnotation(from: annotations)
        }
        
        if let highlightableAnnotation = getHighlightedAnnotation(from: annotations) {
            lastHighlightableAnnotation = highlightableAnnotation
        }
        
        if let lastHighlightableAnnotation = lastHighlightableAnnotation, usersLiveLocation.isEmpty {
            highlightedAnnotation = InvisibleLocationAnnotation(coordinate: lastHighlightableAnnotation.coordinate)
        }
        
        let listViewItems = listItemsViewData(from: usersLiveLocation)
        
        state.annotations = annotations
        state.highlightedAnnotation = highlightedAnnotation
        state.listItemsViewData = listViewItems
    }
    
    private func highlighAnnotation(with userId: String) {
        let foundUserAnnotation = state.annotations.first { annotation in
            annotation.userId == userId
        }
        
        guard let foundUserAnnotation = foundUserAnnotation else {
            return
        }
        
        /*
            if the map is currently following the current user's location,
            we want to switch back to only showing the marker,
            so the the highlighted shared location can be centered
         */
        if state.showsUserLocationMode == .follow {
            state.showsUserLocationMode = .show
        }
        state.highlightedAnnotation = foundUserAnnotation
    }
    
    private func stopUserLocationSharing() {
        state.showLoadingIndicator = true
        
        liveLocationSharingViewerService.stopUserLiveLocationSharing { result in
            self.state.showLoadingIndicator = false
            
            switch result {
            case .success:
                break
            case .failure:
                self.state.bindings.alertInfo = AlertInfo(id: .stopLocationSharingError,
                                                          title: VectorL10n.error,
                                                          message: VectorL10n.locationSharingLiveStopSharingError,
                                                          primaryButton: (VectorL10n.ok, nil))
            }
        }
    }
    
    private func showsCurrentUserLocation() {
        if liveLocationSharingViewerService.requestAuthorizationIfNeeded() {
            state.showsUserLocationMode = .follow
        } else {
            state.errorSubject.send(.invalidLocationAuthorization)
        }
    }
}
