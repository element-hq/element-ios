/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKDeviceView.h"

#import "NSBundle+MatrixKit.h"

#import "MXKConstants.h"

#import "MXKSwiftHeader.h"

static NSAttributedString *verticalWhitespace = nil;

@interface MXKDeviceView ()
{
    /**
     The displayed device
     */
    MXDevice *mxDevice;
    
    /**
     The matrix session.
     */
    MXSession *mxSession;
    
    /**
     The current alert
     */
    UIAlertController *currentAlert;
    
    /**
     Current request in progress.
     */
    MXHTTPOperation *mxCurrentOperation;
}
@end

@implementation MXKDeviceView

+ (UINib *)nib
{
    // Check whether a nib file is available
    NSBundle *mainBundle = [NSBundle mxk_bundleForClass:self.class];
    
    NSString *path = [mainBundle pathForResource:NSStringFromClass([self class]) ofType:@"nib"];
    if (path)
    {
        return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:mainBundle];
    }
    return [UINib nibWithNibName:NSStringFromClass([MXKDeviceView class]) bundle:[NSBundle mxk_bundleForClass:[MXKDeviceView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Add tap recognizer to discard the view on bg view tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBgViewTap:)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.bgView addGestureRecognizer:tap];
    
    // Localize string
    [_cancelButton setTitle:[VectorL10n ok] forState:UIControlStateNormal];
    [_cancelButton setTitle:[VectorL10n ok] forState:UIControlStateHighlighted];
    
    [_renameButton setTitle:[VectorL10n rename] forState:UIControlStateNormal];
    [_renameButton setTitle:[VectorL10n rename] forState:UIControlStateHighlighted];
    
    [_deleteButton setTitle:[VectorL10n delete] forState:UIControlStateNormal];
    [_deleteButton setTitle:[VectorL10n delete] forState:UIControlStateHighlighted];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Scroll to the top the text view content
    self.textView.contentOffset = CGPointZero;
}

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    
    _defaultTextColor = [UIColor blackColor];
    
    // Add shadow on added view
    _containerView.layer.cornerRadius = 5;
    _containerView.layer.shadowOffset = CGSizeMake(0, 1);
    _containerView.layer.shadowOpacity = 0.5f;
}

#pragma mark -

- (void)removeFromSuperviewDidUpdate:(BOOL)isUpdated
{
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    if (mxCurrentOperation)
    {
        [mxCurrentOperation cancel];
        mxCurrentOperation = nil;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissDeviceView:didUpdate:)])
    {
        [self.delegate dismissDeviceView:self didUpdate:isUpdated];
    }
    else
    {
        [self removeFromSuperview];
    }
}

- (instancetype)initWithDevice:(MXDevice*)device andMatrixSession:(MXSession*)session
{
    self = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    if (self)
    {
        mxDevice = device;
        mxSession = session;
        
        [self setTranslatesAutoresizingMaskIntoConstraints: NO];
        
        if (mxDevice)
        {
            // Device information
            NSMutableAttributedString *deviceInformationString = [[NSMutableAttributedString alloc]
                                                                  initWithString:[VectorL10n deviceDetailsTitle]
                                                                  attributes:@{NSForegroundColorAttributeName : _defaultTextColor,
                                                                               NSFontAttributeName: [UIFont boldSystemFontOfSize:15]}];
            [deviceInformationString appendAttributedString:[MXKDeviceView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:[VectorL10n deviceDetailsName]
                                                             attributes:@{NSForegroundColorAttributeName : _defaultTextColor,
                                                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:device.displayName.length ? device.displayName : @""
                                                             attributes:@{NSForegroundColorAttributeName : _defaultTextColor,
                                                                          NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[MXKDeviceView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:[VectorL10n deviceDetailsIdentifier]
                                                             attributes:@{NSForegroundColorAttributeName : _defaultTextColor,
                                                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                             initWithString:device.deviceId
                                                             attributes:@{NSForegroundColorAttributeName : _defaultTextColor,
                                                                          NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[MXKDeviceView verticalWhitespace]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:[VectorL10n deviceDetailsLastSeen]
                                                      attributes:@{NSForegroundColorAttributeName : _defaultTextColor,
                                                                   NSFontAttributeName: [UIFont boldSystemFontOfSize:14]}]];
            
            NSDate *lastSeenDate = [NSDate dateWithTimeIntervalSince1970:device.lastSeenTs/1000];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]]];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            
            NSString *lastSeen = [VectorL10n deviceDetailsLastSeenFormat:device.lastSeenIp :[dateFormatter stringFromDate:lastSeenDate]];
            
            [deviceInformationString appendAttributedString:[[NSMutableAttributedString alloc]
                                                      initWithString:lastSeen
                                                      attributes:@{NSForegroundColorAttributeName : _defaultTextColor,
                                                                   NSFontAttributeName: [UIFont systemFontOfSize:14]}]];
            [deviceInformationString appendAttributedString:[MXKDeviceView verticalWhitespace]];
            
            self.textView.attributedText = deviceInformationString;
        }
        else
        {
            _textView.text = nil;
        }
        
        // Hide potential activity indicator
        [_activityIndicator stopAnimating];
    }
    
    return self;
}

- (void)dealloc
{
    mxDevice = nil;
    mxSession = nil;
}

+ (NSAttributedString *)verticalWhitespace
{
    if (verticalWhitespace == nil)
    {
        verticalWhitespace = [[NSAttributedString alloc] initWithString:@"\n\n" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:4]}];
    }
    return verticalWhitespace;
}

