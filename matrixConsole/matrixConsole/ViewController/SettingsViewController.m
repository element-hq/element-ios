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

#import "SettingsTableViewCell.h"

#define SETTINGS_SECTION_LINKED_EMAILS_INDEX 0
#define SETTINGS_SECTION_NOTIFICATIONS_INDEX 1
#define SETTINGS_SECTION_ROOMS_INDEX         2
#define SETTINGS_SECTION_CONFIGURATION_INDEX 3
#define SETTINGS_SECTION_COMMANDS_INDEX      4
#define SETTINGS_SECTION_COUNT               5

#define SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX         0
#define SETTINGS_SECTION_ROOMS_HIDE_UNSUPPORTED_MESSAGES_INDEX  1
#define SETTINGS_SECTION_ROOMS_SORT_MEMBERS_INDEX               2
#define SETTINGS_SECTION_ROOMS_DISPLAY_LEFT_MEMBERS_INDEX       3
#define SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX             4
#define SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX                5
#define SETTINGS_SECTION_ROOMS_INDEX_COUNT                      6

NSString* const kConfigurationFormatText = @"matrixConsole version: %@\r\nSDK version: %@\r\n\r\nHome server: %@\r\nIdentity server: %@\r\nUser ID: %@\r\nAccess token: %@";
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
    SettingsCellWithTextFieldAndButton* linkedEmailCell;
    SettingsCellWithLabelTextFieldAndButton* emailTokenCell;
    // Dynamic rows in the Linked emails section
    int submittedEmailRowIndex;
    int emailTokenRowIndex;
    
    // Notifications
    UISwitch *apnsNotificationsSwitch;
    UISwitch *inAppNotificationsSwitch;
    SettingsCellWithLabelAndTextField* inAppNotificationsRulesCell;
    // Dynamic rows in the Notifications section
    int enablePushNotifRowIndex;
    int enableInAppNotifRowIndex;
    int inAppNotifRulesRowIndex;
    
    // Rooms settings
    UISwitch *allEventsSwitch;
    UISwitch *unsupportedMsgSwitch;
    UISwitch *sortMembersSwitch;
    UISwitch *displayLeftMembersSwitch;
    SettingsCellWithLabelAndSlider* maxCacheSizeCell;
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
    [[MatrixSDKHandler sharedHandler] addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    isAvatarUpdated = NO;
    isSavingInProgress = NO;
    
    _saveUserInfoButton.enabled = NO;
    _activityIndicatorBackgroundView.hidden = YES;
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
    apnsNotificationsSwitch = nil;
    inAppNotificationsSwitch = nil;
    allEventsSwitch = nil;
    unsupportedMsgSwitch = nil;
    sortMembersSwitch = nil;
    displayLeftMembersSwitch = nil;
    
    inAppNotificationsRulesCell = nil;
    linkedEmailCell = nil;
    emailTokenCell = nil;
    maxCacheSizeCell = nil;
    [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Refresh display
    [self startActivityIndicator];
    [self configureView];
    [[MatrixSDKHandler sharedHandler] addObserver:self forKeyPath:@"isResumeDone" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAPNSHandlerHasBeenUpdated) name:kAPNSHandlerHasBeenUpdated object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MatrixSDKHandler sharedHandler] removeObserver:self forKeyPath:@"isResumeDone"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAPNSHandlerHasBeenUpdated object:nil];
}

