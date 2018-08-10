/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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
    
    // Observe kRiotDesignValuesDidChangeThemeNotification to handle user interface theme change.
    id kRiotDesignValuesDidChangeThemeNotificationObserver;
}

@end

@implementation CallViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.backToAppButton setImage:[UIImage imageNamed:@"back_icon"] forState:UIControlStateNormal];
    [self.backToAppButton setImage:[UIImage imageNamed:@"back_icon"] forState:UIControlStateHighlighted];
    
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"camera_switch"] forState:UIControlStateNormal];
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"camera_switch"] forState:UIControlStateHighlighted];
    
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_mute_off_icon"] forState:UIControlStateNormal];
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_mute_off_icon"] forState:UIControlStateHighlighted];
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_mute_on_icon"] forState:UIControlStateSelected];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_mute_off_icon"] forState:UIControlStateNormal];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_mute_off_icon"] forState:UIControlStateHighlighted];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_mute_on_icon"] forState:UIControlStateSelected];
    [self.speakerButton setImage:[UIImage imageNamed:@"call_speaker_off_icon"] forState:UIControlStateNormal];
    [self.speakerButton setImage:[UIImage imageNamed:@"call_speaker_on_icon"] forState:UIControlStateSelected];
    [self.chatButton setImage:[UIImage imageNamed:@"call_chat_icon"] forState:UIControlStateNormal];
    [self.chatButton setImage:[UIImage imageNamed:@"call_chat_icon"] forState:UIControlStateHighlighted];
    
    [self.endCallButton setTitle:nil forState:UIControlStateNormal];
    [self.endCallButton setTitle:nil forState:UIControlStateHighlighted];
    [self.endCallButton setImage:[UIImage imageNamed:@"call_hangup_icon"] forState:UIControlStateNormal];
    [self.endCallButton setImage:[UIImage imageNamed:@"call_hangup_icon"] forState:UIControlStateHighlighted];
    
    // Define caller image view size
    CGSize size = [[UIScreen mainScreen] bounds].size;
    CGFloat minSize = MIN(size.width, size.height);
    self.callerImageViewWidthConstraint.constant = minSize / 2;
    
    [self updateLocalPreviewLayout];
    
    // Observe user interface theme change.
    kRiotDesignValuesDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kRiotDesignValuesDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    self.view.backgroundColor = kRiotPrimaryBgColor;
    self.defaultBarTintColor = kRiotSecondaryBgColor;
    self.barTitleColor = kRiotPrimaryTextColor;
    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.callerNameLabel.textColor = kRiotPrimaryTextColor;
    self.callStatusLabel.textColor = kRiotTopicTextColor;
    
    self.localPreviewContainerView.layer.borderColor = kRiotColorGreen.CGColor;
    self.localPreviewContainerView.layer.borderWidth = 2;
    self.localPreviewContainerView.layer.cornerRadius = 5;
    self.localPreviewContainerView.clipsToBounds = YES;
    
    self.remotePreviewContainerView.backgroundColor = kRiotPrimaryBgColor;
    
    if (gradientMaskLayer)
    {
        [gradientMaskLayer removeFromSuperlayer];
    }
    
    // Add a gradient mask programatically at the top of the screen (background of the call information (name, status))
    gradientMaskLayer = [CAGradientLayer layer];
    
    // Consider the grayscale components of the kRiotPrimaryBgColor.
    CGFloat white = 1.0;
    [kRiotPrimaryBgColor getWhite:&white alpha:nil];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:white alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:white alpha:0].CGColor;
    
    gradientMaskLayer.colors = [NSArray arrayWithObjects:(__bridge id)opaqueWhiteColor, (__bridge id)transparentWhiteColor, nil];
    
    gradientMaskLayer.bounds = CGRectMake(0, 0, self.callContainerView.frame.size.width, self.callContainerView.frame.size.height + 20);
    gradientMaskLayer.anchorPoint = CGPointZero;
    
    // CAConstraint is not supported on IOS.
    // it seems only being supported on Mac OS.
    // so viewDidLayoutSubviews will refresh the layout bounds.
    [self.gradientMaskContainerView.layer addSublayer:gradientMaskLayer];
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
    
    if (kRiotDesignValuesDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kRiotDesignValuesDidChangeThemeNotificationObserver];
        kRiotDesignValuesDidChangeThemeNotificationObserver = nil;
    }
    
    [gradientMaskLayer removeFromSuperlayer];
    gradientMaskLayer = nil;
}

- (UIView *)createIncomingCallView
{
    NSString *avatarThumbURL = [self.mainSession.matrixRestClient urlOfContentThumbnail:self.peer.avatarUrl
                                                                          toFitViewSize:IncomingCallView.callerAvatarSize
                                                                             withMethod:MXThumbnailingMethodCrop];
    
    NSString *callInfo;
    if (self.mxCall.isVideoCall)
        callInfo = NSLocalizedStringFromTable(@"call_incoming_video", @"Vector", nil);
    else
        callInfo = NSLocalizedStringFromTable(@"call_incoming_voice", @"Vector", nil);
    
    IncomingCallView *incomingCallView = [[IncomingCallView alloc] initWithCallerAvatarURL:avatarThumbURL
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
                                                               usersDevicesNavigationController.navigationBar.barTintColor = kRiotPrimaryBgColor;
                                                               NSDictionary<NSString *,id> *titleTextAttributes = usersDevicesNavigationController.navigationBar.titleTextAttributes;
                                                               if (titleTextAttributes)
                                                               {
                                                                   NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithDictionary:titleTextAttributes];
                                                                   textAttributes[NSForegroundColorAttributeName] = kRiotPrimaryTextColor;
                                                                   usersDevicesNavigationController.navigationBar.titleTextAttributes = textAttributes;
                                                               }
                                                               else if (kRiotPrimaryTextColor)
                                                               {
                                                                   usersDevicesNavigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: kRiotPrimaryTextColor};
                                                               }
                                                               
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
    
    return [UIImage imageNamed:@"placeholder"];
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
        NSString *avatarThumbURL = [self.mainSession.matrixRestClient urlOfContent:peerAvatarURL];
        [self.callerImageView setImageURL:avatarThumbURL withType:nil andImageOrientation:UIImageOrientationUp previewImage:self.picturePlaceholder];
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
