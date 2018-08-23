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

#import "WidgetPickerViewController.h"

#import "AppDelegate.h"

#import "WidgetManager.h"
#import "WidgetViewController.h"
#import "IntegrationManagerViewController.h"

@interface WidgetPickerViewController ()
{
    MXSession *mxSession;
    NSString *roomId;
}

@end

@implementation WidgetPickerViewController

- (instancetype)initForMXSession:(MXSession*)theMXSession inRoom:(NSString*)theRoomId
{
    self = [super init];
    if (self)
    {
        mxSession = theMXSession;
        roomId = theRoomId;

        _alertController = [UIAlertController alertControllerWithTitle:@"Matrix Apps"
                                                               message:nil
                                                        preferredStyle:UIAlertControllerStyleAlert];
    }
    return self;
}

- (void)showInViewController:(MXKViewController *)mxkViewController
{
    MXKRoomDataSourceManager *roomDataSourceManager = [MXKRoomDataSourceManager sharedManagerForMatrixSession:mxSession];
    [roomDataSourceManager roomDataSourceForRoom:roomId create:NO onComplete:^(MXKRoomDataSource *roomDataSource) {

        UIAlertAction *alertAction;

        NSArray<Widget*> *widgets = [[WidgetManager sharedManager] widgetsNotOfTypes:@[kWidgetTypeJitsi]
                                                                              inRoom:roomDataSource.room
                                                                       withRoomState:roomDataSource.roomState];

        // List widgets
        for (Widget *widget in widgets)
        {
            alertAction = [UIAlertAction actionWithTitle:widget.name ? widget.name : widget.type
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * _Nonnull action)
                           {
                               // Hide back button title
                               mxkViewController.navigationItem.backBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

                               // Display the widget
                               [widget widgetUrl:^(NSString * _Nonnull widgetUrl) {

                                   WidgetViewController *widgetVC = [[WidgetViewController alloc] initWithUrl:widgetUrl forWidget:widget];

                                   widgetVC.roomDataSource = roomDataSource;

                                   [mxkViewController.navigationController pushViewController:widgetVC animated:YES];

                               } failure:^(NSError * _Nonnull error) {

                                   NSLog(@"[WidgetPickerVC] Cannot display widget %@", widget);
                                   [[AppDelegate theDelegate] showErrorAsAlert:error];
                               }];
                           }];
            [self.alertController addAction:alertAction];
        }

        // Link to the integration manager
        alertAction = [UIAlertAction actionWithTitle:@"Manage integrations..."
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * _Nonnull action)
                       {
                           IntegrationManagerViewController *modularVC = [[IntegrationManagerViewController alloc] initForMXSession:self->mxSession
                                                                                                                             inRoom:self->roomId
                                                                                                                             screen:kIntegrationManagerMainScreen
                                                                                                                           widgetId:nil];

                           [mxkViewController presentViewController:modularVC animated:NO completion:nil];
                       }];
        [self.alertController addAction:alertAction];

        // Cancel
        alertAction = [UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                               style:UIAlertActionStyleCancel
                                             handler:nil];
        [self.alertController addAction:alertAction];

        // And show it
        [mxkViewController presentViewController:_alertController animated:YES completion:nil];
    }];
 }

@end
