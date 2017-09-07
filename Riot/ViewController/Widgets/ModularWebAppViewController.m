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

#import "ModularWebAppViewController.h"

#import "WidgetManager.h"

@interface ModularWebAppViewController ()
{
    MXSession *mxSession;
    NSString *roomId;
    NSString *screen;
    NSString *widgetId;
    NSString *scalarToken;

    MXHTTPOperation *operation;
}

@end

@implementation ModularWebAppViewController

- (instancetype)initForMXSession:(MXSession *)theMXSession inRoom:(NSString *)theRoomId screen:(NSString *)theScreen widgetId:(NSString *)theWidgetId
{
    self = [super init];
    if (self)
    {
        mxSession = theMXSession;
        roomId = theRoomId;
        screen = theScreen;
        widgetId = theWidgetId;
    }
    return self;
}

- (void)destroy
{
    [super destroy];

    [operation cancel];
    operation = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    webView.scalesPageToFit = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!self.URL && !operation)
    {
        __weak __typeof__(self) weakSelf = self;

        [self startActivityIndicator];

        operation = [[WidgetManager sharedManager] getScalarTokenForMXSession:mxSession success:^(NSString *theScalarToken) {

            typeof(self) self = weakSelf;

            if (self)
            {
                self->operation = nil;
                [self stopActivityIndicator];

                scalarToken = theScalarToken;

                self.URL = [self interfaceUrl];
            }

        } failure:^(NSError *error) {

            typeof(self) self = weakSelf;
            
            if (self)
            {
                self->operation = nil;
                [self stopActivityIndicator];
            }
        }];
    }
}

#pragma mark - Private methods

/**
 Get the URL to use in the Modular interface webapp.
 */
- (NSString *)interfaceUrl
{
    NSMutableString *url;

    if (scalarToken)
    {
        url = [NSMutableString stringWithFormat:@"%@?scalar_token=%@&room_id=%@",
               [[NSUserDefaults standardUserDefaults] objectForKey:@"integrationsUiUrl"],
               [scalarToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
               [roomId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
               ];

        if (screen)
        {
            [url appendString:@"&screen="];
            [url appendString:[screen stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }

        if (widgetId)
        {
            [url appendString:@"&integ_id="];
            [url appendString:[widgetId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    return url;
}

@end
