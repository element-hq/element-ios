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

#import "AppDelegate.h"
#import "Riot-Swift.h"

#import "AvatarGenerator.h"

#import "UsersDevicesViewController.h"

#import "RiotNavigationController.h"

#import "IncomingCallView.h"

@interface CallViewController ()
{
    // Display a gradient view above the screen
    CAGradientLayer* gradientMaskLayer;
    
    // Current alert (if any).
    UIAlertController *currentAlert;
    
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;

    // Flag to compute self.shouldPromptForStunServerFallback
    BOOL promptForStunServerFallback;
}

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
    
    UIColor *unselectedColor = ThemeService.shared.theme.tabBarUnselectedItemTintColor;
    UIColor *selectedColor = ThemeService.shared.theme.tintColor;
    
    // Back button
    
    UIImage *backButtonImage = [[UIImage imageNamed:@"back_icon"] vc_tintedImageUsingColor:selectedColor];
    [self.backToAppButton setImage:backButtonImage forState:UIControlStateNormal];
    [self.backToAppButton setImage:backButtonImage forState:UIControlStateHighlighted];
    
    // Camera switch
    
    UIImage *cameraSwitchButtonImage = [[UIImage imageNamed:@"camera_switch"] vc_tintedImageUsingColor:selectedColor];
    [self.cameraSwitchButton setImage:cameraSwitchButtonImage forState:UIControlStateNormal];
    [self.cameraSwitchButton setImage:cameraSwitchButtonImage forState:UIControlStateHighlighted];
    
    // Audio mute
    
    UIImage *audioMuteOffButtonImage = [[UIImage imageNamed:@"call_audio_mute_off_icon"] vc_tintedImageUsingColor:unselectedColor];
    
    UIImage *audioMuteOnButtonImage = [[UIImage imageNamed:@"call_audio_mute_on_icon"] vc_tintedImageUsingColor:unselectedColor];
    
    [self.audioMuteButton setImage:audioMuteOffButtonImage forState:UIControlStateNormal];
    [self.audioMuteButton setImage:audioMuteOffButtonImage forState:UIControlStateHighlighted];
    [self.audioMuteButton setImage:audioMuteOnButtonImage forState:UIControlStateSelected];
    
    // Video mute
    
    UIImage *videoOffButtonImage = [[UIImage imageNamed:@"call_video_mute_off_icon"] vc_tintedImageUsingColor:unselectedColor];
    UIImage *videoOnButtonImage = [[UIImage imageNamed:@"call_video_mute_on_icon"] vc_tintedImageUsingColor:unselectedColor];
    
    [self.videoMuteButton setImage:videoOffButtonImage forState:UIControlStateNormal];
    [self.videoMuteButton setImage:videoOffButtonImage forState:UIControlStateHighlighted];
    [self.videoMuteButton setImage:videoOnButtonImage forState:UIControlStateSelected];
    
    // Speaker
    
    UIImage *speakerOffButtonImage = [[UIImage imageNamed:@"call_speaker_off_icon"] vc_tintedImageUsingColor:unselectedColor];
    UIImage *speakerOnButtonImage = [[UIImage imageNamed:@"call_speaker_on_icon"] vc_tintedImageUsingColor:unselectedColor];
    [self.speakerButton setImage:speakerOffButtonImage forState:UIControlStateNormal];
    [self.speakerButton setImage:speakerOnButtonImage forState:UIControlStateSelected];
    
    // Chat
    
    UIImage *chatButtonImage = [[UIImage imageNamed:@"call_chat_icon"] vc_tintedImageUsingColor:unselectedColor];
    [self.chatButton setImage:chatButtonImage forState:UIControlStateNormal];
    [self.chatButton setImage:chatButtonImage forState:UIControlStateHighlighted];
    
    // Hang up
    
    UIImage *hangUpButtonImage = [[UIImage imageNamed:@"call_hangup_large"] vc_tintedImageUsingColor:ThemeService.shared.theme.noticeColor];
    
    [self.endCallButton setTitle:nil forState:UIControlStateNormal];
    [self.endCallButton setTitle:nil forState:UIControlStateHighlighted];
    [self.endCallButton setImage:hangUpButtonImage forState:UIControlStateNormal];
    [self.endCallButton setImage:hangUpButtonImage forState:UIControlStateHighlighted];
    
    // Define caller image view size
    CGSize size = [[UIScreen mainScreen] bounds].size;
    CGFloat minSize = MIN(size.width, size.height);
    self.callerImageViewWidthConstraint.constant = minSize / 2;
    
    [self updateLocalPreviewLayout];
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.barTitleColor = ThemeService.shared.theme.textPrimaryColor;
    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.callerNameLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.callStatusLabel.textColor = ThemeService.shared.theme.baseTextSecondaryColor;
    
    self.localPreviewContainerView.layer.borderColor = ThemeService.shared.theme.tintColor.CGColor;
    self.localPreviewContainerView.layer.borderWidth = 2;
    self.localPreviewContainerView.layer.cornerRadius = 5;
    self.localPreviewContainerView.clipsToBounds = YES;
    
    self.remotePreviewContainerView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    if (gradientMaskLayer)
    {
        [gradientMaskLayer removeFromSuperlayer];
    }
    
    // Add a gradient mask programatically at the top of the screen (background of the call information (name, status))
    gradientMaskLayer = [CAGradientLayer layer];
    
    // Consider the grayscale components of the ThemeService.shared.theme.backgroundColor.
    CGFloat white = 1.0;
    [ThemeService.shared.theme.backgroundColor getWhite:&white alpha:nil];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    
    gradientMaskLayer.colors = @[(__bridge id) opaqueWhiteColor, (__bridge id) transparentWhiteColor];
    
    gradientMaskLayer.bounds = CGRectMake(0, 0, self.callContainerView.frame.size.width, self.callContainerView.frame.size.height + 20);
    gradientMaskLayer.anchorPoint = CGPointZero;
    
    // CAConstraint is not supported on IOS.
    // it seems only being supported on Mac OS.
    // so viewDidLayoutSubviews will refresh the layout bounds.
    [self.gradientMaskContainerView.layer addSublayer:gradientMaskLayer];
    
    self.callControlsBackgroundView.backgroundColor = ThemeService.shared.theme.baseColor;
}

