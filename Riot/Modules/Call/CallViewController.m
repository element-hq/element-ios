/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "CallViewController.h"

#import "GeneratedInterface-Swift.h"

#import "AvatarGenerator.h"

#import "UsersDevicesViewController.h"

#import "RiotNavigationController.h"

#import "IncomingCallView.h"

@interface CallViewController () <
PictureInPicturable,
DialpadViewControllerDelegate,
CallTransferMainViewControllerDelegate,
CallAudioRouteMenuViewDelegate>
{
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // Flag to compute self.shouldPromptForStunServerFallback
    BOOL promptForStunServerFallback;
}

@property (nonatomic, weak) IBOutlet UIView *pipViewContainer;

@property (nonatomic, strong) id<Theme> overriddenTheme;
@property (nonatomic, assign) BOOL inPiP;
@property (nonatomic, strong) CallPiPView *pipView;

@property (nonatomic, strong) CustomSizedPresentationController *customSizedPresentationController;
@property (nonatomic, strong) SlidingModalPresenter *slidingModalPresenter;
@property (nonatomic, strong) CallAudioRouteMenuView *audioRoutesMenuView;

@end

@implementation CallViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];

    promptForStunServerFallback = NO;
    _shouldPromptForStunServerFallback = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Back button
    
    UIImage *backButtonImage = AssetImages.backIcon.image;
    [self.backToAppButton setImage:backButtonImage forState:UIControlStateNormal];
    [self.backToAppButton setImage:backButtonImage forState:UIControlStateHighlighted];
    
    // Camera switch
    
    UIImage *cameraSwitchButtonImage = AssetImages.cameraSwitch.image;
    [self.cameraSwitchButton setImage:cameraSwitchButtonImage forState:UIControlStateNormal];
    [self.cameraSwitchButton setImage:cameraSwitchButtonImage forState:UIControlStateHighlighted];
    
    // Audio mute
    
    UIImage *audioMuteOffButtonImage = AssetImages.callAudioMuteOffIcon.image;
    UIImage *audioMuteOnButtonImage = AssetImages.callAudioMuteOnIcon.image;
    
    [self.audioMuteButton setImage:audioMuteOffButtonImage forState:UIControlStateNormal];
    [self.audioMuteButton setImage:audioMuteOffButtonImage forState:UIControlStateHighlighted];
    [self.audioMuteButton setImage:audioMuteOnButtonImage forState:UIControlStateSelected];
    
    // Video mute
    
    UIImage *videoOffButtonImage = AssetImages.callVideoMuteOffIcon.image;
    UIImage *videoOnButtonImage = AssetImages.callVideoMuteOnIcon.image;
    
    [self.videoMuteButton setImage:videoOffButtonImage forState:UIControlStateNormal];
    [self.videoMuteButton setImage:videoOffButtonImage forState:UIControlStateHighlighted];
    [self.videoMuteButton setImage:videoOnButtonImage forState:UIControlStateSelected];
    
    //  More
    
    UIImage *moreButtonImage = AssetImages.callMoreIcon.image;
    
    [self.moreButtonForVoice setImage:moreButtonImage forState:UIControlStateNormal];
    [self.moreButtonForVideo setImage:moreButtonImage forState:UIControlStateNormal];
    
    // Hang up
    
    UIImage *hangUpButtonImage = AssetImages.callHangupLarge.image;
    
    [self.endCallButton setTitle:nil forState:UIControlStateNormal];
    [self.endCallButton setTitle:nil forState:UIControlStateHighlighted];
    [self.endCallButton setImage:hangUpButtonImage forState:UIControlStateNormal];
    [self.endCallButton setImage:hangUpButtonImage forState:UIControlStateHighlighted];
    
    //  force orientation to portrait if phone
    if ([UIDevice currentDevice].isPhone)
    {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
    }
    
    [self updateLocalPreviewLayout];
    
    [self configureUserInterface];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.overriddenTheme.statusBarStyle;
}

