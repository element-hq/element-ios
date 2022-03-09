/*
 Copyright 2015 OpenMarket Ltd
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

#import "MXKCallViewController.h"

@import MatrixSDK;

#import "MXKAppSettings.h"
#import "MXKSoundPlayer.h"
#import "MXKTools.h"
#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

NSString *const kMXKCallViewControllerWillAppearNotification = @"kMXKCallViewControllerWillAppearNotification";
NSString *const kMXKCallViewControllerAppearedNotification = @"kMXKCallViewControllerAppearedNotification";
NSString *const kMXKCallViewControllerWillDisappearNotification = @"kMXKCallViewControllerWillDisappearNotification";
NSString *const kMXKCallViewControllerDisappearedNotification = @"kMXKCallViewControllerDisappearedNotification";
NSString *const kMXKCallViewControllerBackToAppNotification = @"kMXKCallViewControllerBackToAppNotification";

static const CGFloat kLocalPreviewMargin = 20;

@interface MXKCallViewController ()
{
    NSTimer *hideOverlayTimer;
    NSTimer *updateStatusTimer;
    
    Boolean isMovingLocalPreview;
    Boolean isSelectingLocalPreview;
    
    CGPoint startNewLocalMove;

    /**
     The popup showed in case of call stack error.
     */
    UIAlertController *errorAlert;
    
    // the room events listener
    id roomListener;
    
    // Observe kMXRoomDidFlushDataNotification to take into account the updated room members when the room history is flushed.
    id roomDidFlushDataNotificationObserver;
    
    // Observe AVAudioSessionRouteChangeNotification
    id audioSessionRouteChangeNotificationObserver;
    
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    //  Current peer display name
    NSString *peerDisplayName;
}

@property (nonatomic, assign) Boolean isRinging;

@property (nonatomic, nullable) UIView *incomingCallView;

@property (nonatomic, strong) UITapGestureRecognizer *onHoldCallContainerTapRecognizer;

@end

