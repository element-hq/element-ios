/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "JitsiViewController.h"
#import "JitsiWidgetData.h"
#import "GeneratedInterface-Swift.h"

#if __has_include(<MatrixSDK/MXJingleCallStack.h>)
@import JitsiMeetSDK;

static const NSString *kJitsiDataErrorKey = @"error";
/**
 Class name for RCTSafeAreaView. It's in the React Native SDK, so we cannot import its header.
 */
static NSString * _Nonnull kRCTSafeAreaViewClassName = @"RCTSafeAreaView";
/**
 Class name for RCTTextView. It's in the React Native SDK, so we cannot import its header.
 */
static NSString * _Nonnull kRCTTextViewClassName = @"RCTTextView";

/*
 Some feature flags defined in https://github.com/jitsi/jitsi-meet/blob/master/react/features/base/flags/constants.js
 */
static NSString * _Nonnull kJitsiFeatureFlagChatEnabled = @"chat.enabled";
static NSString * _Nonnull kJitsiFeatureFlagScreenSharingEnabled = @"ios.screensharing.enabled";

@interface JitsiViewController () <PictureInPicturable, JitsiMeetViewDelegate>

// The jitsi-meet SDK view
@property (nonatomic, weak) IBOutlet JitsiMeetView *jitsiMeetView;

@property (nonatomic, strong) NSString *conferenceId;
@property (nonatomic, strong) NSURL *serverUrl;
@property (nonatomic, strong) NSString *jwtToken;
@property (nonatomic) BOOL startWithVideo;

/**
 Overlay views in self.jitsiMeetView. Only provided if the screen is in the PiP mode.
 */
@property (nonatomic, strong) NSArray<UIView*> *overlayViews;

@end

@implementation JitsiViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass(self.class)
                          bundle:[NSBundle bundleForClass:self.class]];
}

+ (instancetype)jitsiViewController
{
    JitsiViewController *jitsiViewController = [[[self class] alloc] initWithNibName:NSStringFromClass(self.class)
                                          bundle:[NSBundle bundleForClass:self.class]];
    return jitsiViewController;
}

#pragma mark - Life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.jitsiMeetView.delegate = self;
    
    [self joinConference];
}

- (BOOL)prefersStatusBarHidden
{    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Public

- (void)openWidget:(Widget*)widget withVideo:(BOOL)aVideo
           success:(void (^)(void))success
           failure:(void (^)(NSError *error))failure
{
    self.startWithVideo = aVideo;
    _widget = widget;
    
    MXWeakify(self);

    [_widget widgetUrl:^(NSString * _Nonnull widgetUrl) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // Use widget data from Matrix Widget API v2 first
        JitsiWidgetData *jitsiWidgetData = [JitsiWidgetData modelFromJSON:widget.data];
        
        [self fillWithWidgetData:jitsiWidgetData];
        
        JitsiService *jitsiService = JitsiService.shared;
        
        void (^verifyConferenceId)(void) = ^() {
            if (!self.conferenceId)
            {
                // Else try v1
                [self extractWidgetDataFromUrlString:widgetUrl];
            }
            
            if (self.conferenceId)
            {
                if (success)
                {
                    success();
                }
            }
            else
            {
                MXLogDebug(@"[JitsiVC] Failed to load widget: %@. Widget event: %@", widget, widget.widgetEvent);
                
                if (failure)
                {
                    failure(nil);
                }
            }
        };
        
        // Check if the widget requires authentication
        if ([jitsiService isOpenIdJWTAuthenticationRequiredFor:jitsiWidgetData])
        {
            NSString *roomId = self.widget.roomId;
            MXSession *session = self.widget.mxSession;
            
            MXWeakify(self);
            
            // Retrieve the OpenID token and generate the JWT token
            [jitsiService getOpenIdJWTTokenWithJitsiServerDomain:jitsiWidgetData.domain
                                                          roomId:roomId matrixSession:session success:^(NSString * _Nonnull jwtToken) {
                MXStrongifyAndReturnIfNil(self);
                
                self.jwtToken = jwtToken;
                verifyConferenceId();
            } failure:^(NSError * _Nonnull error) {
                if (failure)
                {
                    failure(error);
                }
            }];
        }
        else
        {
            verifyConferenceId();
        }
    } failure:^(NSError * _Nonnull error) {

        MXLogDebug(@"[JitsiVC] Failed to load widget 2: %@. Widget event: %@", widget, widget.widgetEvent);

        if (failure)
        {
            failure(nil);
        }
    }];
}

- (void)setAudioMuted:(BOOL)muted
{
    [self.jitsiMeetView setAudioMuted:muted];
}

- (void)hangup
{
    [self.jitsiMeetView leave];
}

- (NSUInteger)callDuration
{
    MXEvent *widgetEvent = self.widget.widgetEvent;
    if (widgetEvent)
    {
        if (widgetEvent.originServerTs == kMXUndefinedTimestamp)
        {
            return 0;
        }
        else
        {
            return (uint64_t)[NSDate date].timeIntervalSince1970*1000 - widgetEvent.originServerTs;
        }
    }
    return 0;
}

#pragma mark - Private