- (BOOL)shouldLeave:(blockSettings_onReadyToLeave)handler {
    // Check whether some local changes have not been saved
    if (_saveUserInfoButton.enabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MXCAlert *alert = [[MXCAlert alloc] initWithTitle:nil message:@"Changes will be discarded"  style:MXCAlertStyleAlert];
            [alertsArray addObject:alert];
            alert.cancelButtonIndex = [alert addActionWithTitle:@"Discard" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                [alertsArray removeObject:alert];
                // Discard changes
                self.userDisplayName.text = currentDisplayName;
                [self updateUserPicture:[MatrixSDKHandler sharedHandler].mxSession.myUser.avatarUrl force:YES];
                // Ready to leave
                if (handler) {
                    handler();
                }
            }];
            [alert addActionWithTitle:@"Save" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
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
    for (MXCAlert *alert in alertsArray){
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
            
            [self stopActivityIndicator];
            
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
    } else if (mxHandler.status == MatrixSDKHandlerStatusStoreDataReady) {
        // Set local user's information (the data may not be up-to-date)
        [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl force:NO];
        currentDisplayName = mxHandler.mxSession.myUser.displayname;
        self.userDisplayName.text = currentDisplayName;
    } else if (mxHandler.status == MatrixSDKHandlerStatusLoggedOut) {
        [self reset];
    }
    
    if ([mxHandler isResumeDone]) {
        [self stopActivityIndicator];
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
            NSLog(@"Set displayName failed: %@", error);
            //Alert user
            NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
            if (!title) {
                title = @"Display name change failed";
            }
            NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
            
            MXCAlert *alert = [[MXCAlert alloc] initWithTitle:title message:msg style:MXCAlertStyleAlert];
            [alertsArray addObject:alert];
            alert.cancelButtonIndex = [alert addActionWithTitle:@"Abort" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
                [alertsArray removeObject:alert];
                // Discard changes
                self.userDisplayName.text = currentDisplayName;
                [self updateUserPicture:[MatrixSDKHandler sharedHandler].mxSession.myUser.avatarUrl force:YES];
                // Loop to end saving
                [self saveUserInfo];
            }];
            [alert addActionWithTitle:@"Retry" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
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
            // Upload picture
            MediaLoader *uploader = [[MediaLoader alloc] initWithUploadId:nil initialRange:0 andRange:1.0 folder:kMediaManagerThumbnailFolder];
            [uploader uploadData:UIImageJPEGRepresentation([self.userPictureButton imageForState:UIControlStateNormal], 0.5) mimeType:@"image/jpeg" success:^(NSString *url) {
                // Store uploaded picture url and trigger picture saving
                uploadedPictureURL = url;
                [self saveUserInfo];
            } failure:^(NSError *error) {
                NSLog(@"Upload image failed: %@", error);
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
                                                 NSLog(@"Set avatar url failed: %@", error);
                                                 [self handleErrorDuringPictureSaving:error];
                                             }];
        }
        return;
    }
    
    // Backup is complete
    isSavingInProgress = NO;
    // Stop animation (except if the app is resuming)
    if ([[MatrixSDKHandler sharedHandler] isResumeDone]) {
        [self stopActivityIndicator];
    }
}