@implementation MXKCallViewController
@synthesize backgroundImageView;
@synthesize localPreviewContainerView, localPreviewVideoView, localPreviewActivityView, remotePreviewContainerView;
@synthesize overlayContainerView, callContainerView, callerImageView, callerNameLabel, callStatusLabel;
@synthesize callToolBar, rejectCallButton, answerCallButton, endCallButton;
@synthesize callControlContainerView, speakerButton, audioMuteButton, videoMuteButton;
@synthesize backToAppButton, cameraSwitchButton;
@synthesize backToAppStatusWindow;
@synthesize mxCall;
@synthesize mxCallOnHold;
@synthesize onHoldCallerImageView;
@synthesize onHoldCallContainerView;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)callViewController:(MXCall*)call
{
    MXKCallViewController *instance = [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                                                     bundle:[NSBundle bundleForClass:self.class]];
    
    // Load the view controller's view now (buttons and views will then be available).
    if ([instance respondsToSelector:@selector(loadViewIfNeeded)])
    {
        // iOS 9 and later
        [instance loadViewIfNeeded];
    }
    else if (instance.view)
    {
        // Patch: on iOS < 9.0, we load the view by calling its getter.
    }
    
    instance.mxCall = call;
    
    return instance;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    _playRingtone = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    updateStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimeStatusLabel) userInfo:nil repeats:YES];
    
    self.callerImageView.defaultBackgroundColor = [UIColor clearColor];
    self.backToAppButton.backgroundColor = [UIColor clearColor];
    self.audioMuteButton.backgroundColor = [UIColor clearColor];
    self.videoMuteButton.backgroundColor = [UIColor clearColor];
    self.resumeButton.backgroundColor = [UIColor clearColor];
    self.moreButton.backgroundColor = [UIColor clearColor];
    self.speakerButton.backgroundColor = [UIColor clearColor];
    self.transferButton.backgroundColor = [UIColor clearColor];
    
    [self.backToAppButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_backtoapp"] forState:UIControlStateNormal];
    [self.backToAppButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_backtoapp"] forState:UIControlStateHighlighted];
    [self.audioMuteButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_audio_unmute"] forState:UIControlStateNormal];
    [self.audioMuteButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_audio_mute"] forState:UIControlStateSelected];
    [self.videoMuteButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_video_unmute"] forState:UIControlStateNormal];
    [self.videoMuteButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_video_mute"] forState:UIControlStateSelected];
    [self.moreButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_call_more"] forState:UIControlStateNormal];
    [self.moreButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_call_more"] forState:UIControlStateSelected];
    [self.speakerButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_speaker_off"] forState:UIControlStateNormal];
    [self.speakerButton setImage:[NSBundle mxk_imageFromMXKAssetsBundleWithName:@"icon_speaker_on"] forState:UIControlStateSelected];
    
    // Localize string
    [answerCallButton setTitle:[VectorL10n answerCall] forState:UIControlStateNormal];
    [answerCallButton setTitle:[VectorL10n answerCall] forState:UIControlStateHighlighted];
    [rejectCallButton setTitle:[VectorL10n rejectCall] forState:UIControlStateNormal];
    [rejectCallButton setTitle:[VectorL10n rejectCall] forState:UIControlStateHighlighted];
    [endCallButton setTitle:[VectorL10n endCall] forState:UIControlStateNormal];
    [endCallButton setTitle:[VectorL10n endCall] forState:UIControlStateHighlighted];
    [_resumeButton setTitle:[VectorL10n resumeCall] forState:UIControlStateNormal];
    [_resumeButton setTitle:[VectorL10n resumeCall] forState:UIControlStateHighlighted];
    
    // Refresh call information
    self.mxCall = mxCall;
    
    // Listen to AVAudioSession activation notification if CallKit is available and enabled
    BOOL isCallKitAvailable = [MXCallKitAdapter callKitAvailable] && [MXKAppSettings standardAppSettings].isCallKitEnabled;
    if (isCallKitAvailable)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAudioSessionActivationNotification)
                                                     name:kMXCallKitAdapterAudioSessionDidActive
                                                   object:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXCallKitAdapterAudioSessionDidActive object:nil];

    [self removeObservers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKCallViewControllerWillAppearNotification object:nil];
    
    [self updateLocalPreviewLayout];
    [self showOverlayContainer:YES];
    
    if (mxCall)
    {
        // Refresh call display according to the call room state.
        [self callRoomStateDidChange:^{
            // Refresh call status
            [self call:self->mxCall stateDidChange:self->mxCall.state reason:nil];
        }];

    }
    
    if (_delegate)
    {
        backToAppButton.hidden = NO;
    }
    else
    {
        backToAppButton.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKCallViewControllerAppearedNotification object:nil];
    
    // trick to hide the volume at launch
    // as the mininum volume is forced by the application
    // the volume popup can be displayed
    //    volumeView = [[MPVolumeView alloc] initWithFrame: CGRectMake(5000, 5000, 0, 0)];
    //    [self.view addSubview: volumeView];
    //
    //    dispatch_after(dispatch_walltime(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    //        [volumeView removeFromSuperview];
    //    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKCallViewControllerWillDisappearNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKCallViewControllerDisappearedNotification object:nil];
}

- (void)dismiss
{
    if (_delegate)
    {
        [_delegate dismissCallViewController:self completion:nil];
    }
    else
    {
        // Auto dismiss after few seconds
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }
}

#pragma mark - override MXKViewController

- (void)destroy
{
    self.peer = nil;
    
    self.mxCall = nil;
    
    _delegate = nil;
    
    self.isRinging = NO;
    
    [hideOverlayTimer invalidate];
    [updateStatusTimer invalidate];
    
    _incomingCallView = nil;
    
    _onHoldCallContainerTapRecognizer = nil;
    
    [super destroy];
}

#pragma mark - Properties

- (UIImage *)picturePlaceholder
{
    return [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"default-profile"];
}

- (void)setMxCall:(MXCall *)call
{
    // Remove previous call (if any)
    if (mxCall)
    {
        mxCall.delegate = nil;
        mxCall.selfVideoView = nil;
        mxCall.remoteVideoView = nil;
        [self removeMatrixSession:self.mainSession];
        
        [self removeObservers];
        
        mxCall = nil;
    }
    
    if (call && call.room)
    {
        mxCall = call;
        
        [self addMatrixSession:mxCall.room.mxSession];

        MXWeakify(self);

        // Register a listener to handle messages related to room name, members...
        roomListener = [mxCall.room listenToEventsOfTypes:@[kMXEventTypeStringRoomName, kMXEventTypeStringRoomTopic, kMXEventTypeStringRoomAliases, kMXEventTypeStringRoomAvatar, kMXEventTypeStringRoomCanonicalAlias, kMXEventTypeStringRoomMember] onEvent:^(MXEvent *event, MXTimelineDirection direction, MXRoomState *roomState) {
            MXStrongifyAndReturnIfNil(self);

            // Consider only live events
            if (self->mxCall && direction == MXTimelineDirectionForwards)
            {
                // The room state has been changed
                [self callRoomStateDidChange:nil];
            }
        }];
        
        // Observe room history flush (sync with limited timeline, or state event redaction)
        roomDidFlushDataNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXRoomDidFlushDataNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            MXStrongifyAndReturnIfNil(self);
            
            MXRoom *room = notif.object;
            if (self->mxCall && self.mainSession == room.mxSession && [self->mxCall.room.roomId isEqualToString:room.roomId])
            {
                // The existing room history has been flushed during server sync.
                // Take into account the updated room state
                [self callRoomStateDidChange:nil];
            }
            
        }];
        
        audioSessionRouteChangeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            [self updateProximityAndSleep];
            
        }];
        
        // Hide video mute on voice call
        self.videoMuteButton.hidden = !call.isVideoCall;
        
        // Hide camera switch on voice call
        self.cameraSwitchButton.hidden = !call.isVideoCall;
        
        _moreButtonForVideo.hidden = !call.isVideoCall;
        _moreButtonForVoice.hidden = call.isVideoCall;
        
        // Observe call state change
        call.delegate = self;

        // Display room call information
        [self callRoomStateDidChange:^{
            [self call:call stateDidChange:call.state reason:nil];
        }];
        
        if (call.isVideoCall && localPreviewContainerView)
        {
            // Access to the camera is mandatory to display the self view
            // Check the permission right now
            NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
            [MXKTools checkAccessForMediaType:AVMediaTypeVideo
                          manualChangeMessage:[VectorL10n cameraAccessNotGrantedForCall:appDisplayName]

                    showPopUpInViewController:self completionHandler:^(BOOL granted) {

                   if (granted)
                   {
                       self->localPreviewContainerView.hidden = NO;
                       self->remotePreviewContainerView.hidden = NO;

                       call.selfVideoView = self->localPreviewVideoView;
                       call.remoteVideoView = self->remotePreviewContainerView;
                       [self applyDeviceOrientation:YES];

                       [[NSNotificationCenter defaultCenter] addObserver:self
                                                                selector:@selector(deviceOrientationDidChange)
                                                                    name:UIDeviceOrientationDidChangeNotification
                                                                  object:nil];
                   }
               }];
        }
        else
        {
            localPreviewContainerView.hidden = YES;
            remotePreviewContainerView.hidden = YES;
        }
    }
}

- (void)setMxCallOnHold:(MXCall *)callOnHold
{
    if (mxCallOnHold == callOnHold)
    {
        //  setting same property, return
        return;
    }
    
    mxCallOnHold = callOnHold;
    
    if (mxCallOnHold)
    {
        self.onHoldCallContainerView.hidden = NO;
        [self.onHoldCallContainerView addGestureRecognizer:self.onHoldCallContainerTapRecognizer];
        [self.onHoldCallContainerView setUserInteractionEnabled:YES];
        
        // Handle peer here
        if (mxCallOnHold.isIncoming)
        {
            self.peerOnHold = [mxCallOnHold.room.mxSession getOrCreateUser:mxCallOnHold.callerId];
        }
        else
        {
            // For 1:1 call, find the other peer
            // Else, the room information will be used to display information about the call
            MXWeakify(self);
            [mxCallOnHold.room state:^(MXRoomState *roomState) {
                MXStrongifyAndReturnIfNil(self);
            
                MXUser *theMember = nil;
                NSArray *members = roomState.members.joinedMembers;
                for (MXUser *member in members)
                {
                    if (![member.userId isEqualToString:self->mxCallOnHold.callerId])
                    {
                        theMember = member;
                        break;
                    }
                }

                self.peerOnHold = theMember;
            }];
        }
    }
    else
    {
        [self.onHoldCallContainerView removeGestureRecognizer:self.onHoldCallContainerTapRecognizer];
        [self.onHoldCallContainerView setUserInteractionEnabled:NO];
        self.onHoldCallContainerView.hidden = YES;
        self.peerOnHold = nil;
    }
}

- (void)setPeer:(MXUser *)peer
{
    _peer = peer;
    
    [self updatePeerInfoDisplay];
}

- (void)setPeerOnHold:(MXUser *)peerOnHold
{
    _peerOnHold = peerOnHold;
    
    NSString *peerAvatarURL;
    
    if (_peerOnHold)
    {
        peerAvatarURL = _peerOnHold.avatarUrl;
    }
    else if (mxCall.isConferenceCall)
    {
        peerAvatarURL = mxCallOnHold.room.summary.avatar;
    }
    
    onHoldCallerImageView.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    if (peerAvatarURL)
    {
        // Suppose avatar url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
        onHoldCallerImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder;
        onHoldCallerImageView.enableInMemoryCache = YES;
        [onHoldCallerImageView setImageURI:peerAvatarURL
                                  withType:nil
                       andImageOrientation:UIImageOrientationUp
                             toFitViewSize:onHoldCallerImageView.frame.size
                                withMethod:MXThumbnailingMethodCrop
                              previewImage:self.picturePlaceholder
                              mediaManager:self.mainSession.mediaManager];
    }
    else
    {
        onHoldCallerImageView.image = self.picturePlaceholder;
    }
}

- (void)updatePeerInfoDisplay
{
    NSString *peerAvatarURL;
    
    if (_peer)
    {
        peerDisplayName = [_peer displayname];
        if (!peerDisplayName.length)
        {
            peerDisplayName = _peer.userId;
        }
        peerAvatarURL = _peer.avatarUrl;
    }
    else if (mxCall.isConferenceCall)
    {
        peerDisplayName = mxCall.room.summary.displayname;
        peerAvatarURL = mxCall.room.summary.avatar;
    }
    
    if (mxCall.isConsulting)
    {
        callerNameLabel.text = [VectorL10n callConsultingWithUser:peerDisplayName];
    }
    else
    {
        if (mxCall.isVideoCall)
        {
            callerNameLabel.text = [VectorL10n callVideoWithUser:peerDisplayName];
        }
        else
        {
            callerNameLabel.text = [VectorL10n callVoiceWithUser:peerDisplayName];
        }
    }
    
    if (peerAvatarURL)
    {
        // Suppose avatar url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
        callerImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder;
        callerImageView.enableInMemoryCache = YES;
        [callerImageView setImageURI:peerAvatarURL
                            withType:nil
                 andImageOrientation:UIImageOrientationUp
                       toFitViewSize:callerImageView.frame.size
                          withMethod:MXThumbnailingMethodCrop
                        previewImage:self.picturePlaceholder
                        mediaManager:self.mainSession.mediaManager];
    }
    else
    {
        callerImageView.image = self.picturePlaceholder;
    }
    
    // Round caller image view
    [callerImageView.layer setCornerRadius:callerImageView.frame.size.width / 2];
    callerImageView.clipsToBounds = YES;
}

- (void)setIsRinging:(Boolean)isRinging
{
    if (_isRinging != isRinging)
    {
        if (isRinging)
        {
            NSURL *audioUrl;
            if (mxCall.isIncoming)
            {
                if (self.playRingtone)
                    audioUrl = [self audioURLWithName:@"ring"];
            }
            else
            {
                audioUrl = [self audioURLWithName:@"ringback"];
            }
            
            if (audioUrl)
            {
                [[MXKSoundPlayer sharedInstance] playSoundAt:audioUrl repeat:YES vibrate:mxCall.isIncoming routeToBuiltInReceiver:!mxCall.isIncoming];
            }
        }
        else
        {
            [[MXKSoundPlayer sharedInstance] stopPlayingWithAudioSessionDeactivation:NO];
        }
        
        _isRinging = isRinging;
    }
}

- (void)setDelegate:(id<MXKCallViewControllerDelegate>)delegate
{
    _delegate = delegate;
    
    if (_delegate)
    {
        backToAppButton.hidden = NO;
    }
    else
    {
        backToAppButton.hidden = YES;
    }
}

- (UITapGestureRecognizer *)onHoldCallContainerTapRecognizer
{
    if (_onHoldCallContainerTapRecognizer == nil)
    {
        _onHoldCallContainerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(onHoldCallContainerTapped:)];
    }
    return _onHoldCallContainerTapRecognizer;
}

- (BOOL)isDisplayingAlert
{
    return errorAlert != nil;
}

- (UIButton *)moreButton
{
    if (mxCall.isVideoCall)
    {
        return _moreButtonForVideo;
    }
    return _moreButtonForVoice;
}

#pragma mark - Sounds

- (NSURL *)audioURLWithName:(NSString *)soundName
{
    return [NSBundle mxk_audioURLFromMXKAssetsBundleWithName:soundName];
}

#pragma mark - Actions

- (void)onHoldCallContainerTapped:(UITapGestureRecognizer *)recognizer
{
    if ([self.delegate respondsToSelector:@selector(callViewControllerDidTapOnHoldCall:)])
    {
        [self.delegate callViewControllerDidTapOnHoldCall:self];
    }
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == answerCallButton)
    {
        // If we are here, we have access to the camera
        // The following check is mainly to check microphone access permission
        NSString *appDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];

        [MXKTools checkAccessForCall:mxCall.isVideoCall
         manualChangeMessageForAudio:[VectorL10n microphoneAccessNotGrantedForCall:appDisplayName]
         manualChangeMessageForVideo:[VectorL10n cameraAccessNotGrantedForCall:appDisplayName]
           showPopUpInViewController:self completionHandler:^(BOOL granted) {

               if (granted)
               {
                   [self->mxCall answer];
               }
           }];
    }
    else if (sender == rejectCallButton || sender == endCallButton)
    {
        if (mxCall.state != MXCallStateEnded)
        {
            [mxCall hangup];
        }
        else
        {
            [self dismiss];
        }
    }
    else if (sender == audioMuteButton)
    {
        mxCall.audioMuted = !mxCall.audioMuted;
        audioMuteButton.selected = mxCall.audioMuted;
    }
    else if (sender == videoMuteButton)
    {
        mxCall.videoMuted = !mxCall.videoMuted;
        videoMuteButton.selected = mxCall.videoMuted;
    }
    else if (sender == _resumeButton)
    {
        [mxCall hold:NO];
    }
    else if (sender == self.moreButton)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        MXWeakify(self);
        
        NSMutableArray<UIAlertAction *> *actions = [NSMutableArray arrayWithCapacity:4];
        
        if (self.speakerButton == nil)
        {
            //  audio device action
            UIAlertAction *audioDeviceAction = [UIAlertAction actionWithTitle:[VectorL10n callMoreActionsChangeAudioDevice]
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                
                MXStrongifyAndReturnIfNil(self);
                self->currentAlert = nil;
                [self showAudioDeviceOptions];
                
            }];
            
            [actions addObject:audioDeviceAction];
        }
        
        //  check the call can be up/downgraded
        
        //  check the call can send DTMF tones
        if (self.mxCall.supportsDTMF)
        {
            UIAlertAction *dialpadAction = [UIAlertAction actionWithTitle:[VectorL10n callMoreActionsDialpad]
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                
                MXStrongifyAndReturnIfNil(self);
                self->currentAlert = nil;
                [self openDialpad];
                
            }];
            
            [actions addObject:dialpadAction];
        }
        
        //  check the call be holded/unholded
        if (mxCall.supportsHolding)
        {
            NSString *actionLocKey = (mxCall.state == MXCallStateOnHold) ? [VectorL10n callMoreActionsUnhold] : [VectorL10n callMoreActionsHold];
            
            UIAlertAction *holdAction = [UIAlertAction actionWithTitle:actionLocKey
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                
                MXStrongifyAndReturnIfNil(self);
                self->currentAlert = nil;
                [self->mxCall hold:(self.mxCall.state != MXCallStateOnHold)];
                
            }];
            
            [actions addObject:holdAction];
        }
        
        //  check the call be transferred
        if (mxCall.supportsTransferring && self.peer)
        {
            UIAlertAction *transferAction = [UIAlertAction actionWithTitle:[VectorL10n callMoreActionsTransfer]
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                
                MXStrongifyAndReturnIfNil(self);
                self->currentAlert = nil;
                
                [self openCallTransfer];
            }];
            
            [actions addObject:transferAction];
        }
        
        if (actions.count > 0)
        {
            //  create the alert
            currentAlert = [UIAlertController alertControllerWithTitle:nil
                                                               message:nil
                                                        preferredStyle:UIAlertControllerStyleActionSheet];
            
            //  add actions
            [actions enumerateObjectsUsingBlock:^(UIAlertAction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [currentAlert addAction:obj];
            }];
            
            //  add cancel action always
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                
                MXStrongifyAndReturnIfNil(self);
                self->currentAlert = nil;
                
            }]];
            
            [currentAlert popoverPresentationController].sourceView = self.moreButton;
            [currentAlert popoverPresentationController].sourceRect = self.moreButton.bounds;
            [self presentViewController:currentAlert animated:YES completion:nil];
        }
    }
    else if (sender == speakerButton)
    {
        [self showAudioDeviceOptions];
    }
    else if (sender == cameraSwitchButton)
    {
        switch (mxCall.cameraPosition)
        {
            case AVCaptureDevicePositionFront:
                mxCall.cameraPosition = AVCaptureDevicePositionBack;
                break;
                
            default:
                mxCall.cameraPosition = AVCaptureDevicePositionFront;
                break;
        }
    }
    else if (sender == backToAppButton)
    {
        if (_delegate)
        {
            // Dismiss the view controller whereas the call is still running
            [_delegate dismissCallViewController:self completion:nil];
        }
    }
    else if (sender == _transferButton)
    {
        //  actually transfer the call without consulting
        [self.mainSession.callManager transferCall:mxCall.callWithTransferee
                                                to:mxCall.transferTarget
                                    withTransferee:mxCall.transferee
                                      consultFirst:NO
                                           success:^(NSString * _Nullable newCallId) {
            
        }
                                           failure:^(NSError * _Nullable error) {
            
        }];
    }
    
    [self updateProximityAndSleep];
}

