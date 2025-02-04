// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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

struct TimelineLiveLocationViewData {
    let status: LiveLocationSharingStatus
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
    
    var showMap: Bool {
        guard case .started = status else {
            return false
        }
        return true
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
    @IBOutlet private var placeholderIconView: UIImageView!
    @IBOutlet private var liveLocationContainerView: UIView!
    @IBOutlet private var liveLocationIcon: UIImageView!
    @IBOutlet private var liveLocationIconBackgroundView: UIView!
    @IBOutlet private var liveLocationStatusLabel: UILabel!
    @IBOutlet private var liveLocationTimerLabel: UILabel!
    @IBOutlet private var rightButton: UIButton!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!
    
    @IBOutlet private var mapLoadingErrorContainerView: UIView!
    @IBOutlet private var mapLoadingErrorImageView: UIImageView!
    @IBOutlet private var mapLoadingErrorMessageLabel: UILabel!
    
    private var mapView: MGLMapView!
    
    private var isMapViewLoadingFailed: Bool = false {
        didSet {
            if oldValue != isMapViewLoadingFailed {
                self.mapViewLoadingStateDidChange()
            }
        }
    }
    private var annotationView: LocationMarkerView?
    private static var usernameColorGenerator = UserNameColorGenerator()
    private var theme: Theme!
    private var placeholderBackgroundImage: UIImage?
    private var placeholderIcon: UIImage?
    
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
        
        mapLoadingErrorContainerView.isHidden = true
        mapLoadingErrorImageView.image = Asset.Images.locationMapError.image
        mapLoadingErrorMessageLabel.text = VectorL10n.locationSharingMapLoadingError
        
        theme = ThemeService.shared().theme
    }
    
    // MARK: - Private
    
    private func resetMapViewLoadingState() {
        self.isMapViewLoadingFailed = false
    }
    
    private func mapViewLoadingStateDidChange() {
        
        if mapView.isHidden == false && self.isMapViewLoadingFailed {
            mapLoadingErrorContainerView.isHidden = false
            mapView.isHidden = true
            attributionLabel.isHidden = true
        } else {
            mapLoadingErrorContainerView.isHidden = true
        }
    }
    
    private func displayLocation(_ location: CLLocationCoordinate2D?,
                                 userAvatarData: AvatarViewData? = nil,
                                 mapStyleURL: URL,
                                 bannerViewData: TimelineLiveLocationViewData? = nil) {
        
        resetMapViewLoadingState()
        
        if let location = location {
            mapView.isHidden = false
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
            placeholderBackground.isHidden = true
            placeholderIconView.isHidden = true
            return
        }
        
        liveLocationContainerView.isHidden = false
        liveLocationContainerView.backgroundColor = theme.colors.background.withAlphaComponent(0.90)
        
        liveLocationIcon.image = Asset.Images.locationLiveCellIcon.image
        liveLocationIcon.tintColor = bannerViewData.iconTint
        liveLocationIconBackgroundView.isHidden = !bannerViewData.showMap // Add white background when cell is not in starting or ended state
        
        liveLocationStatusLabel.text = bannerViewData.title
        liveLocationStatusLabel.textColor = bannerViewData.titleColor
        
        liveLocationTimerLabel.text = bannerViewData.timeLeftString
        liveLocationTimerLabel.textColor = theme.colors.tertiaryContent
        liveLocationTimerLabel.isHidden = !bannerViewData.showTimer
        
        rightButton.setTitle(bannerViewData.rightButtonTitle, for: .normal)
        rightButton.isHidden = !bannerViewData.showRightButton
        rightButton.tag = bannerViewData.rightButtonTag.rawValue
        
        placeholderBackground.isHidden = bannerViewData.showMap
        placeholderIconView.image = placeholderIcon
        placeholderIconView.isHidden = bannerViewData.showMap
        placeholderBackground.isHidden = bannerViewData.showMap
        placeholderBackground.image = placeholderBackgroundImage
        mapView.isHidden = !bannerViewData.showMap
        attributionLabel.isHidden = !bannerViewData.showMap
        
        switch bannerViewData.status {
        case .starting:
            placeholderIconView.isHidden = true
            activityIndicatorView.isHidden = false
            activityIndicatorView.startAnimating()
        default:
            activityIndicatorView.isHidden = true
            activityIndicatorView.stopAnimating()
        }
    }
    
    private func liveLocationBannerViewData(from viewState: TimelineLiveLocationViewState) -> TimelineLiveLocationViewData {
        
        let status: LiveLocationSharingStatus
        let iconTint: UIColor
        let title: String
        var titleColor: UIColor = theme.colors.primaryContent
        var timeLeftString: String?
        var rightButtonTitle: String?
        var rightButtonTag: RightButtonTag = .stopSharing
        var liveCoordinate: CLLocationCoordinate2D?

        switch viewState {
        case .incoming(let liveLocationSharingStatus):
            status = liveLocationSharingStatus
            switch liveLocationSharingStatus {
            case .starting:
                iconTint = theme.colors.quarterlyContent
                title = VectorL10n.locationSharingLiveLoading
                titleColor = theme.colors.tertiaryContent
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
                iconTint = theme.colors.quarterlyContent
                title = VectorL10n.liveLocationSharingEnded
                titleColor = theme.colors.tertiaryContent
            }
        case .outgoing(let liveLocationSharingStatus):
            status = liveLocationSharingStatus
            switch liveLocationSharingStatus {
            case .starting:
                iconTint = theme.colors.quarterlyContent
                title = VectorL10n.locationSharingLiveLoading
                titleColor = theme.colors.tertiaryContent
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
                iconTint = theme.colors.quarterlyContent
                title = VectorL10n.liveLocationSharingEnded
                titleColor = theme.colors.tertiaryContent
            }
        }
        
        return TimelineLiveLocationViewData(status: status,
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
        placeholderIcon = ThemeService.shared().isCurrentThemeDark() ? Asset.Images.locationLiveCellEndedDarkIcon.image : Asset.Images.locationLiveCellEndedLightIcon.image
        placeholderBackgroundImage = ThemeService.shared().isCurrentThemeDark() ? Asset.Images.locationBackgroundDarkImage.image : Asset.Images.locationBackgroundLightImage.image
        
        mapLoadingErrorContainerView.backgroundColor = theme.colors.system
        mapLoadingErrorMessageLabel.textColor = theme.colors.primaryContent
    }
    
    // MARK: - MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return annotationView
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MGLMapView, withError error: Error) {
        
        MXLog.error("[RoomTimelineLocationView] Failed to load map", context: error)
        
        self.isMapViewLoadingFailed = true
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        self.isMapViewLoadingFailed = false
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