#pragma mark - Actions

- (IBAction)onBgViewTap:(UITapGestureRecognizer*)sender
{
    [self removeFromSuperviewDidUpdate:NO];
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == _cancelButton)
    {
        [self removeFromSuperviewDidUpdate:NO];
    }
    else if (sender == _renameButton)
    {
        [self renameDevice];
    }
    else if (sender == _deleteButton)
    {
        [self deleteDevice];
    }
}

#pragma mark -

- (void)renameDevice
{
    if (!self.delegate)
    {
        // Ignore
        MXLogDebug(@"[MXKDeviceView] Rename device failed, delegate is missing");
        return;
    }
    
    // Prompt the user to enter a device name.
    [currentAlert dismissViewControllerAnimated:NO completion:nil];
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n deviceDetailsRenamePromptTitle]
                                                       message:[VectorL10n deviceDetailsRenamePromptMessage] preferredStyle:UIAlertControllerStyleAlert];

    [currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        
        textField.secureTextEntry = NO;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeDefault;
        if (weakSelf)
        {
            typeof(self) self = weakSelf;
            textField.text = self->mxDevice.displayName;
        }
    }];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                
                                                if (weakSelf)
                                                {
                                                    typeof(self) self = weakSelf;
                                                    self->currentAlert = nil;
                                                }
                                                
                                            }]];
    
    [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       if (weakSelf)
                                                       {
                                                           typeof(self) self = weakSelf;
                                                           NSString *text = [self->currentAlert textFields].firstObject.text;
                                                           self->currentAlert = nil;
                                                           
                                                           [self.activityIndicator startAnimating];
                                                           
                                                           self->mxCurrentOperation = [self->mxSession.matrixRestClient setDeviceName:text forDeviceId:self->mxDevice.deviceId success:^{
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   self->mxCurrentOperation = nil;
                                                                   [self.activityIndicator stopAnimating];
                                                                   
                                                                   [self removeFromSuperviewDidUpdate:YES];
                                                               }
                                                               
                                                           } failure:^(NSError *error) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   
                                                                   // Notify MatrixKit user
                                                                   NSString *myUserId = self->mxSession.myUser.userId;
                                                                   [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                                                                   
                                                                   self->mxCurrentOperation = nil;
                                                                   
                                                                   MXLogDebug(@"[MXKDeviceView] Rename device (%@) failed", self->mxDevice.deviceId);
                                                                   
                                                                   [self.activityIndicator stopAnimating];
                                                                   
                                                                   [self removeFromSuperviewDidUpdate:NO];
                                                               }
                                                               
                                                           }];
                                                       }
                                                       
                                                   }]];
    
    [self.delegate deviceView:self presentAlertController:currentAlert];
}