- (void)showAudioDeviceOptions
{
    NSMutableArray<UIAlertAction *> *actions = [NSMutableArray new];
    NSArray<MXiOSAudioOutputRoute *> *availableRoutes = mxCall.audioOutputRouter.availableOutputRoutes;
    
    for (MXiOSAudioOutputRoute *route in availableRoutes)
    {
        //  route action
        NSString *name = route.name;
        if (route.routeType == MXiOSAudioOutputRouteTypeLoudSpeakers)
        {
            name = [VectorL10n callMoreActionsAudioUseDevice];
        }
        MXWeakify(self);
        UIAlertAction *routeAction = [UIAlertAction actionWithTitle:name
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
            
            MXStrongifyAndReturnIfNil(self);
            self->currentAlert = nil;
            [self->mxCall.audioOutputRouter changeCurrentRouteTo:route];
            
        }];
        
        [actions addObject:routeAction];
    }
    
    if (actions.count > 0)
    {
        //  create the alert
        currentAlert = [UIAlertController alertControllerWithTitle:nil
                                                           message:nil
                                                    preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (UIAlertAction *action in actions)
        {
            [currentAlert addAction:action];
        }
        
        //  add cancel action
        MXWeakify(self);
        [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action) {
            
            MXStrongifyAndReturnIfNil(self);
            self->currentAlert = nil;
            
        }]];
        
        [currentAlert popoverPresentationController].sourceView = self.moreButton;
        [currentAlert popoverPresentationController].sourceRect = self.moreButton.bounds;
        [self presentViewController:currentAlert animated:YES completion:nil];
    }
}
    