- (void)configureUserInterface
{
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = self.overriddenTheme.userInterfaceStyle;
    }
    
    [self.overriddenTheme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.barTitleColor = self.overriddenTheme.textPrimaryColor;
    self.activityIndicator.backgroundColor = self.overriddenTheme.overlayBackgroundColor;
    
    self.backToAppButton.tintColor = self.overriddenTheme.callScreenButtonTintColor;
    self.cameraSwitchButton.tintColor = self.overriddenTheme.callScreenButtonTintColor;
    self.callerNameLabel.textColor = self.overriddenTheme.baseTextPrimaryColor;
    self.callStatusLabel.textColor = self.overriddenTheme.baseTextPrimaryColor;
    [self.resumeButton setTitleColor:self.overriddenTheme.tintColor
                            forState:UIControlStateNormal];
    [self.transferButton setTitleColor:self.overriddenTheme.tintColor
                              forState:UIControlStateNormal];
    
    self.localPreviewContainerView.layer.borderColor = self.overriddenTheme.tintColor.CGColor;
    self.localPreviewContainerView.layer.borderWidth = 2;
    self.localPreviewContainerView.layer.cornerRadius = 5;
    self.localPreviewContainerView.clipsToBounds = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    [super viewWillDisappear:animated];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    //  limit orientation to portrait only for phone
    if ([UIDevice currentDevice].isPhone)
    {
        return UIInterfaceOrientationMaskPortrait;
    }
    return [super supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if ([UIDevice currentDevice].isPhone)
    {
        return UIInterfaceOrientationPortrait;
    }
    return [super preferredInterfaceOrientationForPresentation];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - override MXKViewController

- (UIView *)createIncomingCallView
{
    if ([MXCallKitAdapter callKitAvailable])
    {
        return nil;
    }
    
    NSString *callInfo;
    if (self.mxCall.isVideoCall)
        callInfo = [VectorL10n callIncomingVideo];
    else
        callInfo = [VectorL10n callIncomingVoice];
    
    IncomingCallView *incomingCallView = [[IncomingCallView alloc] initWithCallerAvatar:self.peer.avatarUrl
                                                                           mediaManager:self.mainSession.mediaManager
                                                                       placeholderImage:self.picturePlaceholder
                                                                             callerName:self.peer.displayname
                                                                               callInfo:callInfo];
    
    // Incoming call is retained by call vc so use weak to avoid retain cycle
    __weak typeof(self) weakSelf = self;
    
    incomingCallView.onAnswer = ^{
        [weakSelf onButtonPressed:weakSelf.answerCallButton];
    };
    
    incomingCallView.onReject = ^{
        [weakSelf onButtonPressed:weakSelf.rejectCallButton];
    };
    
    return incomingCallView;
}

- (void)showAudioDeviceOptions
{
    MXiOSAudioOutputRouter *router = self.mxCall.audioOutputRouter;
    if (router.isAnyExternalDeviceConnected)
    {
        self.slidingModalPresenter = [SlidingModalPresenter new];
        
        _audioRoutesMenuView = [[CallAudioRouteMenuView alloc] initWithRoutes:router.availableOutputRoutes
                                                                 currentRoute:router.currentRoute];
        _audioRoutesMenuView.delegate = self;
        
        [self.slidingModalPresenter presentView:_audioRoutesMenuView
                                           from:self
                                       animated:true
                                        options:SlidingModalPresenter.CenterInScreenOption
                                     completion:nil];
    }
    else
    {
        //  toggle between built-in and loud speakers
        switch (router.currentRoute.routeType)
        {
            case MXiOSAudioOutputRouteTypeBuiltIn:
                [router changeCurrentRouteTo:router.loudSpeakersRoute];
                break;
            case MXiOSAudioOutputRouteTypeLoudSpeakers:
                [router changeCurrentRouteTo:router.builtInRoute];
                break;
            default:
                break;
        }
        
    }
}

- (void)configureSpeakerButton
{
    switch (self.mxCall.audioOutputRouter.currentRoute.routeType)
    {
        case MXiOSAudioOutputRouteTypeBuiltIn:
            [self.speakerButton setImage:AssetImages.callSpeakerOffIcon.image
                                forState:UIControlStateNormal];
            break;
        case MXiOSAudioOutputRouteTypeLoudSpeakers:
            [self.speakerButton setImage:AssetImages.callSpeakerOnIcon.image
                                forState:UIControlStateNormal];
            break;
        case MXiOSAudioOutputRouteTypeExternalWired:
        case MXiOSAudioOutputRouteTypeExternalBluetooth:
        case MXiOSAudioOutputRouteTypeExternalCar:
            [self.speakerButton setImage:AssetImages.callSpeakerExternalIcon.image
                                forState:UIControlStateNormal];
            break;
    }
}

#pragma mark - MXCallDelegate

- (void)call:(MXCall *)call stateDidChange:(MXCallState)state reason:(MXEvent *)event
{
    [super call:call stateDidChange:state reason:event];
    
    [self configurePiPView];

    [self checkStunServerFallbackWithCallState:state];
}

- (void)call:(MXCall *)call didEncounterError:(NSError *)error reason:(MXCallHangupReason)reason
{
    if ([error.domain isEqualToString:MXEncryptingErrorDomain]
        && error.code == MXEncryptingErrorUnknownDeviceCode)
    {
        // There are unknown devices, check what the user wants to do
        __weak __typeof(self) weakSelf = self;
        
        MXUsersDevicesMap<MXDeviceInfo*> *unknownDevices = error.userInfo[MXEncryptingErrorUnknownDeviceDevicesKey];
        
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n unknownDevicesAlertTitle]
                                                           message:[VectorL10n unknownDevicesAlert]
                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n unknownDevicesVerify]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               // Get the UsersDevicesViewController from the storyboard
                                                               UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
                                                               UsersDevicesViewController *usersDevicesViewController = [storyboard instantiateViewControllerWithIdentifier:@"UsersDevicesViewControllerStoryboardId"];
                                                               
                                                               [usersDevicesViewController displayUsersDevices:unknownDevices andMatrixSession:self.mainSession onComplete:^(BOOL doneButtonPressed) {
                                                                   
                                                                   if (doneButtonPressed)
                                                                   {
                                                                       // Retry the call
                                                                       if (call.isIncoming)
                                                                       {
                                                                           [call answer];
                                                                       }
                                                                       else
                                                                       {
                                                                           [call callWithVideo:call.isVideoCall];
                                                                       }
                                                                   }
                                                                   else
                                                                   {
                                                                       // Ignore the call
                                                                       [call hangupWithReason:reason];
                                                                   }
                                                               }];
                                                               
                                                               // Show this screen within a navigation controller
                                                               UINavigationController *usersDevicesNavigationController = [[RiotNavigationController alloc] init];
                                                               
                                                               // Set Riot navigation bar colors
                                                               [ThemeService.shared.theme applyStyleOnNavigationBar:usersDevicesNavigationController.navigationBar];
                                                               usersDevicesNavigationController.navigationBar.barTintColor = ThemeService.shared.theme.backgroundColor;

                                                               [usersDevicesNavigationController pushViewController:usersDevicesViewController animated:NO];
                                                               
                                                               [self presentViewController:usersDevicesNavigationController animated:YES completion:nil];
                                                               
                                                           }
                                                           
                                                       }]];
        
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:(call.isIncoming ? [VectorL10n unknownDevicesAnswerAnyway] : [VectorL10n unknownDevicesCallAnyway])
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               // Acknowledge the existence of all devices
                                                               [self startActivityIndicator];
                                                               if (![self.mainSession.crypto isKindOfClass:[MXLegacyCrypto class]])
                                                               {
                                                                   MXLogFailure(@"[CallViewController] call: Only legacy crypto supports manual setting of known devices");
                                                                   return;
                                                               }
                                                               [(MXLegacyCrypto *)self.mainSession.crypto setDevicesKnown:unknownDevices complete:^{
                                                                   
                                                                   [self stopActivityIndicator];
                                                                   
                                                                   // Retry the call
                                                                   if (call.isIncoming)
                                                                   {
                                                                       [call answer];
                                                                   }
                                                                   else
                                                                   {
                                                                       [call callWithVideo:call.isVideoCall];
                                                                   }
                                                               }];
                                                           }
                                                           
                                                       }]];
        
        [currentAlert mxk_setAccessibilityIdentifier:@"CallVCUnknownDevicesAlert"];
        [self presentViewController:currentAlert animated:YES completion:nil];
    }
    else
    {
        [super call:call didEncounterError:error reason:reason];
    }
}