- (void)deleteDevice
{
    if (!self.delegate)
    {
        // Ignore
        MXLogDebug(@"[MXKDeviceView] Delete device failed, delegate is missing");
        return;
    }
    
    // Get an authentication session to prepare device deletion
    [self.activityIndicator startAnimating];
    
    mxCurrentOperation = [mxSession.matrixRestClient getSessionToDeleteDeviceByDeviceId:mxDevice.deviceId success:^(MXAuthenticationSession *authSession) {
        
        self->mxCurrentOperation = nil;

        // Check whether the password based type is supported
        BOOL isPasswordBasedTypeSupported = NO;
        for (MXLoginFlow *loginFlow in authSession.flows)
        {
            if ([loginFlow.type isEqualToString:kMXLoginFlowTypePassword] || [loginFlow.stages indexOfObject:kMXLoginFlowTypePassword] != NSNotFound)
            {
                isPasswordBasedTypeSupported = YES;
                break;
            }
        }
        
        if (isPasswordBasedTypeSupported && authSession.session)
        {
            // Prompt for a password
            [self->currentAlert dismissViewControllerAnimated:NO completion:nil];
            
            __weak typeof(self) weakSelf = self;
            
            // Prompt the user before deleting the device.
            self->currentAlert = [UIAlertController alertControllerWithTitle:[VectorL10n deviceDetailsDeletePromptTitle] message:[VectorL10n deviceDetailsDeletePromptMessage] preferredStyle:UIAlertControllerStyleAlert];
            
            
            [self->currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                
                textField.secureTextEntry = YES;
                textField.placeholder = nil;
                textField.keyboardType = UIKeyboardTypeDefault;
            }];
            
            [self->currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   self->currentAlert = nil;
                                                                   [self.activityIndicator stopAnimating];
                                                               }
                                                               
                                                           }]];
            
            [self->currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n submit]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;
                                                                   UITextField *textField = [self->currentAlert textFields].firstObject;
                                                                   self->currentAlert = nil;
                                                                   
                                                                   NSString *userId = self->mxSession.myUser.userId;
                                                                   NSDictionary *authParams;
                                                                   
                                                                   // Sanity check
                                                                   if (userId)
                                                                   {
                                                                       authParams = @{@"session":authSession.session,
                                                                                      @"user": userId,
                                                                                      @"password": textField.text,
                                                                                      @"type": kMXLoginFlowTypePassword};
                                                                       
                                                                   }
                                                                   
                                                                   self->mxCurrentOperation = [self->mxSession.matrixRestClient deleteDeviceByDeviceId:self->mxDevice.deviceId authParams:authParams success:^{
                                                                       
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           
                                                                           self->mxCurrentOperation = nil;
                                                                           [self.activityIndicator stopAnimating];
                                                                           
                                                                           [self removeFromSuperviewDidUpdate:YES];
                                                                       }
                                                                       
                                                                   } failure:^(NSError *error) {
                                                    
                                                                       if (weakSelf)
                                                                       {
                                                                           typeof(self) self = weakSelf;
                                                                           
                                                                           // Notify MatrixKit user
                                                                           NSString *myUserId = self->mxSession.myUser.userId;
                                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                                                                           
                                                                           self->mxCurrentOperation = nil;
                                                                           
                                                                           MXLogDebug(@"[MXKDeviceView] Delete device (%@) failed", self->mxDevice.deviceId);
                                                                           
                                                                           [self.activityIndicator stopAnimating];
                                                                           
                                                                           [self removeFromSuperviewDidUpdate:NO];
                                                                       }
                                                                       
                                                                   }];
                                                               }
                                                               
                                                           }]];
            
            [self.delegate deviceView:self presentAlertController:self->currentAlert];
        }
        else
        {
            MXLogDebug(@"[MXKDeviceView] Delete device (%@) failed, auth session flow type is not supported", self->mxDevice.deviceId);
            [self.activityIndicator stopAnimating];
        }
        
    } failure:^(NSError *error) {
        
        self->mxCurrentOperation = nil;
        
        MXLogDebug(@"[MXKDeviceView] Delete device (%@) failed, unable to get auth session", self->mxDevice.deviceId);
        [self.activityIndicator stopAnimating];
        
        // Notify MatrixKit user
        NSString *myUserId = self->mxSession.myUser.userId;
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
    }];
}

@end
