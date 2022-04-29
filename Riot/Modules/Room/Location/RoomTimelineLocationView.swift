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

import UIKit
import Reusable
import Mapbox
import SwiftUI

protocol RoomTimelineLocationViewDelegate: AnyObject {
    func roomTimelineLocationViewDidTapStopButton(_ roomTimelineLocationView: RoomTimelineLocationView)
    func roomTimelineLocationViewDidTapRetryButton(_ roomTimelineLocationView: RoomTimelineLocationView)
}

struct RoomTimelineLocationViewData {
    let location: CLLocationCoordinate2D?
    let userAvatarData: AvatarViewData?
    let mapStyleURL: URL
}

struct LiveLocationBannerViewData {
    let placeholderIcon: UIImage?
    let iconTint: UIColor
    let title: String
    let titleColor: UIColor
    let timeLeftString: String?
    let rightButtonTitle: String?
    let rightButtonTag: RightButtonTag
    let coordinate: CLLocationCoordinate2D?
    
    var showTimer: Bool {
        return timeLeftString != nil
    }
    
    var showRightButton: Bool {
        return rightButtonTitle != nil
    }
    
    var showPlaceholderImage: Bool {
        return placeholderIcon != nil
    }
}

enum TimelineLiveLocationViewState {
    case incoming(_ status: LiveLocationSharingStatus) // live location started by other users
    case outgoing(_ status: LiveLocationSharingStatus) // live location started from current user
}


enum LiveLocationSharingStatus {
    case starting
    case started(_ coordinate: CLLocationCoordinate2D, _ timeleft: TimeInterval)
    case failure
    case stopped
}

enum RightButtonTag: Int {
    case stopSharing = 0
    case retrySharing
}

class RoomTimelineLocationView: UIView, NibLoadable, Themable, MGLMapViewDelegate {

    // MARK: - Constants
    
    private struct Constants {
        static let mapHeight: CGFloat = 300.0
        static let mapZoomLevel = 15.0
        static let cellBorderRadius: CGFloat = 1.0
        static let cellCornerRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties
    // MARK: Private
    
    @IBOutlet private var descriptionContainerView: UIView!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var descriptionIcon: UIImageView!
    @IBOutlet private var attributionLabel: UILabel!
    
    // MARK: - Live Location
    @IBOutlet private var placeholderBackground: UIImageView!
    @IBOutlet private var placeholderIcon: UIImageView!
    @IBOutlet private var liveLocationContainerView: UIView!
    @IBOutlet private var liveLocationImageView: UIImageView!
    @IBOutlet private var liveLocationStatusLabel: UILabel!
    @IBOutlet private var liveLocationTimerLabel: UILabel!
    @IBOutlet private var rightButton: UIButton!
    
    
    
    private var mapView: MGLMapView!
    private var annotationView: LocationMarkerView?
    private static var usernameColorGenerator = UserNameColorGenerator()
    private var theme: Theme!
    
    private lazy var incomingTimerFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }()
    