#pragma mark - DTMF

- (void)openDialpad
{
    //  no-op
}

#pragma mark - Call Transfer

- (void)openCallTransfer
{
    //  no-op
}

#pragma mark - MXCallDelegate

- (void)call:(MXCall *)call stateDidChange:(MXCallState)state reason:(MXEvent *)event
{
    // Set default configuration of bottom bar
    endCallButton.hidden = NO;
    rejectCallButton.hidden = YES;
    answerCallButton.hidden = YES;
    self.moreButton.enabled = YES;
    _resumeButton.hidden = state != MXCallStateOnHold;
    _pausedIcon.hidden = state != MXCallStateOnHold && state != MXCallStateRemotelyOnHold;
    _transferButton.hidden = YES;
    
    [localPreviewActivityView stopAnimating];
    
    switch (state)
    {
        case MXCallStateFledgling:
            self.isRinging = NO;
            callStatusLabel.text = [VectorL10n callConnecting];
            break;
        case MXCallStateWaitLocalMedia:
            self.isRinging = NO;
            [self configureSpeakerButton];
            [localPreviewActivityView startAnimating];
            
            // Try to show a special view for incoming view
            [self configureIncomingCallViewIfRequiredWith:call];
            
            break;
        case MXCallStateCreateOffer:
        {
            // When CallKit is enabled and we have an outgoing call, we need to start playing ringback sound
            // only after AVAudioSession will be activated by the system otherwise the sound will be gone.
            // We always receive signal about MXCallStateCreateOffer earlier than the system activates AVAudioSession
            // so we start playing ringback sound only on AVAudioSession activation in handleAudioSessionActivationNotification
            BOOL isCallKitAvailable = [MXCallKitAdapter callKitAvailable] && [MXKAppSettings standardAppSettings].isCallKitEnabled;
            if (!isCallKitAvailable)
            {
                self.isRinging = YES;
            }
            
            callStatusLabel.text = [VectorL10n callConnecting];
            break;
        }
        case MXCallStateInviteSent:
        {
            callStatusLabel.text = [VectorL10n callRinging];
            break;
        }
        case MXCallStateRinging:
            self.isRinging = YES;
            [self configureSpeakerButton];
            if (call.isVideoCall)
            {
                callStatusLabel.text = [VectorL10n incomingVideoCall];
            }
            else
            {
                callStatusLabel.text = [VectorL10n incomingVoiceCall];
            }
            // Update bottom bar
            endCallButton.hidden = YES;
            rejectCallButton.hidden = NO;
            answerCallButton.hidden = NO;
            
            // Try to show a special view for incoming view
            [self configureIncomingCallViewIfRequiredWith:call];
            
            break;
        case MXCallStateConnecting:
            self.isRinging = NO;
            
            // User has accepted the call and we can remove incomingCallView
            if (self.incomingCallView)
            {
                [UIView transitionWithView:self.view
                                  duration:0.33
                                   options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionCurveEaseOut
                                animations:^{
                                    [self.incomingCallView removeFromSuperview];
                                }
                                completion:^(BOOL finished) {
                                    self.incomingCallView = nil;
                                }];
            }
            
            break;
        case MXCallStateConnected:
            self.isRinging = NO;
            [self updateTimeStatusLabel];

            if (call.isVideoCall)
            {
                self.callerImageView.hidden = YES;
                
                if (call.isConferenceCall)
                {
                    // Do not show self view anymore because it is returned by the conference bridge
                    self.localPreviewContainerView.hidden = YES;

                    // Well, hide does not work. So, shrink the view to nil
                    self.localPreviewContainerView.frame = CGRectZero;
                }
            }
            audioMuteButton.enabled = YES;
            videoMuteButton.enabled = YES;
            speakerButton.enabled = YES;
            cameraSwitchButton.enabled = YES;
            if (call.isConsulting)
            {
                _transferButton.hidden = NO;
            }

            break;
        case MXCallStateOnHold:
            callStatusLabel.text = [VectorL10n callHolded];
            
            break;
        case MXCallStateRemotelyOnHold:
            audioMuteButton.enabled = NO;
            videoMuteButton.enabled = NO;
            speakerButton.enabled = NO;
            cameraSwitchButton.enabled = NO;
            self.moreButton.enabled = NO;
            callStatusLabel.text = [VectorL10n callRemoteHolded:peerDisplayName];
            
            break;
        case MXCallStateInviteExpired:
            // MXCallStateInviteExpired state is sent as an notification
            // MXCall will move quickly to the MXCallStateEnded state
            self.isRinging = NO;
            callStatusLabel.text = [VectorL10n callInviteExpired];
            
            break;
        case MXCallStateEnded:
        {
            self.isRinging = NO;
            callStatusLabel.text = [VectorL10n callEnded];
            
            NSString *soundName = [self soundNameForCallEnding];
            if (soundName)
            {
                NSURL *audioUrl = [self audioURLWithName:soundName];
                [[MXKSoundPlayer sharedInstance] playSoundAt:audioUrl repeat:NO vibrate:NO routeToBuiltInReceiver:YES];
            }
            else
            {
                [[MXKSoundPlayer sharedInstance] stopPlayingWithAudioSessionDeactivation:YES];
            }
            
            // Except in case of call error, quit the screen right now
            if (!errorAlert)
            {
                [self dismiss];
            }

            break;
        }
        default:
            break;
    }
    
    [self updateProximityAndSleep];
}

