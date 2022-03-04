/*
 Copyright 2015 OpenMarket Ltd
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

#import "MXKAccountDetailsViewController.h"

@import MatrixSDK;
#import "MXK3PID.h"

#import "MXKTools.h"

#import "MXKTableViewCellWithButton.h"
#import "MXKTableViewCellWithTextFieldAndButton.h"
#import "MXKTableViewCellWithLabelTextFieldAndButton.h"
#import "MXKTableViewCellWithTextView.h"
#import "MXKTableViewCellWithLabelAndSwitch.h"

#import "NSBundle+MatrixKit.h"

#import "MXKConstants.h"

#import "MXKSwiftHeader.h"

NSString* const kMXKAccountDetailsLinkedEmailCellId = @"kMXKAccountDetailsLinkedEmailCellId";

@interface MXKAccountDetailsViewController ()
{
    NSMutableArray *alertsArray;
    
    // User's profile
    MXMediaLoader *imageLoader;
    NSString *currentDisplayName;
    NSString *currentPictureURL;
    NSString *currentDownloadId;
    NSString *uploadedPictureURL;
    // Local changes
    BOOL isAvatarUpdated;
    BOOL isSavingInProgress;
    blockMXKAccountDetailsViewController_onReadyToLeave onReadyToLeaveHandler;
    
    // account user's profile observer
    id accountUserInfoObserver;

    // Dynamic rows in the Linked emails section
    NSInteger submittedEmailRowIndex;
    
    // Notifications
    // Dynamic rows in the Notifications section
    NSInteger enablePushNotifRowIndex;
    NSInteger enableInAppNotifRowIndex;
    
    UIImagePickerController *mediaPicker;
}

@end

@implementation MXKAccountDetailsViewController
@synthesize userPictureButton, userDisplayName, saveUserInfoButton;
@synthesize profileActivityIndicator, profileActivityIndicatorBgView;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKAccountDetailsViewController class])
                          bundle:[NSBundle bundleForClass:[MXKAccountDetailsViewController class]]];
}

+ (instancetype)accountDetailsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKAccountDetailsViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKAccountDetailsViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    alertsArray = [NSMutableArray array];
    
    isAvatarUpdated = NO;
    isSavingInProgress = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!userPictureButton)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    self.userPictureButton.backgroundColor = [UIColor clearColor];
    [self updateUserPictureButton:self.picturePlaceholder];
    
    [userPictureButton.layer setCornerRadius:userPictureButton.frame.size.width / 2];
    userPictureButton.clipsToBounds = YES;
    
    [saveUserInfoButton setTitle:[VectorL10n accountSaveChanges] forState:UIControlStateNormal];
    [saveUserInfoButton setTitle:[VectorL10n accountSaveChanges] forState:UIControlStateHighlighted];
    
    // Force refresh
    self.mxAccount = _mxAccount;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    if (imageLoader)
    {
        [imageLoader cancel];
        imageLoader = nil;
    }
}

- (void)dealloc
{
    alertsArray = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAPNSStatusUpdate) name:kMXKAccountAPNSActivityDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopProfileActivityIndicator];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKAccountAPNSActivityDidChangeNotification object:nil];
}

#pragma mark - override

- (void)onMatrixSessionChange
{
    [super onMatrixSessionChange];
    
    if (self.mainSession.state != MXSessionStateRunning)
    {
        userPictureButton.enabled = NO;
        userDisplayName.enabled = NO;
    }
    else if (!isSavingInProgress)
    {
        userPictureButton.enabled = YES;
        userDisplayName.enabled = YES;
    }
}

#pragma mark -

- (void)setMxAccount:(MXKAccount *)account
{
    // Remove observer and existing data
    [self reset];
    
    _mxAccount = account;
    
    if (account)
    {
        // Report matrix account session
        [self addMatrixSession:account.mxSession];
        
        // Set current user's information and add observers
        [self updateUserPicture:_mxAccount.userAvatarUrl force:YES];
        currentDisplayName = _mxAccount.userDisplayName;
        self.userDisplayName.text = currentDisplayName;
        [self updateSaveUserInfoButtonStatus];

        // Load linked emails
        [self loadLinkedEmails];

        // Add observer on user's information
        accountUserInfoObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKAccountUserInfoDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            // Ignore any refresh when saving is in progress
            if (self->isSavingInProgress)
            {
                return;
            }
            
            NSString *accountUserId = notif.object;
            
            if ([accountUserId isEqualToString:self->_mxAccount.mxCredentials.userId])
            {   
                // Update displayName
                if (![self->currentDisplayName isEqualToString:self->_mxAccount.userDisplayName])
                {
                    self->currentDisplayName = self->_mxAccount.userDisplayName;
                    self.userDisplayName.text = self->_mxAccount.userDisplayName;
                }
                // Update user's avatar
                [self updateUserPicture:self->_mxAccount.userAvatarUrl force:NO];
                
                // Update button management
                [self updateSaveUserInfoButtonStatus];
                
                // Display user's presence
                UIColor *presenceColor = [MXKAccount presenceColor:self->_mxAccount.userPresence];
                if (presenceColor)
                {
                    self->userPictureButton.layer.borderWidth = 2;
                    self->userPictureButton.layer.borderColor = presenceColor.CGColor;
                }
                else
                {
                    self->userPictureButton.layer.borderWidth = 0;
                }
            }
        }];
    }
    
    [self.tableView reloadData];
}

- (UIImage*)picturePlaceholder
{
    return [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"default-profile"];
}

- (BOOL)shouldLeave:(blockMXKAccountDetailsViewController_onReadyToLeave)handler
{
    // Check whether some local changes have not been saved
    if (saveUserInfoButton.enabled)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[VectorL10n messageUnsavedChanges] preferredStyle:UIAlertControllerStyleAlert];
            
            [self->alertsArray addObject:alert];
            [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n discard]
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        
                                                        [self->alertsArray removeObject:alert];
                                                        
                                                        // Discard changes
                                                        self.userDisplayName.text = self->currentDisplayName;
                                                        [self updateUserPicture:self->_mxAccount.userAvatarUrl force:YES];
                                                        
                                                        // Ready to leave
                                                        if (handler)
                                                        {
                                                            handler();
                                                        }
                                                        
                                                    }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n save]
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        
                                                        [self->alertsArray removeObject:alert];
                                                        
                                                        // Start saving (Report handler to leave at the end).
                                                        self->onReadyToLeaveHandler = handler;
                                                        [self saveUserInfo];
                                                        
                                                    }]];
            
            [self presentViewController:alert animated:YES completion:nil];
        });
        
        return NO;
    }
    else if (isSavingInProgress)
    {
        // Report handler to leave at the end of saving
        onReadyToLeaveHandler = handler;
        return NO;
    }
    return YES;
}

#pragma mark - Internal methods

- (void)startProfileActivityIndicator
{
    if (profileActivityIndicatorBgView.hidden)
    {
        profileActivityIndicatorBgView.hidden = NO;
        [profileActivityIndicator startAnimating];
    }
    userPictureButton.enabled = NO;
    userDisplayName.enabled = NO;
    saveUserInfoButton.enabled = NO;
}

- (void)stopProfileActivityIndicator
{
    if (!isSavingInProgress)
    {
        if (!profileActivityIndicatorBgView.hidden)
        {
            profileActivityIndicatorBgView.hidden = YES;
            [profileActivityIndicator stopAnimating];
        }
        userPictureButton.enabled = YES;
        userDisplayName.enabled = YES;
        [self updateSaveUserInfoButtonStatus];
    }
}

- (void)reset
{
    [self dismissMediaPicker];
    
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Cancel picture loader (if any)
    if (imageLoader)
    {
        [imageLoader cancel];
        imageLoader = nil;
    }
    
    // Cancel potential alerts
    for (UIAlertController *alert in alertsArray)
    {
        [alert dismissViewControllerAnimated:NO completion:nil];
    }
    
    // Remove listener
    if (accountUserInfoObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:accountUserInfoObserver];
        accountUserInfoObserver = nil;
    }
    
    currentPictureURL = nil;
    currentDownloadId = nil;
    uploadedPictureURL = nil;
    isAvatarUpdated = NO;
    [self updateUserPictureButton:self.picturePlaceholder];
    
    currentDisplayName = nil;
    self.userDisplayName.text = nil;
    
    saveUserInfoButton.enabled = NO;
    
    submittedEmail = nil;
    emailSubmitButton = nil;
    emailTextField = nil;
    
    [self removeMatrixSession:self.mainSession];
    
    logoutButton = nil;
    
    onReadyToLeaveHandler = nil;
}

- (void)destroy
{
    if (isSavingInProgress)
    {
        __weak typeof(self) weakSelf = self;
        onReadyToLeaveHandler = ^()
        {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf destroy];
        };
    }
    else
    {
        // Reset account to dispose all resources (Discard here potentials changes)
        self.mxAccount = nil;
        
        if (imageLoader)
        {
            [imageLoader cancel];
            imageLoader = nil;
        }
        
        // Remove listener
        if (accountUserInfoObserver)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:accountUserInfoObserver];
            accountUserInfoObserver = nil;
        }
        
        [super destroy];
    }
}

- (void)saveUserInfo
{
    [self startProfileActivityIndicator];
    isSavingInProgress = YES;
    
    // Check whether the display name has been changed
    NSString *displayname = self.userDisplayName.text;
    if ((displayname.length || currentDisplayName.length) && [displayname isEqualToString:currentDisplayName] == NO)
    {
        // Save display name
        __weak typeof(self) weakSelf = self;
        
        [_mxAccount setUserDisplayName:displayname success:^{
            
            if (weakSelf)
            {
                // Update the current displayname
                typeof(self) self = weakSelf;
                self->currentDisplayName = displayname;
                
                // Go to the next change saving step
                [self saveUserInfo];
            }
            
        } failure:^(NSError *error) {
            
            MXLogDebug(@"[MXKAccountDetailsVC] Failed to set displayName");
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                
                // Alert user
                NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
                if (!title)
                {
                    title = [VectorL10n accountErrorDisplayNameChangeFailed];
                }
                NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
                
                [self->alertsArray addObject:alert];
                
                [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n abort]
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            
                                                            [self->alertsArray removeObject:alert];
                                                            // Discard changes
                                                            self.userDisplayName.text = self->currentDisplayName;
                                                            [self updateUserPicture:self.mxAccount.userAvatarUrl force:YES];
                                                            // Loop to end saving
                                                            [self saveUserInfo];
                                                            
                                                        }]];
                
                [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n retry]
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            
                                                            [self->alertsArray removeObject:alert];
                                                            // Loop to retry saving
                                                            [self saveUserInfo];
                                                            
                                                        }]];
                
                
                [self presentViewController:alert animated:YES completion:nil];
            }
            
         }];
        
        return;
    }
    
    // Check whether avatar has been updated
    if (isAvatarUpdated)
    {
        if (uploadedPictureURL == nil)
        {
            // Retrieve the current picture and make sure its orientation is up
            UIImage *updatedPicture = [MXKTools forceImageOrientationUp:[self.userPictureButton imageForState:UIControlStateNormal]];
            
            MXWeakify(self);
            
            // Upload picture
            MXMediaLoader *uploader = [MXMediaManager prepareUploaderWithMatrixSession:self.mainSession initialRange:0 andRange:1.0];
            [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url)
             {
                 MXStrongifyAndReturnIfNil(self);
                 
                 // Store uploaded picture url and trigger picture saving
                 self->uploadedPictureURL = url;
                 [self saveUserInfo];
             } failure:^(NSError *error)
             {
                 MXLogDebug(@"[MXKAccountDetailsVC] Failed to upload image");
                 MXStrongifyAndReturnIfNil(self);
                 [self handleErrorDuringPictureSaving:error];
             }];
            
        }
        else
        {
            MXWeakify(self);
            
            [_mxAccount setUserAvatarUrl:uploadedPictureURL
                                 success:^{
                                     
                                     // uploadedPictureURL becomes the user's picture
                                     MXStrongifyAndReturnIfNil(self);
                                     
                                     [self updateUserPicture:self->uploadedPictureURL force:YES];
                                     // Loop to end saving
                                     [self saveUserInfo];
                                     
                                 }
                                 failure:^(NSError *error) {
                                     MXLogDebug(@"[MXKAccountDetailsVC] Failed to set avatar url");
                                     MXStrongifyAndReturnIfNil(self);
                                     [self handleErrorDuringPictureSaving:error];
                                 }];
        }
        
        return;
    }
    
    // Backup is complete
    isSavingInProgress = NO;
    [self stopProfileActivityIndicator];
    
    // Ready to leave
    if (onReadyToLeaveHandler)
    {
        onReadyToLeaveHandler();
        onReadyToLeaveHandler = nil;
    }
}

- (void)handleErrorDuringPictureSaving:(NSError*)error
{
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title)
    {
        title = [VectorL10n accountErrorPictureChangeFailed];
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alertsArray addObject:alert];
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n abort]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                
                                                [self->alertsArray removeObject:alert];
                                                
                                                // Remove change
                                                self.userDisplayName.text = self->currentDisplayName;
                                                [self updateUserPicture:self->_mxAccount.userAvatarUrl force:YES];
                                                // Loop to end saving
                                                [self saveUserInfo];
                                                
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n retry]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                
                                                [self->alertsArray removeObject:alert];
                                                
                                                // Loop to retry saving
                                                [self saveUserInfo];
                                                
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateUserPicture:(NSString *)avatar_url force:(BOOL)force
{
    if (force || currentPictureURL == nil || [currentPictureURL isEqualToString:avatar_url] == NO)
    {
        // Remove any pending observers
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        // Cancel previous loader (if any)
        if (imageLoader)
        {
            [imageLoader cancel];
            imageLoader = nil;
        }
        // Cancel any local change
        isAvatarUpdated = NO;
        uploadedPictureURL = nil;
        
        currentPictureURL = [avatar_url isEqual:[NSNull null]] ? nil : avatar_url;
        
        // Check whether this url is valid
        currentDownloadId = [MXMediaManager thumbnailDownloadIdForMatrixContentURI:currentPictureURL
                                                                          inFolder:kMXMediaManagerAvatarThumbnailFolder
                                                                     toFitViewSize:self.userPictureButton.frame.size
                                                                        withMethod:MXThumbnailingMethodCrop];
        if (!currentDownloadId)
        {
            // Set the placeholder in case of invalid Matrix Content URI.
            [self updateUserPictureButton:self.picturePlaceholder];
        }
        else
        {
            // Check whether the image download is in progress
            id loader = [MXMediaManager existingDownloaderWithIdentifier:currentDownloadId];
            if (loader)
            {
                // Observe this loader
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(onMediaLoaderStateChange:)
                                                             name:kMXMediaLoaderStateDidChangeNotification
                                                           object:loader];
            }
            else
            {
                NSString *cacheFilePath = [MXMediaManager thumbnailCachePathForMatrixContentURI:currentPictureURL
                                                                                        andType:nil
                                                                                       inFolder:kMXMediaManagerAvatarThumbnailFolder
                                                                                  toFitViewSize:self.userPictureButton.frame.size
                                                                                     withMethod:MXThumbnailingMethodCrop];
                // Retrieve the image from cache
                UIImage* image = [MXMediaManager loadPictureFromFilePath:cacheFilePath];
                if (image)
                {
                    [self updateUserPictureButton:image];
                }
                else
                {
                    // Download the image, by adding download observer
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(onMediaLoaderStateChange:)
                                                                 name:kMXMediaLoaderStateDidChangeNotification
                                                               object:nil];
                    imageLoader = [self.mainSession.mediaManager downloadThumbnailFromMatrixContentURI:currentPictureURL
                                                                                              withType:nil
                                                                                              inFolder:kMXMediaManagerAvatarThumbnailFolder
                                                                                         toFitViewSize:self.userPictureButton.frame.size
                                                                                            withMethod:MXThumbnailingMethodCrop
                                                                                               success:nil
                                                                                               failure:nil];
                }
            }
        }
    }
}

- (void)updateUserPictureButton:(UIImage*)image
{
    [self.userPictureButton setImage:image forState:UIControlStateNormal];
    [self.userPictureButton setImage:image forState:UIControlStateHighlighted];
    [self.userPictureButton setImage:image forState:UIControlStateDisabled];
}

- (void)updateSaveUserInfoButtonStatus
{
    // Check whether display name has been changed
    NSString *displayname = self.userDisplayName.text;
    BOOL isDisplayNameUpdated = ((displayname.length || currentDisplayName.length) && [displayname isEqualToString:currentDisplayName] == NO);
    
    saveUserInfoButton.enabled = (isDisplayNameUpdated || isAvatarUpdated) && !isSavingInProgress;
}

- (void)onMediaLoaderStateChange:(NSNotification *)notif
{
    MXMediaLoader *loader = (MXMediaLoader*)notif.object;
    if ([loader.downloadId isEqualToString:currentDownloadId])
    {
        // update the image
        switch (loader.state) {
            case MXMediaLoaderStateDownloadCompleted:
            {
                UIImage *image = [MXMediaManager loadPictureFromFilePath:loader.downloadOutputFilePath];
                if (image == nil)
                {
                    image = self.picturePlaceholder;
                }
                [self updateUserPictureButton:image];
                // remove the observers
                [[NSNotificationCenter defaultCenter] removeObserver:self];
                imageLoader = nil;
                break;
            }
            case MXMediaLoaderStateDownloadFailed:
            case MXMediaLoaderStateCancelled:
                [self updateUserPictureButton:self.picturePlaceholder];
                // remove the observers
                [[NSNotificationCenter defaultCenter] removeObserver:self];
                imageLoader = nil;
                // Reset picture URL in order to try next time
                currentPictureURL = nil;
                break;
            default:
                break;
        }
    }
}

- (void)onAPNSStatusUpdate
{
    // Force table reload to update notifications section
    apnsNotificationsSwitch = nil;
    
    [self.tableView reloadData];
}

- (void)dismissMediaPicker
{
    if (mediaPicker)
    {
        [self dismissViewControllerAnimated:NO completion:nil];
        mediaPicker.delegate = nil;
        mediaPicker = nil;
    }
}

- (void)showValidationEmailDialogWithMessage:(NSString*)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n accountEmailValidationTitle] message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertsArray addObject:alert];
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n abort]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                
                                                [self->alertsArray removeObject:alert];
                                                
                                                self->emailSubmitButton.enabled = YES;
                                                
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n continue]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                
                                                [self->alertsArray removeObject:alert];
                                                
                                                __weak typeof(self) weakSelf = self;
                                                
                                                // We do not bind anymore emails when registering, so let's do the same here
                                                [self->submittedEmail add3PIDToUser:NO success:^{
                                                    
                                                    if (weakSelf)
                                                    {
                                                        typeof(self) self = weakSelf;
                                                        
                                                        // Release pending email and refresh table to remove related cell
                                                        self->emailTextField.text = nil;
                                                        self->submittedEmail = nil;
                                                        
                                                        // Update linked emails
                                                        [self loadLinkedEmails];
                                                    }
                                                    
                                                } failure:^(NSError *error) {
                                                    
                                                    if (weakSelf)
                                                    {
                                                        typeof(self) self = weakSelf;
                                                        
                                                        MXLogDebug(@"[MXKAccountDetailsVC] Failed to bind email");
                                                        
                                                        // Display the same popup again if the error is M_THREEPID_AUTH_FAILED
                                                        MXError *mxError = [[MXError alloc] initWithNSError:error];
                                                        if (mxError && [mxError.errcode isEqualToString:kMXErrCodeStringThreePIDAuthFailed])
                                                        {
                                                            [self showValidationEmailDialogWithMessage:[VectorL10n accountEmailValidationError]];
                                                        }
                                                        else
                                                        {
                                                            // Notify MatrixKit user
                                                            NSString *myUserId = self.mxAccount.mxCredentials.userId;
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                                                        }
                                                        
                                                        // Release the pending email (even if it is Authenticated)
                                                        [self.tableView reloadData];
                                                    }
                                                    
                                                }];
                                                
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)loadLinkedEmails
{
    // Refresh the account 3PIDs list
    [_mxAccount load3PIDs:^{

        [self.tableView reloadData];

    } failure:^(NSError *error) {
        // Display the data that has been loaded last time
        [self.tableView reloadData];
    }];
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender
{
    [self dismissKeyboard];

    if (sender == saveUserInfoButton)
    {
        [self saveUserInfo];
    }
    else if (sender == userPictureButton)
    {
        // Open picture gallery
        mediaPicker = [[UIImagePickerController alloc] init];
        mediaPicker.delegate = self;
        mediaPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        mediaPicker.allowsEditing = NO;
        [self presentViewController:mediaPicker animated:YES completion:nil];
    }
    else if (sender == logoutButton)
    {
        [[MXKAccountManager sharedManager] removeAccount:_mxAccount completion:nil];
        self.mxAccount = nil;
    }
    else if (sender == emailSubmitButton)
    {
        // Email check
        if (![MXTools isEmailAddress:emailTextField.text])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[VectorL10n accountErrorEmailWrongTitle] message:[VectorL10n accountErrorEmailWrongDescription] preferredStyle:UIAlertControllerStyleAlert];
            
            [alertsArray addObject:alert];
            [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        
                                                        [self->alertsArray removeObject:alert];
                                                        
                                                    }]];
            
            [self presentViewController:alert animated:YES completion:nil];

            return;
        }
        
        if (!submittedEmail || ![submittedEmail.address isEqualToString:emailTextField.text])
        {
            submittedEmail = [[MXK3PID alloc] initWithMedium:kMX3PIDMediumEmail andAddress:emailTextField.text];
        }
        
        emailSubmitButton.enabled = NO;
        __weak typeof(self) weakSelf = self;

        [submittedEmail requestValidationTokenWithMatrixRestClient:self.mainSession.matrixRestClient isDuringRegistration:NO nextLink:nil success:^{

            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                [self showValidationEmailDialogWithMessage:[VectorL10n accountEmailValidationMessage]];
            }

        } failure:^(NSError *error) {

            MXLogDebug(@"[MXKAccountDetailsVC] Failed to request email token");
            if (weakSelf)
            {
                typeof(self) self = weakSelf;
                // Notify MatrixKit user
                NSString *myUserId = self.mxAccount.mxCredentials.userId;
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error userInfo:myUserId ? @{kMXKErrorUserIdKey: myUserId} : nil];
                
                self->emailSubmitButton.enabled = YES;
            }

        }];
    }
    else if (sender == apnsNotificationsSwitch)
    {
        [_mxAccount enablePushNotifications:apnsNotificationsSwitch.on success:nil failure:nil];
        apnsNotificationsSwitch.enabled = NO;
    }
    else if (sender == inAppNotificationsSwitch)
    {
        _mxAccount.enableInAppNotifications = inAppNotificationsSwitch.on;
        [self.tableView reloadData];
    }
}

#pragma mark - keyboard

- (void)dismissKeyboard
{
    if ([userDisplayName isFirstResponder])
    {
        // Hide the keyboard
        [userDisplayName resignFirstResponder];
        [self updateSaveUserInfoButtonStatus];
    }
    else if ([emailTextField isFirstResponder])
    {
        [emailTextField resignFirstResponder];
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    // "Done" key has been pressed
    [self dismissKeyboard];
    return YES;
}

- (IBAction)textFieldEditingChanged:(id)sender
{
    if (sender == userDisplayName)
    {
        [self updateSaveUserInfoButtonStatus];
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = 0;
    
    linkedEmailsSection = notificationsSection = configurationSection = -1;
    
    if (!_mxAccount.disabled)
    {
        linkedEmailsSection = count ++;
        notificationsSection = count ++;
    }
    
    configurationSection = count ++;
    
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (section == linkedEmailsSection)
    {
        count = _mxAccount.linkedEmails.count;
        submittedEmailRowIndex = count++;
    }
    else if (section == notificationsSection)
    {
        enableInAppNotifRowIndex = enablePushNotifRowIndex = -1;
        
        if ([MXKAccountManager sharedManager].isAPNSAvailable) {
            enablePushNotifRowIndex = count++;
        }
        enableInAppNotifRowIndex = count++;
    }
    else if (section == configurationSection)
    {
        count = 2;
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == configurationSection)
    {
        if (indexPath.row == 0)
        {
            UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
            textView.font = [UIFont systemFontOfSize:14];
            textView.text = [NSString stringWithFormat:@"%@\n%@\n%@", [VectorL10n settingsConfigHomeServer:_mxAccount.mxCredentials.homeServer], [VectorL10n settingsConfigIdentityServer:_mxAccount.identityServerURL], [VectorL10n settingsConfigUserId:_mxAccount.mxCredentials.userId]];
            
            CGSize contentSize = [textView sizeThatFits:textView.frame.size];
            return contentSize.height + 1;
        }
    }
    
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == linkedEmailsSection)
    {
        if (indexPath.row < _mxAccount.linkedEmails.count)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kMXKAccountDetailsLinkedEmailCellId];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMXKAccountDetailsLinkedEmailCellId];
            }
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = [_mxAccount.linkedEmails objectAtIndex:indexPath.row];
        }
        else if (indexPath.row == submittedEmailRowIndex)
        {
            // Report the current email value (if any)
            NSString *currentEmail = nil;
            if (emailTextField)
            {
                currentEmail = emailTextField.text;
            }
            
            MXKTableViewCellWithTextFieldAndButton *submittedEmailCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithTextFieldAndButton defaultReuseIdentifier]];
            if (!submittedEmailCell)
            {
                submittedEmailCell = [[MXKTableViewCellWithTextFieldAndButton alloc] init];
            }
            
            submittedEmailCell.mxkTextField.text = currentEmail;
            submittedEmailCell.mxkTextField.keyboardType = UIKeyboardTypeEmailAddress;
            submittedEmailCell.mxkButton.enabled = (currentEmail.length != 0);
            [submittedEmailCell.mxkButton setTitle:[VectorL10n accountLinkEmail] forState:UIControlStateNormal];
            [submittedEmailCell.mxkButton setTitle:[VectorL10n accountLinkEmail] forState:UIControlStateHighlighted];
            [submittedEmailCell.mxkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            emailSubmitButton = submittedEmailCell.mxkButton;
            emailTextField = submittedEmailCell.mxkTextField;

            cell = submittedEmailCell;
        }
    }
    else if (indexPath.section == notificationsSection)
    {
        MXKTableViewCellWithLabelAndSwitch *notificationsCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
        if (!notificationsCell)
        {
            notificationsCell = [[MXKTableViewCellWithLabelAndSwitch alloc] init];
        }
        else
        {
            // Force layout before reusing a cell (fix switch displayed outside the screen)
            [notificationsCell layoutIfNeeded];
        }
        
        [notificationsCell.mxkSwitch addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventValueChanged];
        
        if (indexPath.row == enableInAppNotifRowIndex)
        {
            notificationsCell.mxkLabel.text = [VectorL10n settingsEnableInappNotifications];
            notificationsCell.mxkSwitch.on = _mxAccount.enableInAppNotifications;
            inAppNotificationsSwitch = notificationsCell.mxkSwitch;
        }
        else /* enablePushNotifRowIndex */
        {
            notificationsCell.mxkLabel.text = [VectorL10n settingsEnablePushNotifications];
            notificationsCell.mxkSwitch.on = _mxAccount.pushNotificationServiceIsActive;
            notificationsCell.mxkSwitch.enabled = YES;
            apnsNotificationsSwitch = notificationsCell.mxkSwitch;
        }
        
        cell = notificationsCell;
    }
    else if (indexPath.section == configurationSection)
    {
        if (indexPath.row == 0)
        {
            MXKTableViewCellWithTextView *configCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithTextView defaultReuseIdentifier]];
            if (!configCell)
            {
                configCell = [[MXKTableViewCellWithTextView alloc] init];
            }
            
            configCell.mxkTextView.text = [NSString stringWithFormat:@"%@\n%@\n%@", [VectorL10n settingsConfigHomeServer:_mxAccount.mxCredentials.homeServer], [VectorL10n settingsConfigIdentityServer:_mxAccount.identityServerURL], [VectorL10n settingsConfigUserId:_mxAccount.mxCredentials.userId]];
            
            cell = configCell;
        }
        else
        {
            MXKTableViewCellWithButton *logoutBtnCell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithButton defaultReuseIdentifier]];
            if (!logoutBtnCell)
            {
                logoutBtnCell = [[MXKTableViewCellWithButton alloc] init];
            }
            [logoutBtnCell.mxkButton setTitle:[VectorL10n actionLogout] forState:UIControlStateNormal];
            [logoutBtnCell.mxkButton setTitle:[VectorL10n actionLogout] forState:UIControlStateHighlighted];
            [logoutBtnCell.mxkButton addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            logoutButton = logoutBtnCell.mxkButton;
            
            cell = logoutBtnCell;
        }
        
    }
    else
    {
        // Return a fake cell to prevent app from crashing.
        cell = [[UITableViewCell alloc] init];
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}
- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *sectionHeader = [[UIView alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    UILabel *sectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, sectionHeader.frame.size.width - 10, sectionHeader.frame.size.height - 10)];
    sectionLabel.font = [UIFont boldSystemFontOfSize:16];
    sectionLabel.backgroundColor = [UIColor clearColor];
    [sectionHeader addSubview:sectionLabel];
    
    if (section == linkedEmailsSection)
    {
        sectionLabel.text = [VectorL10n accountLinkedEmails];
    }
    else if (section == notificationsSection)
    {
        sectionLabel.text = [VectorL10n settingsTitleNotifications];
    }
    else if (section == configurationSection)
    {
        sectionLabel.text = [VectorL10n settingsTitleConfig];
    }
    
    return sectionHeader;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == aTableView)
    {
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

# pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (selectedImage)
    {
        [self updateUserPictureButton:selectedImage];
        isAvatarUpdated = YES;
        saveUserInfoButton.enabled = YES;
    }
    [self dismissMediaPicker];
}

@end