- (void)handleErrorDuringPictureSaving:(NSError*)error {
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title) {
        title = @"Picture change failed";
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    MXCAlert *alert = [[MXCAlert alloc] initWithTitle:title message:msg style:MXCAlertStyleAlert];
    [alertsArray addObject:alert];
    alert.cancelButtonIndex = [alert addActionWithTitle:@"Abort" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
        [alertsArray removeObject:alert];
        // Remove change
        self.userDisplayName.text = currentDisplayName;
        [self updateUserPicture:[MatrixSDKHandler sharedHandler].mxSession.myUser.avatarUrl force:YES];
        // Loop to end saving
        [self saveUserInfo];
    }];
    [alert addActionWithTitle:@"Retry" style:MXCAlertActionStyleDefault handler:^(MXCAlert *alert) {
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

// remove trailing spaces
- (NSString*)removeUselessSpaceChars:(NSString*)text {
    NSMutableString* cleanedText = [text mutableCopy];
    
    while ([cleanedText hasPrefix:@" "]) {
        cleanedText = [[cleanedText substringFromIndex:1] mutableCopy];
    }
    
    while ([cleanedText hasSuffix:@" "]) {
        cleanedText = [[cleanedText substringToIndex:cleanedText.length-1] mutableCopy];
    }
    
    return cleanedText;
}

// split the words list provided by the user
// check if they are valid, not duplicated
- (void)manageWordsList {
    NSArray* words = [inAppNotificationsRulesCell.settingTextField.text componentsSeparatedByString:@","];
    NSMutableArray* fiteredWords = [[NSMutableArray alloc] init];
    MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
    
    // theses both items are implicitly checked
    NSString* displayname = nil;
    if (mxHandler.mxSession.myUser.displayname.length) {
        displayname = mxHandler.mxSession.myUser.displayname;
    }
    
    NSString* userID = nil;
    if (mxHandler.localPartFromUserId.length) {
        userID = mxHandler.localPartFromUserId;
    }
    
    // checked word by word
    for(NSString* word in words) {
        NSString* cleanWord = [self removeUselessSpaceChars:word];
        
        // if they are valid (not null, not implicit and does not already added
        if ((cleanWord.length > 0) && ![cleanWord isEqualToString:displayname] && ![cleanWord isEqualToString:userID] && ([fiteredWords indexOfObject:cleanWord] == NSNotFound)) {
            [fiteredWords addObject:cleanWord];
        }
    }
    
    [[AppSettings sharedSettings] setSpecificWordsToAlertOn:fiteredWords];
    [self refreshWordsList];
}

- (void)refreshWordsList {
    NSMutableString* wordsList = [[NSMutableString alloc] init];
    NSArray* patterns = [AppSettings sharedSettings].specificWordsToAlertOn;
    
    for (NSString* string in patterns) {
        [wordsList appendFormat:@"%@,", string];
    }
    
    if (wordsList.length > 0) {
        inAppNotificationsRulesCell.settingTextField.text = [wordsList substringToIndex:wordsList.length - 1];
    }
    else {
        inAppNotificationsRulesCell.settingTextField.text = nil;
    }
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
    } else if ([@"isResumeDone" isEqualToString:keyPath]) {
        if ([[MatrixSDKHandler sharedHandler] isResumeDone] && !isSavingInProgress) {
            [self stopActivityIndicator];
        } else {
            [self startActivityIndicator];
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
    } else if (sender == linkedEmailCell.settingButton) {
        // FIXME
        NSLog(@"link email is not supported yet (%@)", linkedEmailCell.settingTextField.text);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"link is not supported yet" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        linkedEmailCell.settingTextField.text = nil;
        linkedEmailCell.settingButton.enabled = NO;
    } else if (sender == apnsNotificationsSwitch) {
        [APNSHandler sharedHandler].isActive = apnsNotificationsSwitch.on;
    } else if (sender == inAppNotificationsSwitch) {
        [AppSettings sharedSettings].enableInAppNotifications = inAppNotificationsSwitch.on;
        [self.tableView reloadData];
    } else if (sender == allEventsSwitch) {
        [AppSettings sharedSettings].displayAllEvents = allEventsSwitch.on;
    } else if (sender == unsupportedMsgSwitch) {
        [AppSettings sharedSettings].hideUnsupportedMessages = unsupportedMsgSwitch.on;
    } else if (sender == sortMembersSwitch) {
        [AppSettings sharedSettings].sortMembersUsingLastSeenTime = sortMembersSwitch.on;
    } else if (sender == displayLeftMembersSwitch) {
        [AppSettings sharedSettings].displayLeftUsers = displayLeftMembersSwitch.on;
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
        if (slider.value < mxHandler.minCachesSize) {
            slider.value = mxHandler.minCachesSize;
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
    } else if (inAppNotificationsRulesCell && [inAppNotificationsRulesCell.settingTextField isFirstResponder]) {
        [self manageWordsList];
        [inAppNotificationsRulesCell.settingTextField resignFirstResponder];
    } else if ([linkedEmailCell.settingTextField isFirstResponder]) {
        [linkedEmailCell.settingTextField resignFirstResponder];
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
    } else if (sender == linkedEmailCell.settingTextField) {
        linkedEmailCell.settingButton.enabled = (linkedEmailCell.settingTextField.text.length != 0);
    }
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SETTINGS_SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SETTINGS_SECTION_LINKED_EMAILS_INDEX) {
        return linkedEmails.count + 1;
    } else if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        
        enableInAppNotifRowIndex = inAppNotifRulesRowIndex = enablePushNotifRowIndex = -1;
        
        int count = 0;
        if ([APNSHandler sharedHandler].isAvailable) {
            enablePushNotifRowIndex = count++;
        }
        
        enableInAppNotifRowIndex = count++;
        if ([[AppSettings sharedSettings] enableInAppNotifications]) {
            inAppNotifRulesRowIndex = count++;
        }
        
        return count;
    } else if (section == SETTINGS_SECTION_ROOMS_INDEX) {
        return SETTINGS_SECTION_ROOMS_INDEX_COUNT;
    } else if (section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        return 1;
    } else if (section == SETTINGS_SECTION_COMMANDS_INDEX) {
        return 1;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SETTINGS_SECTION_LINKED_EMAILS_INDEX) {
        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        if (indexPath.row == inAppNotifRulesRowIndex) {
            return 110;
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
        NSString* appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        textView.text = [NSString stringWithFormat:kConfigurationFormatText, appVersion, MatrixSDKVersion, mxHandler.homeServerURL, nil, mxHandler.userId, mxHandler.accessToken];
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
    UITableViewCell *cell = nil;
    
    if (indexPath.section == SETTINGS_SECTION_LINKED_EMAILS_INDEX) {
        // Report the current email value (if any)
        NSString *currentEmail = nil;
        if (linkedEmailCell) {
            currentEmail = linkedEmailCell.settingTextField.text;
        }
        linkedEmailCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextFieldAndButton" forIndexPath:indexPath];
        linkedEmailCell.settingTextField.text = currentEmail;
        linkedEmailCell.settingButton.enabled = (currentEmail.length != 0);
        cell = linkedEmailCell;
    } else if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        if (indexPath.row == inAppNotifRulesRowIndex) {
            // Report the current email value (if any)
            NSString *currentRules = nil;
            BOOL isFirstResponder = NO;
            if (inAppNotificationsRulesCell) {
                currentRules = inAppNotificationsRulesCell.settingTextField.text;
                isFirstResponder = inAppNotificationsRulesCell.settingTextField.isFirstResponder;
            }
            inAppNotificationsRulesCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithLabelAndTextField" forIndexPath:indexPath];
            inAppNotificationsRulesCell.settingLabel.text = @"If blank, all messages will trigger an alert.Your username & display name always alerts.";
            inAppNotificationsRulesCell.settingTextField.text = currentRules;
            
            // If the current rules are empty, reload rules from settings except if the textField was the first responder
            if (!currentRules.length && !isFirstResponder) {
                [self refreshWordsList];
            }
        
            cell = inAppNotificationsRulesCell;
        } else {
            SettingsCellWithSwitch *notificationsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            if (indexPath.row == enableInAppNotifRowIndex) {
                notificationsCell.settingLabel.text = @"Enable In-App notifications";
                notificationsCell.settingSwitch.on = [[AppSettings sharedSettings] enableInAppNotifications];
                inAppNotificationsSwitch = notificationsCell.settingSwitch;
            } else /* SETTINGS_SECTION_NOTIFICATIONS_PUSH_NOTIFICATION_INDEX */{
                notificationsCell.settingLabel.text = @"Enable push notifications";
                notificationsCell.settingSwitch.on = [[APNSHandler sharedHandler] isActive];
                apnsNotificationsSwitch = notificationsCell.settingSwitch;
            }
            cell = notificationsCell;
        }
    } else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) {
        if (indexPath.row == SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ClearCacheCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ClearCacheCell"];
            }
            
            cell.textLabel.text = [NSString stringWithFormat:@"Clear cache (%@)", [NSByteCountFormatter stringFromByteCount:[MatrixSDKHandler sharedHandler].cachesSize countStyle:NSByteCountFormatterCountStyleFile]];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor =  [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor;
        } else if (indexPath.row == SETTINGS_SECTION_ROOMS_SET_CACHE_SIZE_INDEX) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithLabelAndSilder" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            maxCacheSizeCell = (SettingsCellWithLabelAndSlider*)cell;
            
            maxCacheSizeCell.settingSlider.minimumValue = 0;
            maxCacheSizeCell.settingSlider.value = [MatrixSDKHandler sharedHandler].currentMaxCachesSize;
            
            [self onSliderValueChange:maxCacheSizeCell.settingSlider];
        
        } else {
            SettingsCellWithSwitch *roomsSettingCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            
            if (indexPath.row == SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX) {
                roomsSettingCell.settingLabel.text = @"Display all events";
                roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] displayAllEvents];
                allEventsSwitch = roomsSettingCell.settingSwitch;
            } else if (indexPath.row == SETTINGS_SECTION_ROOMS_HIDE_UNSUPPORTED_MESSAGES_INDEX) {
                roomsSettingCell.settingLabel.text = @"Hide unsupported messages";
                roomsSettingCell.settingSwitch.on = [[AppSettings sharedSettings] hideUnsupportedMessages];
                unsupportedMsgSwitch = roomsSettingCell.settingSwitch;
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
        SettingsCellWithTextView *configCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        NSString* appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        MatrixSDKHandler *mxHandler = [MatrixSDKHandler sharedHandler];
        configCell.settingTextView.text = [NSString stringWithFormat:kConfigurationFormatText, appVersion, MatrixSDKVersion, mxHandler.homeServerURL, nil, mxHandler.userId, mxHandler.accessToken];
        cell = configCell;
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
            [[MatrixSDKHandler sharedHandler] forceInitialSync:YES];
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

@end