- (void)call:(MXCall *)call didEncounterError:(NSError *)error reason:(MXCallHangupReason)reason
{
    MXLogDebug(@"[MXKCallViewController] didEncounterError. mxCall.state: %tu. Stop call due to error: %@", mxCall.state, error);

    if (mxCall.state != MXCallStateEnded)
    {
        // Popup the error to the user
        NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
        if (!title)
        {
            title = [VectorL10n error];
        }
        NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
        if (!msg)
        {
            msg = [VectorL10n errorCommonMessage];
        }

        MXWeakify(self);
        errorAlert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [errorAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
            
            MXStrongifyAndReturnIfNil(self);
            self->errorAlert = nil;
            [self dismiss];
            
        }]];
        
        [self presentViewController:errorAlert animated:YES completion:nil];
        
        // And interrupt the call
        [mxCall hangupWithReason:reason];
    }
}

- (void)callConsultingStatusDidChange:(MXCall *)call
{
    [self updatePeerInfoDisplay];
    
    if (call.isConsulting)
    {
        NSString *title = [VectorL10n callTransferToUser:call.transferee.displayname];
        [_transferButton setTitle:title forState:UIControlStateNormal];
        _transferButton.hidden = call.state != MXCallStateConnected;
    }
    else
    {
        _transferButton.hidden = YES;
    }
}

