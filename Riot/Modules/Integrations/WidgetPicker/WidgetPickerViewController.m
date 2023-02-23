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

#import "WidgetManager.h"
#import "WidgetViewController.h"
#import "IntegrationManagerViewController.h"
#import "GeneratedInterface-Swift.h"

@interface WidgetPickerViewController () <ServiceTermsModalCoordinatorBridgePresenterDelegate>
{
    MXSession *mxSession;
    NSString *roomId;
}

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter;
@property (nonatomic, strong) MXKRoomDataSource *roomDataSource;
@property (nonatomic, strong) Widget *selectedWidget;

@end

@implementation WidgetPickerViewController

- (instancetype)initForMXSession:(MXSession*)theMXSession inRoom:(NSString*)theRoomId
{
    self = [super init];
    if (self)
    {
        mxSession = theMXSession;
        roomId = theRoomId;

        _alertController = [UIAlertController alertControllerWithTitle:[VectorL10n widgetPickerTitle]
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

        NSArray<Widget*> *widgets = [[WidgetManager sharedManager] widgetsNotOfTypes:@[kWidgetTypeJitsiV1, kWidgetTypeJitsiV2]
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
                [mxkViewController vc_removeBackTitle];

                [self fetchWidgetURLAndDisplayUsingWidget:widget canPresentServiceTerms:YES];
            }];
            [self.alertController addAction:alertAction];
        }

        // Link to the integration manager
        if (RiotSettings.shared.roomInfoScreenShowIntegrations)
        {
            alertAction = [UIAlertAction actionWithTitle:[VectorL10n widgetPickerManageIntegrations]
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
        }

        // Cancel
        alertAction = [UIAlertAction actionWithTitle:[VectorL10n cancel]
                                               style:UIAlertActionStyleCancel
                                             handler:nil];
        [self.alertController addAction:alertAction];

        // And show it
        [mxkViewController presentViewController:self.alertController animated:YES completion:nil];
        
        self.presentingViewController = mxkViewController;
    }];
 }

- (void)fetchWidgetURLAndDisplayUsingWidget:(Widget*)widget canPresentServiceTerms:(BOOL)canPresentServiceTerms
{
    [widget widgetUrl:^(NSString * _Nonnull widgetUrl) {
 
        // Display the widget
        
        WidgetViewController *widgetVC = [[WidgetViewController alloc] initWithUrl:widgetUrl forWidget:widget];
        
        widgetVC.roomDataSource = self.roomDataSource;
        
        [self.presentingViewController.navigationController pushViewController:widgetVC animated:YES];
        
    } failure:^(NSError * _Nonnull error) {
        
        MXLogDebug(@"[WidgetPickerVC] Get widget URL failed with error: %@", error);
        
        if (canPresentServiceTerms
            && [error.domain isEqualToString:WidgetManagerErrorDomain]
            && error.code == WidgetManagerErrorCodeTermsNotSigned)
        {
            [self presentTermsForWidget:widget];
        }
        else
        {
            [[AppDelegate theDelegate] showErrorAsAlert:error];
        }
    }];
}

#pragma mark - Service terms

- (void)presentTermsForWidget:(Widget*)widget
{
    if (self.serviceTermsModalCoordinatorBridgePresenter)
    {
        return;
    }
    
    WidgetManagerConfig *config =  [[WidgetManager sharedManager] configForUser:widget.mxSession.myUser.userId];
    
    MXLogDebug(@"[WidgetVC] presentTerms for %@", config.baseUrl);
    
    ServiceTermsModalCoordinatorBridgePresenter *serviceTermsModalCoordinatorBridgePresenter = [[ServiceTermsModalCoordinatorBridgePresenter alloc] initWithSession:widget.mxSession baseUrl:config.baseUrl
                                                                                                                                                        serviceType:MXServiceTypeIntegrationManager
                                                                                                                                                        accessToken:config.scalarToken];
    serviceTermsModalCoordinatorBridgePresenter.delegate = self;
    
    [serviceTermsModalCoordinatorBridgePresenter presentFrom:self.presentingViewController animated:YES];
    self.serviceTermsModalCoordinatorBridgePresenter = serviceTermsModalCoordinatorBridgePresenter;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidAccept:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    MXWeakify(self);
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:^{
        MXStrongifyAndReturnIfNil(self);
        
        if (self.selectedWidget)
        {
            [self fetchWidgetURLAndDisplayUsingWidget:self.selectedWidget canPresentServiceTerms:NO];
        }
    }];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidDecline:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter session:(MXSession * _Nonnull)session
{
    [coordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

- (void)serviceTermsModalCoordinatorBridgePresenterDelegateDidClose:(ServiceTermsModalCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    self.serviceTermsModalCoordinatorBridgePresenter = nil;
}

@end
