/*
 Copyright 2016 OpenMarket Ltd
 
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
#import "VectorDesignValues.h"

@interface CallViewController ()
{
    // Display a gradient view above the screen
    CAGradientLayer* gradientMaskLayer;
}

@end

@implementation CallViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)callViewController:(MXCall*)call
{
    CallViewController* instance = [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.backToAppButton setImage:[UIImage imageNamed:@"back_icon"] forState:UIControlStateNormal];
    [self.backToAppButton setImage:[UIImage imageNamed:@"back_icon"] forState:UIControlStateHighlighted];
    
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"camera_switch"] forState:UIControlStateNormal];
    [self.cameraSwitchButton setImage:[UIImage imageNamed:@"camera_switch"] forState:UIControlStateHighlighted];
    
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_icon"] forState:UIControlStateNormal];
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_icon"] forState:UIControlStateHighlighted];
    [self.audioMuteButton setImage:[UIImage imageNamed:@"call_audio_mute_icon"] forState:UIControlStateSelected];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_icon"] forState:UIControlStateNormal];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_icon"] forState:UIControlStateHighlighted];
    [self.videoMuteButton setImage:[UIImage imageNamed:@"call_video_mute_icon"] forState:UIControlStateSelected];
    [self.speakerButton setImage:[UIImage imageNamed:@"call_speaker_off_icon"] forState:UIControlStateNormal];
    [self.speakerButton setImage:[UIImage imageNamed:@"call_speaker_on_icon"] forState:UIControlStateSelected];
    [self.chatButton setImage:[UIImage imageNamed:@"call_chat_icon"] forState:UIControlStateNormal];
    [self.chatButton setImage:[UIImage imageNamed:@"call_chat_icon"] forState:UIControlStateHighlighted];
    
    [self.endCallButton setTitle:nil forState:UIControlStateNormal];
    [self.endCallButton setTitle:nil forState:UIControlStateHighlighted];
    [self.endCallButton setImage:[UIImage imageNamed:@"call_hangup_icon"] forState:UIControlStateNormal];
    [self.endCallButton setImage:[UIImage imageNamed:@"call_hangup_icon"] forState:UIControlStateHighlighted];
    
    self.callerNameLabel.textColor = kVectorTextColorBlack;
    self.callStatusLabel.textColor = kVectorTextColorDarkGray;
    
    self.localPreviewContainerView.layer.borderColor = kVectorColorGreen.CGColor;
    self.localPreviewContainerView.layer.borderWidth = 2;
    self.localPreviewContainerView.layer.cornerRadius = 5;
    self.localPreviewContainerView.clipsToBounds = YES;
    
    self.remotePreviewContainerView.backgroundColor = kVectorTextColorBlack;
    
    // Add a gradient mask programatically at the top of the screen (background of the call information (name, status))
    gradientMaskLayer = [CAGradientLayer layer];
    
    CGColorRef opaqueWhiteColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
    CGColorRef transparentWhiteColor = [UIColor colorWithWhite:1.0 alpha:0].CGColor;
    
    gradientMaskLayer.colors = [NSArray arrayWithObjects:(__bridge id)opaqueWhiteColor, (__bridge id)transparentWhiteColor, nil];
    
    gradientMaskLayer.bounds = CGRectMake(0, 0, self.callContainerView.frame.size.width, self.callContainerView.frame.size.height + 20);
    gradientMaskLayer.anchorPoint = CGPointZero;
    
    // CAConstraint is not supported on IOS.
    // it seems only being supported on Mac OS.
    // so viewDidLayoutSubviews will refresh the layout bounds.
    [self.gradientMaskContainerView.layer addSublayer:gradientMaskLayer];
    
    [self updateLocalPreviewLayout];
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
}

- (void)dealloc
{
}

#pragma mark - override MXKViewController

- (void)destroy
{
    [super destroy];
    
    [gradientMaskLayer removeFromSuperlayer];
    gradientMaskLayer = nil;
}

#pragma mark - Properties

- (UIImage*)picturePlaceholder
{
    if (self.peer)
    {
        // Use the vector style placeholder
        return [AvatarGenerator generateRoomMemberAvatar:self.peer.userId displayName:self.peer.displayname];
    }
    else if (self.mxCall.room)
    {
        return [AvatarGenerator generateRoomAvatar:self.mxCall.room.roomId andDisplayName:self.mxCall.room.state.displayname];
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
        peerDisplayName = self.mxCall.room.state.displayname;
        peerAvatarURL = self.mxCall.room.state.avatar;
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
                    [[AppDelegate theDelegate] showRoom:self.mxCall.room.state.roomId andEventId:nil withMatrixSession:self.mxCall.room.mxSession];
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