- (void)callAssertedIdentityDidChange:(MXCall *)call
{
    MXAssertedIdentityModel *assertedIdentity = call.assertedIdentity;
    
    if (assertedIdentity)
    {
        //  update caller display name and avatar with the asserted identity
        NSString *peerAvatarURL = assertedIdentity.avatarUrl;
        
        if (assertedIdentity.displayname)
        {
            peerDisplayName = assertedIdentity.displayname;
        }
        else if (assertedIdentity.userId)
        {
            peerDisplayName = assertedIdentity.userId;
        }
        
        if (mxCall.isVideoCall)
        {
            callerNameLabel.text = [VectorL10n callVideoWithUser:peerDisplayName];
        }
        else
        {
            callerNameLabel.text = [VectorL10n callVoiceWithUser:peerDisplayName];
        }
        
        if (peerAvatarURL)
        {
            // Suppose avatar url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
            callerImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder;
            callerImageView.enableInMemoryCache = YES;
            [callerImageView setImageURI:peerAvatarURL
                                withType:nil
                     andImageOrientation:UIImageOrientationUp
                           toFitViewSize:callerImageView.frame.size
                              withMethod:MXThumbnailingMethodCrop
                            previewImage:self.picturePlaceholder
                            mediaManager:self.mainSession.mediaManager];
        }
        else
        {
            callerImageView.image = self.picturePlaceholder;
        }
        
        [updateStatusTimer fire];
    }
    else
    {
        //  go back to the original display name and avatar
        [self updatePeerInfoDisplay];
    }
}

- (void)callAudioOutputRouteTypeDidChange:(MXCall *)call
{
    [self configureSpeakerButton];
}

- (void)callAvailableAudioOutputsDidChange:(MXCall *)call
{
    
}

#pragma mark - Internal