    private lazy var outgoingTimerFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .brief
        return formatter
    }()
    
    weak var delegate: RoomTimelineLocationViewDelegate?
    
    // MARK: Public
    
    var locationDescription: String? {
        get {
            descriptionLabel.text
        }
        set {
            descriptionLabel.text = newValue
            descriptionContainerView.isHidden = (newValue?.count ?? 0 == 0)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mapView = MGLMapView(frame: .zero)
        mapView.delegate = self
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        mapView.isUserInteractionEnabled = false
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addConstraint(mapView.heightAnchor.constraint(equalToConstant: Constants.mapHeight))
        vc_addSubViewMatchingParent(mapView)
        sendSubviewToBack(mapView)
        
        clipsToBounds = true
        layer.borderWidth = Constants.cellBorderRadius
        layer.cornerRadius = Constants.cellCornerRadius
        
        theme = ThemeService.shared().theme
    }
    
    // MARK: - Private
    
    private func displayLocation(_ location: CLLocationCoordinate2D?,
                                 userAvatarData: AvatarViewData? = nil,
                                 mapStyleURL: URL,
                                 bannerViewData: LiveLocationBannerViewData? = nil) {
        
        if let location = location {
            mapView.styleURL = mapStyleURL
            
            annotationView = LocationMarkerView.loadFromNib()
            
            if let userAvatarData = userAvatarData {
                let avatarBackgroundColor = Self.usernameColorGenerator.color(from: userAvatarData.matrixItemId)
                annotationView?.setAvatarData(userAvatarData, avatarBackgroundColor: avatarBackgroundColor)
            }
            
            if let annotations = mapView.annotations {
                mapView.removeAnnotations(annotations)
            }
            
            mapView.setCenter(location, zoomLevel: Constants.mapZoomLevel, animated: false)
            
            let pointAnnotation = MGLPointAnnotation()
            pointAnnotation.coordinate = location
            mapView.addAnnotation(pointAnnotation)
        } else {
            mapView.isHidden = true
        }
        
        // Configure live location banner
        guard let bannerViewData = bannerViewData else {
            liveLocationContainerView.isHidden = true
            return
        }
        
        liveLocationContainerView.isHidden = false
        liveLocationContainerView.backgroundColor = theme.colors.background.withAlphaComponent(0.85)
        
        liveLocationImageView.image = Asset.Images.locationLiveCellIcon.image
        liveLocationImageView.tintColor = bannerViewData.iconTint
        
        liveLocationStatusLabel.text = bannerViewData.title
        liveLocationStatusLabel.textColor = bannerViewData.titleColor
        
        liveLocationTimerLabel.text = bannerViewData.timeLeftString
        liveLocationTimerLabel.textColor = theme.colors.tertiaryContent
        liveLocationTimerLabel.isHidden = !bannerViewData.showTimer
        
        rightButton.setTitle(bannerViewData.rightButtonTitle, for: .normal)
        rightButton.isHidden = !bannerViewData.showRightButton
        rightButton.tag = bannerViewData.rightButtonTag.rawValue
        
        placeholderBackground.isHidden = !bannerViewData.showPlaceholderImage
        placeholderIcon.image = bannerViewData.placeholderIcon
        placeholderIcon.isHidden = !bannerViewData.showPlaceholderImage
        placeholderBackground.isHidden = !bannerViewData.showPlaceholderImage
        mapView.isHidden = bannerViewData.showPlaceholderImage
    }
    
    private func liveLocationBannerViewData(from viewState: TimelineLiveLocationViewState) -> LiveLocationBannerViewData {
        
        let iconTint: UIColor
        let title: String
        var titleColor: UIColor = theme.colors.primaryContent
        var placeholderIcon: UIImage?
        var timeLeftString: String?
        var rightButtonTitle: String?
        var rightButtonTag: RightButtonTag = .stopSharing
        var liveCoordinate: CLLocationCoordinate2D?

        switch viewState {
        case .incoming(let liveLocationSharingStatus):
            switch liveLocationSharingStatus {
            case .starting:
                iconTint = theme.colors.tertiaryContent
                title = VectorL10n.locationSharingLiveLoading
                titleColor = theme.colors.tertiaryContent
                placeholderIcon = Asset.Images.locationLiveCellLoadingIcon.image
            case .started(let coordinate, let timeLeft):
                iconTint = theme.roomCellLocalisationIconStartedColor
                title = VectorL10n.liveLocationSharingBannerTitle
                timeLeftString = generateTimerString(for: timeLeft, isIncomingLocation: true)
                liveCoordinate = coordinate
            case .failure:
                iconTint = theme.roomCellLocalisationErrorColor
                title = VectorL10n.locationSharingLiveError
                rightButtonTitle = VectorL10n.retry
                rightButtonTag = .retrySharing
            case .stopped:
                iconTint = theme.colors.tertiaryContent
                title = VectorL10n.liveLocationSharingEnded
                titleColor = theme.colors.tertiaryContent
                placeholderIcon = Asset.Images.locationLiveCellEndedIcon.image
            }
        case .outgoing(let liveLocationSharingStatus):
            switch liveLocationSharingStatus {
            case .starting:
                iconTint = theme.colors.tertiaryContent
                title = VectorL10n.locationSharingLiveLoading
                titleColor = theme.colors.tertiaryContent
                placeholderIcon = Asset.Images.locationLiveCellLoadingIcon.image
            case .started(let coordinate, let timeLeft):
                iconTint = theme.roomCellLocalisationIconStartedColor
                title = VectorL10n.liveLocationSharingBannerTitle
                timeLeftString = generateTimerString(for: timeLeft, isIncomingLocation: false)
                rightButtonTitle = VectorL10n.stop
                liveCoordinate = coordinate
            case .failure:
                iconTint = theme.roomCellLocalisationErrorColor
                title = VectorL10n.locationSharingLiveError
                rightButtonTitle = VectorL10n.retry
                rightButtonTag = .retrySharing
            case .stopped:
                iconTint = theme.colors.tertiaryContent
                title = VectorL10n.liveLocationSharingEnded
                titleColor = theme.colors.tertiaryContent
                placeholderIcon = Asset.Images.locationLiveCellEndedIcon.image
            }
        }
        
        return LiveLocationBannerViewData(placeholderIcon: placeholderIcon,
                                          iconTint: iconTint,
                                          title: title,
                                          titleColor: titleColor,
                                          timeLeftString: timeLeftString,
                                          rightButtonTitle: rightButtonTitle,
                                          rightButtonTag: rightButtonTag,
                                          coordinate: liveCoordinate)
    }
    
    private func generateTimerString(for timestamp: Double,
                                     isIncomingLocation: Bool) -> String? {
        let timerInSec = timestamp
        let timerString: String?
        if isIncomingLocation {
            timerString = VectorL10n.locationSharingLiveTimerIncoming(incomingTimerFormatter.string(from: Date(timeIntervalSince1970: timerInSec)))
        } else if let outgoingTimer = outgoingTimerFormatter.string(from: Date(timeIntervalSince1970: timerInSec).timeIntervalSinceNow) {
            timerString = VectorL10n.locationSharingLiveListItemTimeLeft(outgoingTimer)
        } else {
            timerString = nil
        }
        return timerString
    }
    
    // MARK: - Public
    
    public func displayStaticLocation(with viewData: RoomTimelineLocationViewData) {
        displayLocation(viewData.location,
                        userAvatarData: viewData.userAvatarData,
                        mapStyleURL: viewData.mapStyleURL,
                        bannerViewData: nil)
    }
    
    public func displayLiveLocation(with viewData: RoomTimelineLocationViewData, liveLocationViewState: TimelineLiveLocationViewState) {
        let bannerViewData = liveLocationBannerViewData(from: liveLocationViewState)
        displayLocation(bannerViewData.coordinate,
                        userAvatarData: viewData.userAvatarData,
                        mapStyleURL: viewData.mapStyleURL,
                        bannerViewData: bannerViewData)
        
    }
    
    
    // MARK: - Themable
    
    func update(theme: Theme) {
        Self.usernameColorGenerator.update(theme: theme)
        descriptionLabel.textColor = theme.colors.primaryContent
        descriptionLabel.font = theme.fonts.footnote
        descriptionIcon.tintColor = theme.colors.accent
        attributionLabel.textColor = theme.colors.accent
        layer.borderColor = theme.colors.quinaryContent.cgColor
        self.theme = theme
    }
    
    // MARK: - MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return annotationView
    }
    
    // MARK: - Action
    
    @IBAction private func didTapTightButton(_ sender: Any) {
        if rightButton.tag == RightButtonTag.stopSharing.rawValue {
            delegate?.roomTimelineLocationViewDidTapStopButton(self)
        } else if rightButton.tag == RightButtonTag.retrySharing.rawValue {
            delegate?.roomTimelineLocationViewDidTapRetryButton(self)
        }
    }
}
