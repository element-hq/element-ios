/*
 Copyright 2014 OpenMarket Ltd
 
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

#import "SettingsViewController.h"

#import "AppDelegate.h"
#import "AppSettings.h"
#import "APNSHandler.h"
#import "MatrixSDKHandler.h"
#import "MediaManager.h"
#import "MXC3PID.h"
#import "MXCTools.h"

#import "ContactManager.h"

#import "SettingsTableViewCell.h"

#define SETTINGS_SECTION_LINKED_EMAILS_INDEX 0
#define SETTINGS_SECTION_NOTIFICATIONS_INDEX 1
#define SETTINGS_SECTION_CONTACTS_INDEX      2
#define SETTINGS_SECTION_ROOMS_INDEX         3
#define SETTINGS_SECTION_CONFIGURATION_INDEX 4
#define SETTINGS_SECTION_COMMANDS_INDEX      5
#define SETTINGS_SECTION_COUNT               6

#define SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX         0
#define SETTINGS_SECTION_ROOMS_HIDE_REDACTIONS_INDEX         1
#define SETTINGS_SECTION_ROOMS_HIDE_UNSUPPORTED_EVENTS_INDEX    2
#define SETTINGS_SECTION_ROOMS_SORT_MEMBERS_INDEX               3
#define SETTINGS_SECTION_ROOMS_DISPLAY_LEFT_MEMBERS_INDEX       4
#define SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX             5
#define SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX                6
#define SETTINGS_SECTION_ROOMS_INDEX_COUNT                      7

NSString* const kUserInfoNotificationRulesText = @"To configure global notification settings (like rules), go find a webclient and hit Settings > Notifications.";
NSString* const kConfigurationFormatText = @"matrixConsole version: %@\r\nSDK version: %@\r\n%@\r\nHome server: %@\r\nIdentity server: %@\r\nUser ID: %@";
NSString* const kBuildFormatText = @"Build: %@\r\n";
NSString* const kCommandsDescriptionText = @"The following commands are available in the room chat:\r\n\r\n /nick <display_name>: change your display name\r\n /me <action>: send the action you are doing. /me will be replaced by your display name\r\n /join <room_alias>: join a room\r\n /kick <user_id> [<reason>]: kick the user\r\n /ban <user_id> [<reason>]: ban the user\r\n /unban <user_id>: unban the user\r\n /op <user_id> <power_level>: set user power level\r\n /deop <user_id>: reset user power level to the room default value";

@interface SettingsViewController () {
    NSMutableArray *alertsArray;
    
    // Navigation Bar button
    UIButton *logoutBtn;
    
    // User's profile
    MediaLoader *imageLoader;
    NSString *currentDisplayName;
    NSString *currentPictureURL;
    NSString *currentPictureThumbURL;
    NSString *uploadedPictureURL;
    // Local changes
    BOOL isAvatarUpdated;
    BOOL isSavingInProgress;
    // Listen user's profile changes
    id userUpdateListener;
    
    // Linked emails
    NSMutableArray *linkedEmails;
    MXC3PID        *submittedEmail;
    SettingsCellWithTextFieldAndButton* submittedEmailCell;
    SettingsCellWithLabelTextFieldAndButton* emailTokenCell;
    // Dynamic rows in the Linked emails section
    NSInteger submittedEmailRowIndex;
    NSInteger emailTokenRowIndex;
    
    // Notifications
    UISwitch *apnsNotificationsSwitch;
    UISwitch *inAppNotificationsSwitch;
    // Dynamic rows in the Notifications section
    NSInteger enablePushNotifRowIndex;
    NSInteger enableInAppNotifRowIndex;
    NSInteger userInfoNotifRowIndex;
    
    // Contacts
    UISwitch *contactsSyncSwitch;
    // Country codes management
    NSArray* countryCodes;
    NSString* countryCode;
    NSString* selectedCountryCode;
    BOOL isSelectingCountryCode;
    // Dynamic rows in Contacts section
    NSInteger syncLocalContactsRowIndex;
    NSInteger countryCodeRowIndex;
    
    // Rooms settings
    UISwitch *allEventsSwitch;
    UISwitch *redactionsSwitch;
    UISwitch *unsupportedEventsSwitch;
    UISwitch *sortMembersSwitch;
    UISwitch *displayLeftMembersSwitch;
    SettingsCellWithLabelAndSlider* maxCacheSizeCell;
    NSUInteger minimumCacheSize;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableHeader;
@property (weak, nonatomic) IBOutlet UIButton *userPictureButton;
@property (weak, nonatomic) IBOutlet UITextField *userDisplayName;
@property (weak, nonatomic) IBOutlet UIButton *saveUserInfoButton;
@property (strong, nonatomic) IBOutlet UIView *activityIndicatorBackgroundView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)onButtonPressed:(id)sender;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Add logout button in nav bar
    logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    logoutBtn.frame = CGRectMake(0, 0, 60, 44);
    [logoutBtn setTitle:@"Logout" forState:UIControlStateNormal];
    [logoutBtn setTitle:@"Logout" forState:UIControlStateHighlighted];
    [logoutBtn addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logoutBtn];
    
    // keep the aspect ratio of the contact thumbnail
    // scale it to fit the button frame
    [[self.userPictureButton imageView] setContentMode: UIViewContentModeScaleAspectFill];
    [[self.userPictureButton imageView] setClipsToBounds:YES];
    
    alertsArray = [NSMutableArray array];
    
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    [mxHandler addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    // Initialize the minimum cache size with the current value
    minimumCacheSize = mxHandler.minCachesSize;
    
    isAvatarUpdated = NO;
    isSavingInProgress = NO;
    
    _saveUserInfoButton.enabled = NO;
    _activityIndicatorBackgroundView.hidden = YES;

    // country selection
    NSString *path = [[NSBundle mainBundle] pathForResource:@"countryCodes" ofType:@"plist"];
    countryCodes = [NSArray arrayWithContentsOfFile:path];
    isSelectingCountryCode = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    if (imageLoader) {
        [imageLoader cancel];
        imageLoader = nil;
    }
}

- (void)dealloc {
    [self reset];
    alertsArray = nil;
    logoutBtn = nil;
    
    [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    selectedCountryCode = countryCode = [[AppSettings sharedSettings] countryCode];
    
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    [mxHandler addObserver:self forKeyPath:@"isActivityInProgress" options:0 context:nil];
    
    // Update the minimum cache size with the current value
    // Dispatch this operation to not freeze the app
    dispatch_async(dispatch_get_main_queue(), ^{
        minimumCacheSize = mxHandler.minCachesSize;
    });
    
    // Refresh display
    if (mxHandler.isActivityInProgress) {
        [self startActivityIndicator];
    }
    [self configureView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAPNSHandlerHasBeenUpdated) name:kAPNSHandlerHasBeenUpdated object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"isActivityInProgress"];
    [self stopActivityIndicator];

    // if country has been updated
    // update the contact phonenumbers
    // and check if they match now to Matrix Users
    if (![countryCode isEqualToString:selectedCountryCode]) {
        
        [[AppSettings sharedSettings] setCountryCode:selectedCountryCode];
        countryCode = selectedCountryCode;
        
        [[ContactManager sharedManager] internationalizePhoneNumbers:countryCode];
        [[ContactManager sharedManager] fullRefresh];
    }
        countryCode = [[AppSettings sharedSettings] countryCode];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAPNSHandlerHasBeenUpdated object:nil];
}

- (BOOL)shouldLeave:(blockSettings_onReadyToLeave)handler {
    // Check whether some local changes have not been saved
    if (_saveUserInfoButton.enabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MXKAlert *alert = [[MXKAlert alloc] initWithTitle:nil message:@"Changes will be discarded"  style:MXKAlertStyleAlert];
            [alertsArray addObject:alert];
            alert.cancelButtonIndex = [alert addActionWithTitle:@"Discard" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                [alertsArray removeObject:alert];
                // Discard changes
                self.userDisplayName.text = currentDisplayName;
                [self updateUserPicture:[MatrixSDKHandler sharedHandler].mxSession.myUser.avatarUrl force:YES];
                // Ready to leave
                if (handler) {
                    handler();
                }
            }];
            [alert addActionWithTitle:@"Save" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                [alertsArray removeObject:alert];
                // Start saving
                [self saveUserInfo];
                // Ready to leave
                if (handler) {
                    handler();
                }
            }];
            [alert showInViewController:self];
        });
                       
        return NO;
    }
    return YES;
}

#pragma mark - Internal methods

- (void)onAPNSHandlerHasBeenUpdated {
    // Force table reload to update notifications section
    apnsNotificationsSwitch = nil;
    [self.tableView reloadData];
}

- (void)reset {
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Cancel picture loader (if any)
    if (imageLoader) {
        [imageLoader cancel];
        imageLoader = nil;
    }
    
    // Cancel potential alerts
    for (MXKAlert *alert in alertsArray){
        [alert dismiss:NO];
    }
    
    // Remove listener
    if (userUpdateListener) {
        [[MatrixSDKHandler sharedHandler].mxSession.myUser removeListener:userUpdateListener];
        userUpdateListener = nil;
    }
    
    currentPictureURL = nil;
    currentPictureThumbURL = nil;
    uploadedPictureURL = nil;
    isAvatarUpdated = NO;
    [self updateUserPictureButton:[UIImage imageNamed:@"default-profile"]];
    
    currentDisplayName = nil;
    self.userDisplayName.text = nil;
    
    _saveUserInfoButton.enabled = NO;
    
    linkedEmails = nil;
    submittedEmail = nil;
    submittedEmailCell = nil;
    emailTokenCell = nil;
    
    contactsSyncSwitch = nil;
    
    apnsNotificationsSwitch = nil;
    inAppNotificationsSwitch = nil;
    
    allEventsSwitch = nil;
    unsupportedEventsSwitch = nil;
    sortMembersSwitch = nil;
    displayLeftMembersSwitch = nil;
    maxCacheSizeCell = nil;
}

- (void)startActivityIndicator {
    if (_activityIndicatorBackgroundView.hidden) {
        _activityIndicatorBackgroundView.hidden = NO;
        [_activityIndicator startAnimating];
    }
    _userPictureButton.enabled = NO;
    _userDisplayName.enabled = NO;
    _saveUserInfoButton.enabled = NO;
}

- (void)stopActivityIndicator {
    if (!_activityIndicatorBackgroundView.hidden) {
        _activityIndicatorBackgroundView.hidden = YES;
        [_activityIndicator stopAnimating];
    }
    _userPictureButton.enabled = YES;
    _userDisplayName.enabled = YES;
    [self updateSaveUserInfoButtonStatus];
}

- (void)configureView {
    // Ignore any refresh when saving is in progress
    if (isSavingInProgress) {
        return;
    }
    
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
    // Disable user's interactions
    _userPictureButton.enabled = NO;
    _userDisplayName.enabled = NO;
    
    if (mxHandler.status == MatrixSDKHandlerStatusServerSyncDone) {
        if (!userUpdateListener) {
            // Set current user's information and add observers
            [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl force:YES];
            currentDisplayName = mxHandler.mxSession.myUser.displayname;
            self.userDisplayName.text = currentDisplayName;
            
            // Register listener to update user's information
            userUpdateListener = [mxHandler.mxSession.myUser listenToUserUpdate:^(MXEvent *event) {
                // Update displayName
                if (![currentDisplayName isEqualToString:mxHandler.mxSession.myUser.displayname]) {
                    currentDisplayName = mxHandler.mxSession.myUser.displayname;
                    self.userDisplayName.text = mxHandler.mxSession.myUser.displayname;
                }
                // Update user's avatar
                [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl force:NO];
                
                // Update button management
                [self updateSaveUserInfoButtonStatus];
                
                // TODO display user's presence
            }];
        }
    } else if (mxHandler.status == MatrixSDKHandlerStatusStoreDataReady || mxHandler.status == MatrixSDKHandlerStatusInitialServerSyncInProgress) {
        // Remove listener (if any), this action is required to handle correctly matrix sdk handler reload (see clear cache)
        if (userUpdateListener) {
            [mxHandler.mxSession.myUser removeListener:userUpdateListener];
            userUpdateListener = nil;
        }
        // Set local user's information (the data may not be up-to-date)
        [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl force:NO];
        currentDisplayName = mxHandler.mxSession.myUser.displayname;
        self.userDisplayName.text = currentDisplayName;
    } else if (mxHandler.status == MatrixSDKHandlerStatusLoggedOut) {
        [self reset];
    }
    
    // Restore user's interactions
    _userPictureButton.enabled = YES;
    _userDisplayName.enabled = YES;
    
    [self.tableView reloadData];
}

- (void)saveUserInfo {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    [self startActivityIndicator];
    isSavingInProgress = YES;
    
    // Check whether the display name has been changed
    NSString *displayname = self.userDisplayName.text;
    if ((displayname.length || currentDisplayName.length) && [displayname isEqualToString:currentDisplayName] == NO) {
        // Save display name
        [mxHandler.mxSession.myUser setDisplayName:displayname success:^{
            // Update the current displayname
            currentDisplayName = displayname;
            // Go to the next change saving step
            [self saveUserInfo];
        } failure:^(NSError *error) {
            NSLog(@"[SettingsVC] Failed to set displayName: %@", error);
            //Alert user
            NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
            if (!title) {
                title = @"Display name change failed";
            }
            NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
            
            MXKAlert *alert = [[MXKAlert alloc] initWithTitle:title message:msg style:MXKAlertStyleAlert];
            [alertsArray addObject:alert];
            alert.cancelButtonIndex = [alert addActionWithTitle:@"Abort" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                [alertsArray removeObject:alert];
                // Discard changes
                self.userDisplayName.text = currentDisplayName;
                [self updateUserPicture:[MatrixSDKHandler sharedHandler].mxSession.myUser.avatarUrl force:YES];
                // Loop to end saving
                [self saveUserInfo];
            }];
            [alert addActionWithTitle:@"Retry" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                [alertsArray removeObject:alert];
                // Loop to retry saving
                [self saveUserInfo];
            }];
            [alert showInViewController:self];
        }];
        return;
    }
    
    // Check whether avatar has been updated
    if (isAvatarUpdated) {
        if (uploadedPictureURL == nil) {
            // Retrieve the current picture and make sure its orientation is up
            UIImage *updatedPicture = [MXCTools forceImageOrientationUp:[self.userPictureButton imageForState:UIControlStateNormal]];
            
            // Upload picture
            MediaLoader *uploader = [[MediaLoader alloc] initWithUploadId:nil initialRange:0 andRange:1.0 folder:kMediaManagerThumbnailFolder];
            [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) mimeType:@"image/jpeg" success:^(NSString *url) {
                // Store uploaded picture url and trigger picture saving
                uploadedPictureURL = url;
                [self saveUserInfo];
            } failure:^(NSError *error) {
                NSLog(@"[SettingsVC] Failed to upload image: %@", error);
                [self handleErrorDuringPictureSaving:error];
            }];
        } else {
            [mxHandler.mxSession.myUser setAvatarUrl:uploadedPictureURL
                                             success:^{
                                                 // uploadedPictureURL becomes the user's picture
                                                 [self updateUserPicture:uploadedPictureURL force:YES];
                                                 // Loop to end saving
                                                 [self saveUserInfo];
                                             } failure:^(NSError *error) {
                                                 NSLog(@"[SettingsVC] Failed to set avatar url: %@", error);
                                                 [self handleErrorDuringPictureSaving:error];
                                             }];
        }
        return;
    }
    
    // Backup is complete
    isSavingInProgress = NO;
    // Stop activity indicator except if matrix sdk handler is working
    if (!mxHandler.isActivityInProgress) {
        [self stopActivityIndicator];
    }
}

- (void)handleErrorDuringPictureSaving:(NSError*)error {
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title) {
        title = @"Picture change failed";
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    MXKAlert *alert = [[MXKAlert alloc] initWithTitle:title message:msg style:MXKAlertStyleAlert];
    [alertsArray addObject:alert];
    alert.cancelButtonIndex = [alert addActionWithTitle:@"Abort" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        [alertsArray removeObject:alert];
        // Remove change
        self.userDisplayName.text = currentDisplayName;
        [self updateUserPicture:[MatrixSDKHandler sharedHandler].mxSession.myUser.avatarUrl force:YES];
        // Loop to end saving
        [self saveUserInfo];
    }];
    [alert addActionWithTitle:@"Retry" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
        [alertsArray removeObject:alert];
        // Loop to retry saving
        [self saveUserInfo];
    }];
    
    [alert showInViewController:self];
}

- (void)updateUserPicture:(NSString *)avatar_url force:(BOOL)force {
    if (force || currentPictureURL == nil || [currentPictureURL isEqualToString:avatar_url] == NO) {
        // Remove any pending observers
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        // Cancel previous loader (if any)
        if (imageLoader) {
            [imageLoader cancel];
            imageLoader = nil;
        }
        // Cancel any local change
        isAvatarUpdated = NO;
        uploadedPictureURL = nil;
        
        currentPictureURL = [avatar_url isEqual:[NSNull null]] ? nil : avatar_url;
        if (currentPictureURL) {
            // Suppose this url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
            MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
            currentPictureThumbURL = [mxHandler thumbnailURLForContent:currentPictureURL inViewSize:self.userPictureButton.frame.size withMethod:MXThumbnailingMethodCrop];
            
            // Check whether the image download is in progress
            id loader = [MediaManager existingDownloaderForURL:currentPictureThumbURL inFolder:kMediaManagerThumbnailFolder];
            if (loader) {
                // Add observers
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFinishNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFailNotification object:nil];
            } else {
                // Retrieve the image from cache
                UIImage* image = [MediaManager loadCachePictureForURL:currentPictureThumbURL inFolder:kMediaManagerThumbnailFolder];
                if (image) {
                    [self updateUserPictureButton:image];
                } else {
                    // Cancel potential download in progress
                    if (imageLoader) {
                        [imageLoader cancel];
                    }
                    // Add observers
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFinishNotification object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFailNotification object:nil];
                    imageLoader = [MediaManager downloadMediaFromURL:currentPictureThumbURL withType:@"image/jpeg" inFolder:kMediaManagerThumbnailFolder];
                }
            }
        } else {
            // Set placeholder
            [self updateUserPictureButton:[UIImage imageNamed:@"default-profile"]];
        }
    }
}

- (void)updateUserPictureButton:(UIImage*)image {
    [self.userPictureButton setImage:image forState:UIControlStateNormal];
    [self.userPictureButton setImage:image forState:UIControlStateHighlighted];
    [self.userPictureButton setImage:image forState:UIControlStateDisabled];
}

- (void)updateSaveUserInfoButtonStatus {
    // Check whether display name has been changed
    NSString *displayname = self.userDisplayName.text;
    BOOL isDisplayNameUpdated = ((displayname.length || currentDisplayName.length) && [displayname isEqualToString:currentDisplayName] == NO);
    
    _saveUserInfoButton.enabled = isDisplayNameUpdated || isAvatarUpdated;
}

- (void)onMediaDownloadEnd:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:currentPictureThumbURL]) {
            // update the image
            UIImage* image = [MediaManager loadCachePictureForURL:currentPictureThumbURL inFolder:kMediaManagerThumbnailFolder];
            if (image == nil) {
                image = [UIImage imageNamed:@"default-profile"];
            }
            [self updateUserPictureButton:image];
            
            // remove the observers
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            imageLoader = nil;
            
            if ([notif.name isEqualToString:kMediaDownloadDidFailNotification]) {
                // Reset picture URL in order to try next time
                currentPictureURL = nil;
            }
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([@"status" isEqualToString:keyPath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureView];
        });
    } else if ([@"isActivityInProgress" isEqualToString:keyPath]) {
        if ([MatrixSDKHandler sharedHandler].isActivityInProgress || isSavingInProgress) {
            [self startActivityIndicator];
        } else {
            [self stopActivityIndicator];
        }
    }
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    if (sender == _saveUserInfoButton) {
        [self saveUserInfo];
    } else if (sender == _userPictureButton) {
        // Open picture gallery
        UIImagePickerController *mediaPicker = [[UIImagePickerController alloc] init];
        mediaPicker.delegate = self;
        mediaPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        mediaPicker.allowsEditing = NO;
        [[AppDelegate theDelegate].masterTabBarController presentMediaPicker:mediaPicker];
    } else if (sender == logoutBtn) {
        [[AppDelegate theDelegate] logout];
    } else if (sender == submittedEmailCell.settingButton) {
        if (!submittedEmail || ![submittedEmail.address isEqualToString:submittedEmailCell.settingTextField.text]) {
            submittedEmail = [[MXC3PID alloc] initWithMedium:kMX3PIDMediumEmail andAddress:submittedEmailCell.settingTextField.text];
        }
        
        submittedEmailCell.settingButton.enabled = NO;
        [submittedEmail requestValidationToken:^{
            // Reset email field
            submittedEmailCell.settingTextField.text = nil;
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            NSLog(@"[SettingsVC] Failed to request email token: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
            submittedEmailCell.settingButton.enabled = YES;
        }];
    } else if (sender == emailTokenCell.settingButton) {
        emailTokenCell.settingButton.enabled = NO;
        [submittedEmail validateWithToken:emailTokenCell.settingTextField.text success:^(BOOL success) {
            if (success) {
                // The email has been "Authenticated"
                // Link the email with user's account
                MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
                [submittedEmail bindWithUserId:mxHandler.userId success:^{
                    // Add new linked email
                    if (!linkedEmails) {
                        linkedEmails = [NSMutableArray array];
                    }
                    [linkedEmails addObject:submittedEmail.address];
                    
                    // Release pending email and refresh table to remove related cell
                    submittedEmail = nil;
                    [self.tableView reloadData];
                } failure:^(NSError *error) {
                    NSLog(@"[SettingsVC] Failed to link email: %@", error);
                    //Alert user
                    [[AppDelegate theDelegate] showErrorAsAlert:error];
                    
                    // Release the pending email (even if it is Authenticated)
                    submittedEmail = nil;
                    [self.tableView reloadData];
                }];
            } else {
                NSLog(@"[SettingsVC] Failed to link email");
                MXKAlert *alert = [[MXKAlert alloc] initWithTitle:nil message:@"Failed to link email"  style:MXKAlertStyleAlert];
                [alertsArray addObject:alert];
                alert.cancelButtonIndex = [alert addActionWithTitle:@"OK" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
                    [alertsArray removeObject:alert];
                }];
                [alert showInViewController:self];
                // Reset wrong token
                emailTokenCell.settingTextField.text = nil;
            }
        } failure:^(NSError *error) {
            NSLog(@"[SettingsVC] Failed to submit email token: %@", error);
            //Alert user
            [[AppDelegate theDelegate] showErrorAsAlert:error];
            emailTokenCell.settingButton.enabled = YES;
        }];
    } else if (sender == apnsNotificationsSwitch) {
        [APNSHandler sharedHandler].isActive = apnsNotificationsSwitch.on;
        apnsNotificationsSwitch.enabled = NO;
    } else if (sender == inAppNotificationsSwitch) {
        [AppSettings sharedSettings].enableInAppNotifications = inAppNotificationsSwitch.on;
        [self.tableView reloadData];
    } else if (sender == allEventsSwitch) {
        [AppSettings sharedSettings].displayAllEvents = allEventsSwitch.on;
    } else if (sender == redactionsSwitch) {
        [AppSettings sharedSettings].hideRedactions = redactionsSwitch.on;
    } else if (sender == unsupportedEventsSwitch) {
        [AppSettings sharedSettings].hideUnsupportedEvents = unsupportedEventsSwitch.on;
    } else if (sender == sortMembersSwitch) {
        [AppSettings sharedSettings].sortMembersUsingLastSeenTime = sortMembersSwitch.on;
    } else if (sender == displayLeftMembersSwitch) {
        [AppSettings sharedSettings].displayLeftUsers = displayLeftMembersSwitch.on;
    } else if (sender == contactsSyncSwitch) {
    	[AppSettings sharedSettings].syncLocalContacts = contactsSyncSwitch.on;
        isSelectingCountryCode = NO;
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.tableView reloadData];
         });
    }
}

- (IBAction)onSliderValueChange:(id)sender {
    if (sender == maxCacheSizeCell.settingSlider) {
        
        MatrixSDKHandler* mxHandler = [MatrixSDKHandler sharedHandler];
        UISlider* slider = maxCacheSizeCell.settingSlider;
        
        // check if the upper bounds have been updated
        if (slider.maximumValue != mxHandler.maxAllowedCachesSize) {
            slider.maximumValue = mxHandler.maxAllowedCachesSize;
        }
        
        // check if the value does not exceed the bounds
        if (slider.value < minimumCacheSize) {
            slider.value = minimumCacheSize;
        }
        
        [[MatrixSDKHandler sharedHandler] setCurrentMaxCachesSize:slider.value];
        
        maxCacheSizeCell.settingLabel.text = [NSString stringWithFormat:@"Maximum cache size (%@)", [NSByteCountFormatter stringFromByteCount:mxHandler.currentMaxCachesSize countStyle:NSByteCountFormatterCountStyleFile]];
    }
}

#pragma mark - keyboard

- (void)dismissKeyboard {
    if ([_userDisplayName isFirstResponder]) {
        // Hide the keyboard
        [_userDisplayName resignFirstResponder];
        [self updateSaveUserInfoButtonStatus];
    } else if ([submittedEmailCell.settingTextField isFirstResponder]) {
        [submittedEmailCell.settingTextField resignFirstResponder];
    } else if ([emailTokenCell.settingTextField isFirstResponder]) {
        [emailTokenCell.settingTextField resignFirstResponder];
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    // "Done" key has been pressed
    [self dismissKeyboard];
    return YES;
}

- (IBAction)textFieldDidChange:(id)sender {
    if (sender == _userDisplayName) {
        [self updateSaveUserInfoButtonStatus];
    } else if (sender == submittedEmailCell.settingTextField) {
        submittedEmailCell.settingButton.enabled = (submittedEmailCell.settingTextField.text.length != 0);
    } else if (sender == emailTokenCell.settingTextField) {
        emailTokenCell.settingButton.enabled = (emailTokenCell.settingTextField.text.length != 0);
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (section == SETTINGS_SECTION_LINKED_EMAILS_INDEX) {
        submittedEmailRowIndex = emailTokenRowIndex = -1;
        
        count = linkedEmails.count;
        submittedEmailRowIndex = count++;
        if (submittedEmail && submittedEmail.validationState >= MXC3PIDAuthStateTokenReceived) {
            emailTokenRowIndex = count++;
        } else {
            emailTokenCell = nil;
        }
    } else if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        enableInAppNotifRowIndex = enablePushNotifRowIndex = userInfoNotifRowIndex = -1;
        
        if ([APNSHandler sharedHandler].isAvailable) {
            enablePushNotifRowIndex = count++;
        }
        enableInAppNotifRowIndex = count++;
        userInfoNotifRowIndex = count++;
    } else if (section == SETTINGS_SECTION_CONTACTS_INDEX) {
        countryCodeRowIndex = syncLocalContactsRowIndex = -1;

        // init row index
        syncLocalContactsRowIndex = count++;
        if ([[AppSettings sharedSettings] syncLocalContacts]) {
            countryCodeRowIndex = count++;
        }
    } else if (section == SETTINGS_SECTION_ROOMS_INDEX) {
        count = SETTINGS_SECTION_ROOMS_INDEX_COUNT;
    } else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        count = 1;
    } else if (section == SETTINGS_SECTION_COMMANDS_INDEX) {
        count = 1;
    }
    
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SETTINGS_SECTION_LINKED_EMAILS_INDEX) {
        if (indexPath.row == emailTokenRowIndex) {
            return 70;
        }
        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        if (indexPath.row == userInfoNotifRowIndex) {
            UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
            textView.font = [UIFont systemFontOfSize:14];
            textView.text = kUserInfoNotificationRulesText;
            CGSize contentSize = [textView sizeThatFits:textView.frame.size];
            return contentSize.height + 1;
        }
        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX) {
        
        if ((indexPath.row == countryCodeRowIndex) && isSelectingCountryCode) {
            
            return 164;
        }
        
        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) {
        if (indexPath.row == SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX) {
            return 88;
        }
        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
        textView.font = [UIFont systemFontOfSize:14];
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        if (build.length) {
            build = [NSString stringWithFormat:kBuildFormatText, build];
        }
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        textView.text = [NSString stringWithFormat:kConfigurationFormatText, appVersion, MatrixSDKVersion, build, mxHandler.homeServerURL, mxHandler.identityServerURL, mxHandler.userId];
        CGSize contentSize = [textView sizeThatFits:textView.frame.size];
        return contentSize.height + 1;
    } else if (indexPath.section == SETTINGS_SECTION_COMMANDS_INDEX) {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
        textView.font = [UIFont systemFontOfSize:14];
        textView.text = kCommandsDescriptionText;
        CGSize contentSize = [textView sizeThatFits:textView.frame.size];
        return contentSize.height + 1;
    }
    
    return 44;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}
- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *sectionHeader = [[UILabel alloc] initWithFrame:[tableView rectForHeaderInSection:section]];
    sectionHeader.font = [UIFont boldSystemFontOfSize:16];
    sectionHeader.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    
    if (section == SETTINGS_SECTION_LINKED_EMAILS_INDEX) {
        sectionHeader.text = @" Linked emails";
    } else if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        sectionHeader.text = @" Notifications";
    } else if (section == SETTINGS_SECTION_CONTACTS_INDEX) {
        sectionHeader.text = @" Contacts";
    } else if (section == SETTINGS_SECTION_ROOMS_INDEX) {
        sectionHeader.text = @" Rooms";
    } else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        sectionHeader.text = @" Configuration";
    } else if (section == SETTINGS_SECTION_COMMANDS_INDEX) {
        sectionHeader.text = @" Commands";
    } else {
        sectionHeader = nil;
    }
    return sectionHeader;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    UITableViewCell *cell = nil;
    
    if (indexPath.section == SETTINGS_SECTION_LINKED_EMAILS_INDEX) {
        if (indexPath.row < linkedEmails.count) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LinkedEmailCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LinkedEmailCell"];
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.text = [linkedEmails objectAtIndex:indexPath.row];
        } else if (indexPath.row == submittedEmailRowIndex) {
            // Report the current email value (if any)
            NSString *currentEmail = nil;
            if (submittedEmailCell) {
                currentEmail = submittedEmailCell.settingTextField.text;
            }
            submittedEmailCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextFieldAndButton" forIndexPath:indexPath];
            submittedEmailCell.settingTextField.text = currentEmail;
            submittedEmailCell.settingButton.enabled = (currentEmail.length != 0);
            [submittedEmailCell.settingButton setTitle:@"Link Email" forState:UIControlStateNormal];
            [submittedEmailCell.settingButton setTitle:@"Link Email" forState:UIControlStateHighlighted];
            if (emailTokenRowIndex != -1) {
                // Hide the separator
                CGSize screenSize = [[UIScreen mainScreen] bounds].size;
                CGFloat rightInset = (screenSize.width < screenSize.height) ? screenSize.height : screenSize.width;
                submittedEmailCell.separatorInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, rightInset);
            }
            cell = submittedEmailCell;
        } else if (indexPath.row == emailTokenRowIndex) {
            // Report the current token value (if any)
            NSString *currentToken = nil;
            if (emailTokenCell) {
                currentToken = emailTokenCell.settingTextField.text;
            }
            emailTokenCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithLabelTextFieldAndButton" forIndexPath:indexPath];
            emailTokenCell.settingLabel.text = [NSString stringWithFormat:@"Enter validation token for %@:", submittedEmail.address];
            emailTokenCell.settingTextField.text = currentToken;
            emailTokenCell.settingButton.enabled = (currentToken.length != 0);
            [emailTokenCell.settingButton setTitle:@"Submit code" forState:UIControlStateNormal];
            [emailTokenCell.settingButton setTitle:@"Submit code" forState:UIControlStateHighlighted];
            cell = emailTokenCell;
        }
    } else if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        if (indexPath.row == userInfoNotifRowIndex) {
            SettingsCellWithTextView *userInfoCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
            userInfoCell.settingTextView.text = kUserInfoNotificationRulesText;
            cell = userInfoCell;
        } else {
            SettingsCellWithSwitch *notificationsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            if (indexPath.row == enableInAppNotifRowIndex) {
                notificationsCell.settingLabel.text = @"Enable In-App notifications";
                notificationsCell.settingSwitch.on = [[AppSettings sharedSettings] enableInAppNotifications];
                inAppNotificationsSwitch = notificationsCell.settingSwitch;
            } else /* enablePushNotifRowIndex */{
                notificationsCell.settingLabel.text = @"Enable push notifications";
                notificationsCell.settingSwitch.on = [[APNSHandler sharedHandler] isActive];
                notificationsCell.settingSwitch.enabled = YES;
                apnsNotificationsSwitch = notificationsCell.settingSwitch;
            }
            cell = notificationsCell;
        }
    } else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX) {
        if (indexPath.row  == syncLocalContactsRowIndex) {
            SettingsCellWithSwitch *contactsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            
            contactsCell.settingLabel.text = @"Sync local contacts";
            contactsCell.settingSwitch.on = [[AppSettings sharedSettings] syncLocalContacts];
            contactsSyncSwitch = contactsCell.settingSwitch;
            cell = contactsCell;
        } else if (indexPath.row  == countryCodeRowIndex) {
            
            int index = 0;
            NSString* countryName = @"";
            
            for(NSDictionary* dict in countryCodes) {
                if ([[dict valueForKey:@"id"] isEqualToString:selectedCountryCode]) {
                    countryName = [dict valueForKey:@"country"];
                    break;
                }
                
                index++;
            }
        
            // there is no country code selection
            if (!isSelectingCountryCode) {
                SettingsCellWithLabelAndSubLabel *countryCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithLabelAndSubLabel" forIndexPath:indexPath];
               
                countryCell.label.text = @"Select your country";
                countryCell.sublabel.text = countryName;
                countryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell = countryCell;
                
            } else {
                // there is a selection in progress
                SettingsCellWithPicker *pickerCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithPicker" forIndexPath:indexPath];
                
                // display a picker
                pickerCell.pickerView.delegate = self;
                pickerCell.pickerView.dataSource = self;
                
                if (countryName.length > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [pickerCell.pickerView selectRow:index inComponent:0 animated:NO];
                    });
                }
                
                cell = pickerCell;
            }
        }
        
    } else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) {
        if (indexPath.row == SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ClearCacheCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ClearCacheCell"];
            }
            cell.textLabel.text = [NSString stringWithFormat:@"Clear Cache (%@)", [NSByteCountFormatter stringFromByteCount:mxHandler.cachesSize countStyle:NSByteCountFormatterCountStyleFile]];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor =  [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor;
        } else if (indexPath.row == SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX) {
            maxCacheSizeCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithLabelAndSilder" forIndexPath:indexPath];
            maxCacheSizeCell.settingSlider.minimumValue = 0;
            maxCacheSizeCell.settingSlider.maximumValue = mxHandler.maxAllowedCachesSize;
            maxCacheSizeCell.settingSlider.value = mxHandler.currentMaxCachesSize;
            
            [self onSliderValueChange:maxCacheSizeCell.settingSlider];
            cell = maxCacheSizeCell;
        } else {
            SettingsCellWithSwitch *roomsSettingCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            
            if (indexPath.row == SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Display all events";
                roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] displayAllEvents];
                allEventsSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_HIDE_REDACTIONS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Hide redactions";
                roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] hideRedactions];
                redactionsSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_HIDE_UNSUPPORTED_EVENTS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Hide unsupported events";
                roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] hideUnsupportedEvents];
                unsupportedEventsSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_SORT_MEMBERS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Sort members by last seen time";
                roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] sortMembersUsingLastSeenTime];
                sortMembersSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_DISPLAY_LEFT_MEMBERS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Display left members";
                roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] displayLeftUsers];
                displayLeftMembersSwitch = roomsSettingCell.settingSwitch;
            }
            
            cell = roomsSettingCell;
        }
    } else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        SettingsCellWithTextView *configurationCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        NSString* appVersion = [AppDelegate theDelegate].appVersion;
        NSString* build = [AppDelegate theDelegate].build;
        if (build.length) {
            build = [NSString stringWithFormat:kBuildFormatText, build];
        }
        configurationCell.settingTextView.text = [NSString stringWithFormat:kConfigurationFormatText, appVersion, MatrixSDKVersion, build, mxHandler.homeServerURL, mxHandler.identityServerURL, mxHandler.userId];
        cell = configurationCell;
    } else if (indexPath.section == SETTINGS_SECTION_COMMANDS_INDEX) {
        SettingsCellWithTextView *commandsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        commandsCell.settingTextView.text = kCommandsDescriptionText;
        cell = commandsCell;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView == aTableView) {
        // tap on clear application cache
        if ((indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) && (indexPath.row == SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX)) {
            // clear caches
            [[MatrixSDKHandler sharedHandler] reload:YES];
        }
        else if (indexPath.section == SETTINGS_SECTION_CONTACTS_INDEX) {
            
            if (indexPath.row == countryCodeRowIndex) {
                isSelectingCountryCode = YES;

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }

        }
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

# pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (selectedImage) {
        [self updateUserPictureButton:selectedImage];
        isAvatarUpdated = YES;
        _saveUserInfoButton.enabled = YES;
    }
    [self dismissMediaPicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissMediaPicker];
}

- (void)dismissMediaPicker {
    [[AppDelegate theDelegate].masterTabBarController dismissMediaPicker];
}


#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [countryCodes count];
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[countryCodes objectAtIndex:row] valueForKey:@"country"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    // sanity check
    if ((row >= 0) && (row < countryCodes.count)) {
        NSDictionary* dict = [countryCodes objectAtIndex:row];
        selectedCountryCode = [dict valueForKey:@"id"];
    }
    
    isSelectingCountryCode = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

@end