#pragma mark - Fallback STUN server

- (void)checkStunServerFallbackWithCallState:(MXCallState)callState
{
    // Detect if we should display the prompt to fallback to the STUN server defined
    // in the app plist if the homeserver does not provide STUN or TURN servers.
    // We should display it if the call ends while we were in connecting state
    if (!self.mainSession.callManager.turnServers
        && !self.mainSession.callManager.fallbackSTUNServer
        && !RiotSettings.shared.isAllowStunServerFallbackHasBeenSetOnce)
    {
        switch (callState)
        {
            case MXCallStateConnecting:
                promptForStunServerFallback = YES;
                break;

            case MXCallStateConnected:
                promptForStunServerFallback = NO;
                break;

            case MXCallStateEnded:
                if (promptForStunServerFallback)
                {
                    _shouldPromptForStunServerFallback = YES;
                }

            default:
                // There is nothing to do for other states
                break;
        }
    }
}


#pragma mark - Properties

- (id<Theme>)overriddenTheme
{
    if (_overriddenTheme == nil)
    {
        _overriddenTheme = [DarkTheme new];
    }
    return _overriddenTheme;
}

- (CallPiPView *)pipView
{
    if (_pipView == nil)
    {
        _pipView = [CallPiPView instantiateWithSession:self.mainSession];
        [_pipView updateWithTheme:self.overriddenTheme];
    }
    return _pipView;
}

