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

static const NSString *kJitsiServerUrl = @"https://jitsi.riot.im/";

@interface JitsiViewController ()
{
    NSString *jitsiUrl;

    BOOL video;
}

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

- (BOOL)openWidget:(Widget*)widget withVideo:(BOOL)aVideo
{
    video = aVideo;
    _widget = widget;

    // Extract the jitsi conference id from the widget url
    NSString *confId;
    NSURL *url = [NSURL URLWithString:_widget.url];
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

    // And build from it the url to use in jitsi-meet sdk
    if (confId)
    {
        jitsiUrl = [NSString stringWithFormat:@"%@%@", kJitsiServerUrl, confId];
    }

    if (!jitsiUrl)
    {
        NSLog(@"[JitsiVC] Failed to load widget: %@", widget);
    }

    return (jitsiUrl != nil);
}

- (void)hangup
{
    jitsiUrl = nil;

    // It would have been nicer to ask JitsiMeetView but there is no api.
    // Dismissing the view controller and releasing it does the job for the moment
    if (_delegate)
    {
        [_delegate jitsiViewController:self dismissViewJitsiController:nil];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.jitsiMeetView.delegate = self;

    // Pass the URL to jitsi-meet sdk
    [self.jitsiMeetView loadURLObject: @{
                                         @"url": jitsiUrl,
                                         @"configOverwrite": @{
                                                 @"startWithVideoMuted": @(!video)
                                                 }
                                         }];

    // TODO: Set up user info but it is not yet available in the jitsi-meet iOS SDK
    // See https://github.com/jitsi/jitsi-meet/issues/1880
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction)onBackToAppButtonPressed:(id)sender
{
    if (_delegate)
    {
        [_delegate jitsiViewController:self goBackToApp:nil];
    }
}

#pragma mark - JitsiMeetViewDelegate

- (void)conferenceFailed:(NSDictionary *)data
{
    NSLog(@"[JitsiViewController] conferenceFailed - data: %@", data);
}

- (void)conferenceLeft:(NSDictionary *)data
{
    // The conference is over. Let the delegate close this view controller.
    if (_delegate)
    {
        [_delegate jitsiViewController:self dismissViewJitsiController:nil];
    }
    else
    {
        // Do it ourself
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