// Fill Jitsi data based on Matrix Widget V2 widget data
- (void)fillWithWidgetData:(JitsiWidgetData*)jitsiWidgetData
{
    if (jitsiWidgetData)
    {
        self.conferenceId = jitsiWidgetData.conferenceId;
        if (jitsiWidgetData.domain)
        {
            NSString *serverUrlString = [NSString stringWithFormat:@"https://%@", jitsiWidgetData.domain];
            self.serverUrl = [NSURL URLWithString:serverUrlString];
        }
        self.startWithVideo = !jitsiWidgetData.isAudioOnly;
    }
}

// Extract data based on Matrix Widget V1 URL
- (void)extractWidgetDataFromUrlString:(NSString*)widgetUrlString
{
    // Extract the jitsi conference id from the widget url
    NSString *confId;
    NSURL *url = [NSURL URLWithString:widgetUrlString];
    if (url)
    {
        NSURLComponents *components = [[NSURLComponents new] initWithURL:url resolvingAgainstBaseURL:NO];
        NSArray *queryItems = [components queryItems];
        
        for (NSURLQueryItem *item in queryItems)
        {
            if ([item.name isEqualToString:@"confId"])
            {
                confId = item.value;
                break;
            }
        }
    }
    
    self.conferenceId = confId;
}

- (void)joinConference
{
    [self joinConferenceWithId:self.conferenceId andServerUrl:self.serverUrl];
}

- (void)joinConferenceWithId:(NSString*)conferenceId andServerUrl:(NSURL*)serverUrl
{
    if (conferenceId)
    {
        // Get info about the room and our user
        MXSession *session = self.widget.mxSession;
        MXRoomSummary *roomSummary = [session roomSummaryWithRoomId:self.widget.roomId];

        MXRoom *room = [session roomWithRoomId:self.widget.roomId];
        MXRoomMember *roomMember = [room.dangerousSyncState.members memberWithUserId:session.myUser.userId];

        NSString *userDisplayName = roomMember.displayname;
        NSString *avatar = [session.mediaManager urlOfContent:roomMember.avatarUrl];
        NSURL *avatarUrl = [NSURL URLWithString:avatar];

        JitsiMeetConferenceOptions *jitsiMeetConferenceOptions = [JitsiMeetConferenceOptions fromBuilder:^(JitsiMeetConferenceOptionsBuilder * _Nonnull builder) {

            if (serverUrl)
            {
                builder.serverURL = serverUrl;
            }
            builder.room = conferenceId;
            builder.videoMuted = !self.startWithVideo;

            builder.subject = roomSummary.displayName;
            builder.userInfo = [[JitsiMeetUserInfo alloc] initWithDisplayName:userDisplayName
                                                                     andEmail:nil
                                                                    andAvatar:avatarUrl];
            builder.token = self.jwtToken;
            [builder setFeatureFlag:kJitsiFeatureFlagChatEnabled withBoolean:NO];
            [builder setFeatureFlag:kJitsiFeatureFlagScreenSharingEnabled withBoolean: YES];
        }];
        
        [self.jitsiMeetView join:jitsiMeetConferenceOptions];
    }
}

/**
 Finds all the views in self.jitsiMeetView recursively those kind of class with the name `kRCTSafeAreaViewClassName` or `kRCTTextViewClassName`.
 */
- (NSArray<UIView*>*)overlayViewsIn:(UIView *)view
{
    Class class1 = NSClassFromString(kRCTSafeAreaViewClassName);
    Class class2 = NSClassFromString(kRCTTextViewClassName);
    if ([view isKindOfClass:class1] || [view isKindOfClass:class2])
    {
        return @[view];
    }
    
    NSMutableArray<UIView *> *result = [NSMutableArray arrayWithCapacity:2];
    
    [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObjectsFromArray:[self overlayViewsIn:subview]];
    }];
    
    return result;
}

#pragma mark - JitsiMeetViewDelegate

- (void)conferenceWillJoin:(NSDictionary *)data
{
    // Nothing to do
}

- (void)conferenceJoined:(NSDictionary *)data
{
    // Nothing to do
}

- (void)conferenceTerminated:(NSDictionary *)data
{
    // If the call is terminated by a moderator the error key contains the "conference.destroyed" value
    if (data[kJitsiDataErrorKey] != nil)
    {
        MXLogDebug(@"[JitsiViewController] conferenceTerminated - data: %@", data);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // The conference is over. Let the delegate close this view controller.
        if (self.delegate)
        {
            [self.delegate jitsiViewController:self dismissViewJitsiController:nil];
        }
        else
        {
            // Do it ourself
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

- (void)enterPictureInPicture:(NSDictionary *)data
{
    if (self.delegate)
    {
        [self.delegate jitsiViewController:self goBackToApp:nil];
    }
}

#pragma mark - PictureInPicturable

- (void)didEnterPiP
{
    self.overlayViews = [self overlayViewsIn:self.view];
    for (UIView *view in self.overlayViews)
    {
        view.alpha = 0;
    }
}

- (void)didExitPiP
{
    for (UIView *view in self.overlayViews)
    {
        view.alpha = 1.0;
    }
    self.overlayViews = nil;
}

@end

#endif