- (void)setMxCallOnHold:(MXCall *)mxCallOnHold
{
    [super setMxCallOnHold:mxCallOnHold];
    
    [self configurePiPView];
}

- (UIImage*)picturePlaceholder
{
    CGFloat fontSize = floor(self.callerImageViewWidthConstraint.constant * 0.7);
    
    if (self.peer)
    {
        // Use the vector style placeholder
        return [AvatarGenerator generateAvatarForMatrixItem:self.peer.userId
                                            withDisplayName:self.peer.displayname
                                                       size:self.callerImageViewWidthConstraint.constant
                                                andFontSize:fontSize];
    }
    else if (self.mxCall.room)
    {
        return [AvatarGenerator generateAvatarForMatrixItem:self.mxCall.room.roomId
                                            withDisplayName:self.mxCall.room.summary.displayname
                                                       size:self.callerImageViewWidthConstraint.constant
                                                andFontSize:fontSize];
    }
    
    return [MXKTools paintImage:AssetImages.placeholder.image
                      withColor:self.overriddenTheme.tintColor];
}

- (void)updatePeerInfoDisplay
{
    [super updatePeerInfoDisplay];
    
    NSString *peerAvatarURL;

    if (self.peer)
    {
        peerAvatarURL = self.peer.avatarUrl;
    }
    else if (self.mxCall.isConferenceCall)
    {
        peerAvatarURL = self.mxCall.room.summary.avatar;
    }

    self.blurredCallerImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.callerImageView.contentMode = UIViewContentModeScaleAspectFill;
    if (peerAvatarURL)
    {
        // Retrieve the avatar in full resolution
        [self.blurredCallerImageView setImageURI:peerAvatarURL
                                        withType:nil
                             andImageOrientation:UIImageOrientationUp
                                    previewImage:self.picturePlaceholder
                                    mediaManager:self.mainSession.mediaManager];

        // Retrieve the avatar in full resolution
        [self.callerImageView setImageURI:peerAvatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.picturePlaceholder
                             mediaManager:self.mainSession.mediaManager];
    }
    else
    {
        self.blurredCallerImageView.image = self.picturePlaceholder;
        self.callerImageView.image = self.picturePlaceholder;
    }
}