- (void)removeObservers
{
    if (roomDidFlushDataNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:roomDidFlushDataNotificationObserver];
        roomDidFlushDataNotificationObserver = nil;
    }
    
    if (audioSessionRouteChangeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:audioSessionRouteChangeNotificationObserver];
        audioSessionRouteChangeNotificationObserver = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (roomListener && mxCall.room)
    {
        MXWeakify(self);
        [mxCall.room liveTimeline:^(id<MXEventTimeline> liveTimeline) {
            MXStrongifyAndReturnIfNil(self);

            [liveTimeline removeListener:self->roomListener];
            self->roomListener = nil;
        }];
    }
}

- (void)callRoomStateDidChange:(dispatch_block_t)onComplete
{
    // Handle peer here
    if (mxCall.isIncoming)
    {
        self.peer = [mxCall.room.mxSession getOrCreateUser:mxCall.callerId];
        if (onComplete)
        {
            onComplete();
        }
    }
    else
    {
        // For 1:1 call, find the other peer
        // Else, the room information will be used to display information about the call
        if (!mxCall.isConferenceCall)
        {
            MXWeakify(self);
            [mxCall.room state:^(MXRoomState *roomState) {
                MXStrongifyAndReturnIfNil(self);
            
                MXUser *theMember = nil;
                NSArray *members = roomState.members.joinedMembers;
                for (MXUser *member in members)
                {
                    if (![member.userId isEqualToString:self->mxCall.callerId])
                    {
                        theMember = member;
                        break;
                    }
                }

                self.peer = theMember;
                if (onComplete)
                {
                    onComplete();
                }
            }];
        }
        else
        {
            self.peer = nil;
            if (onComplete)
            {
                onComplete();
            }
        }
    }
}

- (BOOL)isBuiltInReceiverAudioOuput
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#endif
    BOOL isBuiltInReceiverUsed = NO;
    
    // Check whether the audio output is the built-in receiver
    AVAudioSessionRouteDescription *audioRoute = [[AVAudioSession sharedInstance] currentRoute];
    if (audioRoute.outputs.count)
    {
        // TODO: handle the case where multiple outputs are returned
        AVAudioSessionPortDescription *audioOutputs = audioRoute.outputs.firstObject;
        isBuiltInReceiverUsed = ([audioOutputs.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]);
    }
    
    return isBuiltInReceiverUsed;
}

- (NSString *)soundNameForCallEnding
{
    if (mxCall.endReason == MXCallEndReasonUnknown)
        return nil;
    
    if (mxCall.isEstablished)
        return @"callend";
    
    if (mxCall.endReason == MXCallEndReasonBusy || (!mxCall.isIncoming && mxCall.endReason == MXCallEndReasonMissed))
        return @"busy";
    
    return nil;
}

- (void)handleAudioSessionActivationNotification
{
    // It's only relevant for outgoing calls which aren't in connected state
    if (self.mxCall.state >= MXCallStateCreateOffer && self.mxCall.state != MXCallStateConnected && self.mxCall.state != MXCallStateEnded)
    {
        self.isRinging = YES;
    }
}

#pragma mark - UI methods

- (void)configureSpeakerButton
{
    switch (mxCall.audioOutputRouter.currentRoute.routeType)
    {
        case MXiOSAudioOutputRouteTypeBuiltIn:
            self.speakerButton.selected = NO;
            break;
        case MXiOSAudioOutputRouteTypeLoudSpeakers:
        case MXiOSAudioOutputRouteTypeExternalWired:
        case MXiOSAudioOutputRouteTypeExternalBluetooth:
        case MXiOSAudioOutputRouteTypeExternalCar:
            self.speakerButton.selected = YES;
            break;
    }
}

- (void)configureIncomingCallViewIfRequiredWith:(MXCall *)call
{
    if (call.isIncoming && !self.incomingCallView)
    {
        UIView *incomingCallView = [self createIncomingCallView];
        if (incomingCallView)
        {
            self.incomingCallView = incomingCallView;
            [self.view addSubview:incomingCallView];
            
            incomingCallView.translatesAutoresizingMaskIntoConstraints = NO;
            [incomingCallView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0].active = YES;
            [incomingCallView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0].active = YES;
            [incomingCallView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:0].active = YES;
            [incomingCallView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0].active = YES;
        }
    }
}

- (void)updateLocalPreviewLayout
{
    // On IOS 8 and later, the screen size is oriented.
    CGRect bounds = [[UIScreen mainScreen] bounds];
    BOOL isLandscapeOriented = (bounds.size.width > bounds.size.height);
    
    CGFloat maxPreviewFrameSize, minPreviewFrameSize;
    
    if (_localPreviewContainerViewWidthConstraint.constant < _localPreviewContainerViewHeightConstraint.constant)
    {
        maxPreviewFrameSize = _localPreviewContainerViewHeightConstraint.constant;
        minPreviewFrameSize = _localPreviewContainerViewWidthConstraint.constant;
    }
    else
    {
        minPreviewFrameSize = _localPreviewContainerViewHeightConstraint.constant;
        maxPreviewFrameSize = _localPreviewContainerViewWidthConstraint.constant;
    }
    
    if (isLandscapeOriented)
    {
        _localPreviewContainerViewHeightConstraint.constant = minPreviewFrameSize;
        _localPreviewContainerViewWidthConstraint.constant = maxPreviewFrameSize;
    }
    else
    {
        _localPreviewContainerViewHeightConstraint.constant = maxPreviewFrameSize;
        _localPreviewContainerViewWidthConstraint.constant = minPreviewFrameSize;
    }
    
    CGPoint previewOrigin = self.localPreviewContainerView.frame.origin;
    
    if (previewOrigin.x != (bounds.size.width - _localPreviewContainerViewWidthConstraint.constant - kLocalPreviewMargin))
    {
        CGFloat posX = (bounds.size.width - _localPreviewContainerViewWidthConstraint.constant - kLocalPreviewMargin);
        _localPreviewContainerViewLeadingConstraint.constant = posX;
    }
    
    if (previewOrigin.y != kLocalPreviewMargin)
    {
        CGFloat posY = (bounds.size.height - _localPreviewContainerViewHeightConstraint.constant - kLocalPreviewMargin);
        _localPreviewContainerViewTopConstraint.constant = posY;
    }
}

