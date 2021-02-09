/*
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

#import "JitsiViewController.h"
#import "JitsiWidgetData.h"
#import "Riot-Swift.h"

#if __has_include(<MatrixSDK/MXJingleCallStack.h>)
@import JitsiMeetSDK;

static const NSString *kJitsiDataErrorKey = @"error";

@interface JitsiViewController () <JitsiMeetViewDelegate>

// The jitsi-meet SDK view
@property (nonatomic, weak) IBOutlet JitsiMeetView *jitsiMeetView;

@property (nonatomic, strong) NSString *conferenceId;
@property (nonatomic, strong) NSURL *serverUrl;
@property (nonatomic, strong) NSString *jwtToken;
@property (nonatomic) BOOL startWithVideo;

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
                NSLog(@"[JitsiVC] Failed to load widget: %@. Widget event: %@", widget, widget.widgetEvent);
                
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

        NSLog(@"[JitsiVC] Failed to load widget 2: %@. Widget event: %@", widget, widget.widgetEvent);

        if (failure)
        {
            failure(nil);
        }
    }];
}

- (void)hangup
{
    [self.jitsiMeetView leave];
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

            builder.subject = roomSummary.displayname;
            builder.userInfo = [[JitsiMeetUserInfo alloc] initWithDisplayName:userDisplayName
                                                                     andEmail:nil
                                                                    andAvatar:avatarUrl];
            builder.token = self.jwtToken;
        }];
        
        [self.jitsiMeetView join:jitsiMeetConferenceOptions];
    }
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
    if (data[kJitsiDataErrorKey] != nil)
    {
        NSLog(@"[JitsiViewController] conferenceTerminated - data: %@", data);
    }
    else
    {
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
}

- (void)enterPictureInPicture:(NSDictionary *)data
{
    if (self.delegate)
    {
        [self.delegate jitsiViewController:self goBackToApp:nil];
    }
}

@end

#endif