#pragma mark - Sounds

- (NSURL*)audioURLWithName:(NSString*)soundName
{
    NSURL *audioUrl;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:soundName ofType:@"mp3"];
    if (path)
    {
        audioUrl = [NSURL fileURLWithPath:path];
    }
    
    // Use by default the matrix kit sounds.
    if (!audioUrl)
    {
        audioUrl = [super audioURLWithName:soundName];
    }
    
    return audioUrl;
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _chatButton)
    {
        if (self.delegate)
        {
            // Dismiss the view controller whereas the call is still running
            [self.delegate dismissCallViewController:self completion:^{
                
                if (self.mxCall.room)
                {
                    // Open the room page
                    Analytics.shared.viewRoomTrigger = AnalyticsViewRoomTriggerInCall;
                    [[AppDelegate theDelegate] showRoom:self.mxCall.room.roomId andEventId:nil withMatrixSession:self.mxCall.room.mxSession];
                }
                
            }];
        }
    }
    else
    {
        [super onButtonPressed:sender];
    }
}

- (void)setInPiP:(BOOL)inPiP
{
    _inPiP = inPiP;
    
    if (_inPiP)
    {
        self.overlayContainerView.hidden = YES;
        self.callerImageView.hidden = YES;
        self.callerNameLabel.hidden = YES;
        self.callStatusLabel.hidden = YES;
        self.localPreviewContainerView.hidden = YES;
        self.localPreviewActivityView.hidden = YES;
        
        if (self.pipViewContainer.subviews.count == 0)
        {
            [self.pipViewContainer vc_addSubViewMatchingParent:self.pipView];
        }
        [self configurePiPView];
        self.pipViewContainer.hidden = NO;
    }
    else
    {
        self.pipViewContainer.hidden = YES;
        self.localPreviewContainerView.hidden = !self.mxCall.isVideoCall;
        self.callerImageView.hidden = self.mxCall.isVideoCall && self.mxCall.state == MXCallStateConnected;
        self.callerNameLabel.hidden = NO;
        self.callStatusLabel.hidden = NO;
        
        //  show controls when coming back from PiP mode
        [self showOverlayContainer:YES];
    }
}

- (void)showOverlayContainer:(BOOL)isShown
{
    if (self.inPiP)
    {
        return;
    }
    
    [super showOverlayContainer:isShown];
}

#pragma mark - DTMF