- (void)showOverlayContainer:(BOOL)isShown
{
    if (mxCall && !mxCall.isVideoCall) isShown = YES;
    if (mxCall.state != MXCallStateConnected) isShown = YES;
    
    if (isShown)
    {
        overlayContainerView.hidden = NO;
        if (mxCall && mxCall.isVideoCall)
        {
            [hideOverlayTimer invalidate];
            hideOverlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(hideOverlay:) userInfo:nil repeats:NO];
        }
    }
    else
    {
        overlayContainerView.hidden = YES;
    }
}

- (void)toggleOverlay
{
    [self showOverlayContainer:overlayContainerView.isHidden];
}

- (void)hideOverlay:(NSTimer*)theTimer
{
    [self showOverlayContainer:NO];
    hideOverlayTimer = nil;
}

- (void)updateTimeStatusLabel
{
    if (mxCall.state == MXCallStateConnected)
    {
        NSUInteger duration = mxCall.duration / 1000;
        NSUInteger secs = duration % 60;
        NSUInteger mins = (duration - secs) / 60;
        callStatusLabel.text = [NSString stringWithFormat:@"%02tu:%02tu", mins, secs];
    }
}

 - (void)updateProximityAndSleep
 {
     BOOL inCall = (mxCall.state == MXCallStateConnected || mxCall.state == MXCallStateRinging || mxCall.state == MXCallStateInviteSent || mxCall.state == MXCallStateConnecting || mxCall.state == MXCallStateCreateOffer || mxCall.state == MXCallStateCreateAnswer);

     BOOL isBuiltInReceiverUsed = self.isBuiltInReceiverAudioOuput;
     
     // Enable the proximity monitoring when the built in receiver is used as the audio output.
     BOOL enableProxMonitoring = inCall && isBuiltInReceiverUsed;
     
     UIDevice *device = [UIDevice currentDevice];
     if (device && device.isProximityMonitoringEnabled != enableProxMonitoring)
     {
         [device setProximityMonitoringEnabled:enableProxMonitoring];
     }

     // Disable the idle timer during a video call, or during a voice call which is performed with the built-in receiver.
     // Note: if the device is locked, VoIP calling get dropped if an incoming GSM call is received.
     BOOL disableIdleTimer = inCall && (mxCall.isVideoCall || isBuiltInReceiverUsed);
     
     UIApplication *sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
     if (sharedApplication && sharedApplication.isIdleTimerDisabled != disableIdleTimer)
     {
         sharedApplication.idleTimerDisabled = disableIdleTimer;
     }
 }

- (UIView *)createIncomingCallView
{
    return nil;
}

#pragma mark - UIResponder Touch Events

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    if ((!self.localPreviewContainerView.hidden) && CGRectContainsPoint(self.localPreviewContainerView.frame, point))
    {
        // Starting to move the local preview view
        if (mxCallOnHold)
        {
            //  if there is a call on hold, do not move local preview for now
            //  TODO: Instead of wholly avoiding mobility of local preview, just avoid the on hold call's corner here
            return;
        }
        isSelectingLocalPreview = YES;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    isMovingLocalPreview = NO;
    isSelectingLocalPreview = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (isMovingLocalPreview)
    {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self.view];
        
        CGRect bounds = self.view.bounds;
        CGFloat midX = bounds.size.width / 2.0;
        CGFloat midY = bounds.size.height / 2.0;
        
        CGFloat posX = (point.x < midX) ? 20.0 : (bounds.size.width - _localPreviewContainerViewWidthConstraint.constant - 20.0);
        CGFloat posY = (point.y < midY) ? 20.0 : (bounds.size.height - _localPreviewContainerViewHeightConstraint.constant - 20.0);
        
        _localPreviewContainerViewLeadingConstraint.constant = posX;
        _localPreviewContainerViewTopConstraint.constant = posY;
        
        [self.view setNeedsUpdateConstraints];
    }
    else
    {
        [self toggleOverlay];
    }
    isMovingLocalPreview = NO;
    isSelectingLocalPreview = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    
    if (isSelectingLocalPreview)
    {
        isMovingLocalPreview = YES;
        self.localPreviewContainerView.center = point;
    }
}

#pragma mark - UIDeviceOrientationDidChangeNotification

- (void)deviceOrientationDidChange
{
    [self applyDeviceOrientation:NO];
    
    [self showOverlayContainer:YES];
}

- (void)applyDeviceOrientation:(BOOL)forcePortrait
{
    if (mxCall)
    {
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        
        // Set the camera orientation according to the orientation supported by the app
        if (UIDeviceOrientationPortrait == deviceOrientation || UIDeviceOrientationLandscapeLeft == deviceOrientation || UIDeviceOrientationLandscapeRight == deviceOrientation)
        {
            mxCall.selfOrientation = deviceOrientation;
            [self updateLocalPreviewLayout];
        }
        else if (forcePortrait)
        {
            mxCall.selfOrientation = UIDeviceOrientationPortrait;
            [self updateLocalPreviewLayout];
        }        
    }
}

@end