- (BOOL)prefersStatusBarHidden
{
    // Hide the status bar on the call view controller.
    return YES;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // sanity check
    if (gradientMaskLayer)
    {
        CGRect currentBounds = gradientMaskLayer.bounds;
        CGRect newBounds = CGRectMake(0, 0, self.callContainerView.frame.size.width, self.callContainerView.frame.size.height + 20);
        
        // check if there is an update
        if (!CGSizeEqualToSize(currentBounds.size, newBounds.size))
        {
            newBounds.origin = CGPointZero;
            gradientMaskLayer.bounds = newBounds;
        }
    }
    
    // The caller image view is circular
    self.callerImageView.layer.cornerRadius = self.callerImageViewWidthConstraint.constant / 2;
    self.callerImageView.clipsToBounds = YES;
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

- (void)dealloc
{
}

#pragma mark - override MXKViewController

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
    
    [gradientMaskLayer removeFromSuperlayer];
    gradientMaskLayer = nil;
}

- (UIView *)createIncomingCallView
{
    NSString *callInfo;
    if (self.mxCall.isVideoCall)
        callInfo = NSLocalizedStringFromTable(@"call_incoming_video", @"Vector", nil);
    else
        callInfo = NSLocalizedStringFromTable(@"call_incoming_voice", @"Vector", nil);
    
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

#pragma mark - MXCallDelegate

- (void)call:(MXCall *)call stateDidChange:(MXCallState)state reason:(MXEvent *)event
{
    [super call:call stateDidChange:state reason:event];

    [self checkStunServerFallbackWithCallState:state];
}

- (void)call:(MXCall *)call didEncounterError:(NSError *)error
{
    if ([error.domain isEqualToString:MXEncryptingErrorDomain]
        && error.code == MXEncryptingErrorUnknownDeviceCode)
    {
        // There are unknown devices, check what the user wants to do
        __weak __typeof(self) weakSelf = self;
        
        MXUsersDevicesMap<MXDeviceInfo*> *unknownDevices = error.userInfo[MXEncryptingErrorUnknownDeviceDevicesKey];
        
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        
        currentAlert = [UIAlertController alertControllerWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_alert_title"]
                                                           message:[NSBundle mxk_localizedStringForKey:@"unknown_devices_alert"]
                                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"unknown_devices_verify"]
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
                                                                       [call hangup];
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
        
        
        [currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:(call.isIncoming ? @"unknown_devices_answer_anyway":@"unknown_devices_call_anyway")]
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           
                                                           if (weakSelf)
                                                           {
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               // Acknowledge the existence of all devices
                                                               [self startActivityIndicator];
                                                               [self.mainSession.crypto setDevicesKnown:unknownDevices complete:^{
                                                                   
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
        [super call:call didEncounterError:error];
    }
}


#pragma mark - Fallback STUN server

- (void)checkStunServerFallbackWithCallState:(MXCallState)callState
{
    // Detect if we should display the prompt to fallback to the STUN server defined
    // in the app plist if the homeserver does not provide STUN or TURN servers.
    // We should if the call ends while we were in connecting state
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
                break;
        }
    }
}


#pragma mark - Properties

- (UIImage*)picturePlaceholder
{
    CGFloat fontSize = floor(self.callerImageViewWidthConstraint.constant * 0.7);
    
    if (self.peer)
    {
        // Use the vector style placeholder
        return [AvatarGenerator generateAvatarForMatrixItem:self.peer.userId withDisplayName:self.peer.displayname size:self.callerImageViewWidthConstraint.constant andFontSize:fontSize];
    }
    else if (self.mxCall.room)
    {
        return [AvatarGenerator generateAvatarForMatrixItem:self.mxCall.room.roomId withDisplayName:self.mxCall.room.summary.displayname size:self.callerImageViewWidthConstraint.constant andFontSize:fontSize];
    }
    
    return [MXKTools paintImage:[UIImage imageNamed:@"placeholder"]
                      withColor:ThemeService.shared.theme.tintColor];
}

- (void)setMxCall:(MXCall *)call
{
    [super setMxCall:call];
    
    self.callerImageView.hidden = self.mxCall.isVideoCall;
}

- (void)updatePeerInfoDisplay
{
    NSString *peerDisplayName;
    NSString *peerAvatarURL;
    
    if (self.peer)
    {
        peerDisplayName = [self.peer displayname];
        if (!peerDisplayName.length)
        {
            peerDisplayName = self.peer.userId;
        }
        peerAvatarURL = self.peer.avatarUrl;
    }
    else if (self.mxCall.isConferenceCall)
    {
        peerDisplayName = self.mxCall.room.summary.displayname;
        peerAvatarURL = self.mxCall.room.summary.avatar;
    }
    
    self.callerNameLabel.text = peerDisplayName;
    
    self.callerImageView.contentMode = UIViewContentModeScaleAspectFill;
    if (peerAvatarURL)
    {
        // Retrieve the avatar in full resolution
        [self.callerImageView setImageURI:peerAvatarURL
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                             previewImage:self.picturePlaceholder
                             mediaManager:self.mainSession.mediaManager];
    }
    else
    {
        self.callerImageView.image = self.picturePlaceholder;
    }
}

- (void)showOverlayContainer:(BOOL)isShown
{
    [super showOverlayContainer:isShown];
    
    self.gradientMaskContainerView.hidden = self.overlayContainerView.isHidden;
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

@end