- (void)openDialpad
{
    DialpadConfiguration *config = [[DialpadConfiguration alloc] initWithShowsTitle:YES
                                                                   showsCloseButton:YES
                                                               showsBackspaceButton:NO
                                                                    showsCallButton:NO
                                                                  formattingEnabled:NO
                                                                     editingEnabled:NO
                                                                          playTones:YES];
    DialpadViewController *controller = [DialpadViewController instantiateWithConfiguration:config];
    controller.delegate = self;
    self.customSizedPresentationController = [[CustomSizedPresentationController alloc] initWithPresentedViewController:controller presentingViewController:self];
    self.customSizedPresentationController.dismissOnBackgroundTap = NO;
    self.customSizedPresentationController.cornerRadius = 16;
    
    controller.transitioningDelegate = self.customSizedPresentationController;
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Call Transfer

- (void)openCallTransfer
{
    CallTransferMainViewController *controller = [CallTransferMainViewController instantiateWithSession:self.mainSession ignoredUserIds:@[self.peer.userId]];
    controller.delegate = self;
    UINavigationController *navController = [[RiotNavigationController alloc] initWithRootViewController:controller];
    [self.mxCall hold:YES];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - DialpadViewControllerDelegate

- (void)dialpadViewControllerDidTapClose:(DialpadViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
    self.customSizedPresentationController = nil;
}

- (void)dialpadViewControllerDidTapDigit:(DialpadViewController *)viewController digit:(NSString *)digit
{
    if (digit.length == 0)
    {
        return;
    }
    BOOL result = [self.mxCall sendDTMF:digit];
    
    MXLogDebug(@"[CallViewController] Sending DTMF tones %@", result ? @"succeeded": @"failed");
}

#pragma mark - CallTransferMainViewControllerDelegate

- (void)callTransferMainViewControllerDidComplete:(CallTransferMainViewController *)viewController consult:(BOOL)consult contact:(MXKContact *)contact phoneNumber:(NSString *)phoneNumber
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    void(^failureBlock)(NSError *_Nullable) = ^(NSError *error) {
        [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        MXWeakify(self);
        
        self->currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n callTransferErrorTitle]
                                                                 message:[VectorL10n callTransferErrorMessage]
                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        [self->currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
            
            MXStrongifyAndReturnIfNil(self);
            self->currentAlert = nil;
        }]];
        
        [self presentViewController:self->currentAlert animated:YES completion:nil];
    };
    
    void(^continueBlock)(NSString *_Nonnull) = ^(NSString *targetUserId) {
        MXUserModel *targetUser = [[MXUserModel alloc] initWithUserId:targetUserId
                                                          displayname:contact.displayName
                                                            avatarUrl:contact.matrixAvatarURL];
        MXUserModel *transfereeUser = [[MXUserModel alloc] initWithUser:self.peer];

        [self.mainSession.callManager transferCall:self.mxCall
                                                to:targetUser
                                    withTransferee:transfereeUser
                                      consultFirst:consult
                                           success:^(NSString * _Nonnull newCallId){
            MXLogDebug(@"Call transfer succeeded with new call ID: %@", newCallId);
        } failure:^(NSError * _Nullable error) {
            MXLogDebug(@"Call transfer failed with error: %@", error);
            failureBlock(error);
        }];
    };
    
    if (contact)
    {
        continueBlock(contact.matrixIdentifiers.firstObject);
    }
    else if (phoneNumber)
    {
        MXWeakify(self);
        [self.mainSession.callManager getThirdPartyUserFrom:phoneNumber success:^(MXThirdPartyUserInstance * _Nonnull user) {
            if (weakself == nil) {
                return;
            }
            
            continueBlock(user.userId);
        } failure:^(NSError * _Nullable error) {
            failureBlock(error);
        }];
    }
}

- (void)callTransferMainViewControllerDidCancel:(CallTransferMainViewController *)viewController
{
    [self.mxCall hold:NO];
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - PiP

- (void)configurePiPView
{
    if (self.inPiP)
    {
        [self.pipView configureWithCall:self.mxCall
                                   peer:self.peer
                             onHoldCall:self.mxCallOnHold
                             onHoldPeer:self.peerOnHold];
    }
}

#pragma mark - PictureInPicturable

- (void)didEnterPiP
{
    self.inPiP = YES;
}

- (void)willExitPiP
{
    self.pipViewContainer.hidden = YES;
}

- (void)didExitPiP
{
    self.inPiP = NO;
}

#pragma mark - CallAudioRouteMenuViewDelegate

- (void)callAudioRouteMenuView:(CallAudioRouteMenuView *)view didSelectRoute:(MXiOSAudioOutputRoute *)route
{
    [self.mxCall.audioOutputRouter changeCurrentRouteTo:route];
    [self.slidingModalPresenter dismissWithAnimated:YES completion:nil];
}

@end
