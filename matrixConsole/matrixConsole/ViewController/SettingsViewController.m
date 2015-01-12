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
#import "MatrixHandler.h"
#import "MediaManager.h"

#import "SettingsTableViewCell.h"

#define SETTINGS_SECTION_NOTIFICATIONS_INDEX 0
#define SETTINGS_SECTION_ROOMS_INDEX         1
#define SETTINGS_SECTION_CONFIGURATION_INDEX 2
#define SETTINGS_SECTION_COMMANDS_INDEX      3

#define SETTINGS_SECTION_ROOMS_DISPLAY_ALL_EVENTS_INDEX         0
#define SETTINGS_SECTION_ROOMS_HIDE_UNSUPPORTED_MESSAGES_INDEX  1
#define SETTINGS_SECTION_ROOMS_SORT_MEMBERS_INDEX               2
#define SETTINGS_SECTION_ROOMS_DISPLAY_LEFT_MEMBERS_INDEX       3
#define SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX                4
#define SETTINGS_SECTION_ROOMS_INDEX_COUNT                      5

NSString* const kConfigurationFormatText = @"Home server: %@\r\nIdentity server: %@\r\nUser ID: %@\r\nAccess token: %@";
NSString* const kCommandsDescriptionText = @"The following commands are available in the room chat:\r\n\r\n /nick <display_name>: change your display name\r\n /me <action>: send the action you are doing. /me will be replaced by your display name\r\n /join <room_alias>: join a room\r\n /kick <user_id> [<reason>]: kick the user\r\n /ban <user_id> [<reason>]: ban the user\r\n /unban <user_id>: unban the user\r\n /op <user_id> <power_level>: set user power level\r\n /deop <user_id>: reset user power level to the room default value";

@interface SettingsViewController () {
    MediaLoader *imageLoader;
    
    NSString *currentDisplayName;
    NSString *currentPictureURL;
    NSString *uploadedPictureURL;
    
    // Listen user's settings change
    id userUpdateListener;
    
    NSMutableArray *errorAlerts;
    
    UIButton *logoutBtn;
    UISwitch *apnsNotificationsSwitch;
    UISwitch *inAppNotificationsSwitch;
    UISwitch *allEventsSwitch;
    UISwitch *unsupportedMsgSwitch;
    UISwitch *sortMembersSwitch;
    UISwitch *displayLeftMembersSwitch;
    
    // user info update
    BOOL isAvatarUpdated;
    BOOL isDisplayNameUpdated;
    
    // do not hide the spinner while switching between viewcontroller
    BOOL isAvatarUploading;
    BOOL isDisplayNameUploading;

    //
    UITextField* wordsListTextField;
    
    // dynamic rows in the notification settings
    int enableInAppRowIndex;
    int setInAppWordRowIndex;
    int enablePushNotificationdRowIndex;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableHeader;
@property (weak, nonatomic) IBOutlet UIButton *userPicture;
@property (weak, nonatomic) IBOutlet UITextField *userDisplayName;
@property (weak, nonatomic) IBOutlet UIButton *saveUserInfoButton;
@property (strong, nonatomic) IBOutlet UIView *activityIndicatorBackgroundView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) CustomAlert* customAlert;

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
    [[self.userPicture imageView] setContentMode: UIViewContentModeScaleAspectFill];
    [[self.userPicture imageView] setClipsToBounds:YES];
    
    errorAlerts = [NSMutableArray array];
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    isAvatarUpdated = NO;
    isDisplayNameUpdated = NO;
    
    isAvatarUploading = NO;
    isDisplayNameUploading = NO;
    
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
    
    errorAlerts = nil;
    
    logoutBtn = nil;
    apnsNotificationsSwitch = nil;
    inAppNotificationsSwitch = nil;
    allEventsSwitch = nil;
    unsupportedMsgSwitch = nil;
    sortMembersSwitch = nil;
    displayLeftMembersSwitch = nil;
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"status"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Refresh display
    [self startUserInfoUploadAnimation];
    [self configureView];
    [[MatrixHandler sharedHandler] addObserver:self forKeyPath:@"isResumeDone" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAPNSHandlerHasBeenUpdated) name:kAPNSHandlerHasBeenUpdated object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MatrixHandler sharedHandler] removeObserver:self forKeyPath:@"isResumeDone"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAPNSHandlerHasBeenUpdated object:nil];
}

- (BOOL)checkPendingSave:(blockSettings_onCheckSave)handler {
    // there is a profile update and there is no pending update
    if ((isAvatarUpdated || isDisplayNameUpdated) && (!isDisplayNameUploading) && (!isAvatarUploading)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __weak typeof(self) weakSelf = self;
            
            self.customAlert  = [[CustomAlert alloc] initWithTitle:nil message:@"Save profile update" style:CustomAlertStyleAlert];
            self.customAlert.cancelButtonIndex = [self.customAlert addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                handler();
                weakSelf.customAlert = nil;
            }];
            
            [self.customAlert addActionWithTitle:@"OK" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                [weakSelf saveDisplayName];
                
                weakSelf.customAlert = nil;
                handler();
            }];
            
            [self.customAlert showInViewController:self];
        });
                       
        return YES;
    }
    return NO;
}

#pragma mark - Internal methods

- (void)onAPNSHandlerHasBeenUpdated {
    // Force table reload to update notifications section
    apnsNotificationsSwitch = nil;
    [self.tableView reloadData];
}

- (void)updateAvatarImage:(UIImage*)image {
    [self.userPicture setImage:image forState:UIControlStateNormal];
    [self.userPicture setImage:image forState:UIControlStateHighlighted];
    [self.userPicture setImage:image forState:UIControlStateDisabled];
}

- (void)reset {
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Cancel picture loader (if any)
    if (imageLoader) {
        [imageLoader cancel];
        imageLoader = nil;
    }
    
    // Cancel potential error alerts
    for (CustomAlert *alert in errorAlerts){
        [alert dismiss:NO];
    }
    
    // Remove listener
    if (userUpdateListener) {
        [[MatrixHandler sharedHandler].mxSession.myUser removeListener:userUpdateListener];
        userUpdateListener = nil;
    }
    
    currentPictureURL = nil;
    uploadedPictureURL = nil;
    
    [self updateAvatarImage:[UIImage imageNamed:@"default-profile"]];
    
    currentDisplayName = nil;
    self.userDisplayName.text = nil;
}

- (void) startUserInfoUploadAnimation {
    if (_activityIndicatorBackgroundView.hidden) {
        _activityIndicatorBackgroundView.hidden = NO;
        [_activityIndicator startAnimating];
    }
    _saveUserInfoButton.enabled = NO;
}

- (void) stopUserInfoUploadAnimation {
    if (!_activityIndicatorBackgroundView.hidden) {
        _activityIndicatorBackgroundView.hidden = YES;
        [_activityIndicator stopAnimating];
    }
    _saveUserInfoButton.enabled = isAvatarUpdated || isDisplayNameUpdated;
}

- (void)configureView {
    // ignore any refresh until there is a pending upload
    if (isDisplayNameUploading || isAvatarUploading) {
        return;
    }
    
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Disable user's interactions
    _userPicture.enabled = NO;
    _userDisplayName.enabled = NO;
    
    if (mxHandler.status == MatrixHandlerStatusServerSyncDone) {
        if (!userUpdateListener) {
            // Set current user's information and add observers
            [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl];
            currentDisplayName = mxHandler.mxSession.myUser.displayname;
            self.userDisplayName.text = currentDisplayName;
            
            [self stopUserInfoUploadAnimation];
            
            // Register listener to update user's information
            userUpdateListener = [mxHandler.mxSession.myUser listenToUserUpdate:^(MXEvent *event) {
                // Update displayName
                if (![currentDisplayName isEqualToString:mxHandler.mxSession.myUser.displayname]) {
                    currentDisplayName = mxHandler.mxSession.myUser.displayname;
                    self.userDisplayName.text = mxHandler.mxSession.myUser.displayname;
                }
                // Update user's avatar
                [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl];
               
                // update button management
                isDisplayNameUpdated = isAvatarUpdated = NO;
                _saveUserInfoButton.enabled = NO;
                
                // TODO display user's presence
            }];
        }
    } else if (mxHandler.status == MatrixHandlerStatusStoreDataReady) {
        // Set local user's information (the data may not be up-to-date)
        [self updateUserPicture:mxHandler.mxSession.myUser.avatarUrl];
        currentDisplayName = mxHandler.mxSession.myUser.displayname;
        self.userDisplayName.text = currentDisplayName;
    } else if (mxHandler.status == MatrixHandlerStatusLoggedOut) {
        [self reset];
    }
    
    if ([mxHandler isResumeDone]) {
        [self stopUserInfoUploadAnimation];
        _userPicture.enabled = YES;
        _userDisplayName.enabled = YES;
    }
    [self.tableView reloadData];
}

- (void)saveDisplayName {
    // Check whether the display name has been changed
    NSString *displayname = self.userDisplayName.text;
    if ((displayname.length || currentDisplayName.length) && [displayname isEqualToString:currentDisplayName] == NO) {
        // Save display name
        [self startUserInfoUploadAnimation];
        _userDisplayName.enabled = NO;
        isDisplayNameUploading = YES;

         MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        [mxHandler.mxSession.myUser setDisplayName:displayname success:^{
            // save the current displayname
            currentDisplayName = displayname;
            // no more update in progress
            isDisplayNameUpdated = NO;
            
            // need to uploaded the avatar
            if (isAvatarUpdated) {
                [self savePicture];
            } else {
                // the job is ended
                [self stopUserInfoUploadAnimation];
            }
            _userDisplayName.enabled = YES;
            isDisplayNameUploading = NO;
        } failure:^(NSError *error) {
            NSLog(@"Set displayName failed: %@", error);
            [self stopUserInfoUploadAnimation];
            _userDisplayName.enabled = YES;
            isDisplayNameUploading = NO;
            
            //Alert user
            NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
            if (!title) {
                title = @"Display name change failed";
            }
            NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
            
            CustomAlert *alert = [[CustomAlert alloc] initWithTitle:title message:msg style:CustomAlertStyleAlert];
            [errorAlerts addObject:alert];
            alert.cancelButtonIndex = [alert addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                [errorAlerts removeObject:alert];
                // Remove change
                self.userDisplayName.text = currentDisplayName;
            }];
            [alert addActionWithTitle:@"Retry" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
                [errorAlerts removeObject:alert];
                [self saveDisplayName];
            }];
            [alert showInViewController:self];
        }];
    }
}

- (void)savePicture {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Save picture
    [self startUserInfoUploadAnimation];
    _userPicture.enabled = NO;
    isAvatarUploading = YES;
    
    if (uploadedPictureURL == nil) {
        // Upload picture
        [mxHandler.mxRestClient uploadContent:UIImageJPEGRepresentation([self.userPicture imageForState:UIControlStateNormal], 0.5)
                                     mimeType:@"image/jpeg"
                                      timeout:30
                                      success:^(NSString *url) {
                                          // Store uploaded picture url and trigger picture saving
                                          uploadedPictureURL = url;
                                          [self savePicture];
                                      } failure:^(NSError *error) {
                                          NSLog(@"Upload image failed: %@", error);
                                          [self stopUserInfoUploadAnimation];
                                          _userPicture.enabled = YES;
                                          isAvatarUploading = NO;
                                          [self handleErrorDuringPictureSaving:error];
                                      } uploadProgress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                                          // need to display the progress ?
                                      }];
    } else {
        [mxHandler.mxSession.myUser setAvatarUrl:uploadedPictureURL
                                     success:^{
                                         // uploadedPictureURL becomes the uploaded picture
                                         currentPictureURL = uploadedPictureURL;
                                         // manage the nil case.
                                         [self updateUserPicture:uploadedPictureURL];
                                         uploadedPictureURL = nil;
                                         
                                         isAvatarUpdated = NO;
                                         
                                         if (isDisplayNameUpdated) {
                                             [self saveDisplayName];
                                         } else {
                                             _saveUserInfoButton.enabled = NO;
                                             [self stopUserInfoUploadAnimation];
                                         }
                                         
                                         // update statuses
                                         _userPicture.enabled = YES;
                                         isAvatarUploading = NO;
                                         
                                     } failure:^(NSError *error) {
                                         NSLog(@"Set avatar url failed: %@", error);
                                         [self stopUserInfoUploadAnimation];
                                         
                                         _userPicture.enabled = YES;
                                         isAvatarUploading = NO;
                                         
                                         // update statuses
                                         [self handleErrorDuringPictureSaving:error];
                                     }];
    }
}

- (void)handleErrorDuringPictureSaving:(NSError*)error {
    NSString *title = [error.userInfo valueForKey:NSLocalizedFailureReasonErrorKey];
    if (!title) {
        title = @"Picture change failed";
    }
    NSString *msg = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    
    CustomAlert *alert = [[CustomAlert alloc] initWithTitle:title message:msg style:CustomAlertStyleAlert];
    [errorAlerts addObject:alert];
    alert.cancelButtonIndex = [alert addActionWithTitle:@"Cancel" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
        [errorAlerts removeObject:alert];
        // Remove change
        uploadedPictureURL = nil;
        [self updateUserPicture:[MatrixHandler sharedHandler].mxSession.myUser.avatarUrl];
    }];
    [alert addActionWithTitle:@"Retry" style:CustomAlertActionStyleDefault handler:^(CustomAlert *alert) {
        [errorAlerts removeObject:alert];
        [self savePicture];
    }];
    
    [alert showInViewController:self];
}

- (void)updateUserPicture:(NSString *)avatar_url {
    if (currentPictureURL == nil || [currentPictureURL isEqualToString:avatar_url] == NO) {
        // Remove any pending observers
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        // Cancel previous loader (if any)
        if (imageLoader) {
            [imageLoader cancel];
            imageLoader = nil;
        }
        
        currentPictureURL = [avatar_url isEqual:[NSNull null]] ? nil : avatar_url;
        if (currentPictureURL) {
            // Check whether the image download is in progress
            id loader = [MediaManager existingDownloaderForURL:currentPictureURL];
            if (loader) {
                // Add observers
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFinishNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFailNotification object:nil];
            } else {
                // Retrieve the image from cache
                UIImage* image = [MediaManager loadCachePictureForURL:currentPictureURL];
                if (image) {
                    [self updateAvatarImage:image];
                } else {
                    // Cancel potential download in progress
                    if (imageLoader) {
                        [imageLoader cancel];
                    }
                    // Add observers
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFinishNotification object:nil];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMediaDownloadDidFailNotification object:nil];
                    imageLoader = [MediaManager downloadMedia:currentPictureURL mimeType:@"image/jpeg"];
                }
            }
        } else {
            // Set placeholder
            [self updateAvatarImage:[UIImage imageNamed:@"default-profile"]];
        }
    }
}

- (void)onMediaDownloadEnd:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* url = notif.object;
        
        if ([url isEqualToString:currentPictureURL]) {
            // update the image
            UIImage* image = [MediaManager loadCachePictureForURL:currentPictureURL];
            if (image == nil) {
                image = [UIImage imageNamed:@"default-profile"];
            }
            [self updateAvatarImage:image];
            
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
        if ([[MatrixHandler sharedHandler] isResumeDone]) {
            [self stopUserInfoUploadAnimation];
            _userPicture.enabled = YES;
            _userDisplayName.enabled = YES;
        } else {
            [self startUserInfoUploadAnimation];
            _userPicture.enabled = NO;
            _userDisplayName.enabled = NO;
        }
    }
}

#pragma mark - Actions

- (IBAction)onButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    if (sender == _saveUserInfoButton) {
        if (isDisplayNameUpdated) {
            _saveUserInfoButton.enabled = NO;
            [self saveDisplayName];
        } else if (isAvatarUpdated) {
            _saveUserInfoButton.enabled = NO;
            [self savePicture];
        }
    } else if (sender == _userPicture) {
        // Open picture gallery
        UIImagePickerController *mediaPicker = [[UIImagePickerController alloc] init];
        mediaPicker.delegate = self;
        mediaPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        mediaPicker.allowsEditing = NO;
        [[AppDelegate theDelegate].masterTabBarController presentMediaPicker:mediaPicker];
    } else if (sender == logoutBtn) {
        [[AppDelegate theDelegate] logout];
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

#pragma mark - keyboard

- (void) manageSaveChangeButton {
    // check if there is a displayname update
    NSString *displayname = self.userDisplayName.text;
    isDisplayNameUpdated = ((displayname.length || currentDisplayName.length) && [displayname isEqualToString:currentDisplayName] == NO);
    
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
    NSArray* words = [wordsListTextField.text componentsSeparatedByString:@","];
    NSMutableArray* fiteredWords = [[NSMutableArray alloc] init];
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
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

- (void)dismissKeyboard {
    if ([_userDisplayName isFirstResponder]) {
        // Hide the keyboard
        [_userDisplayName resignFirstResponder];
        [self manageSaveChangeButton];
    }
    
    if ([wordsListTextField isFirstResponder]) {
        [self manageWordsList];
        [wordsListTextField resignFirstResponder];
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    if ((_userDisplayName == textField) || (wordsListTextField == textField)) {
        // "Done" key has been pressed
        [self dismissKeyboard];
    }
    return YES;
}

- (IBAction)textFieldDidChange:(id)sender {
    if (sender == _userDisplayName) {
        [self manageSaveChangeButton];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView == aTableView) {
        // tap on clear application cache
        if ((indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) && (indexPath.row == SETTINGS_SECTION_ROOMS_CLEAR_CACHE_INDEX)) {
            // clear caches
            [[MatrixHandler sharedHandler] forceInitialSync:YES];
        }
        
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        
        enableInAppRowIndex = setInAppWordRowIndex = enablePushNotificationdRowIndex = -1;
        
        int count = 0;
        enableInAppRowIndex = count++;
        
        if ([[AppSettings sharedSettings] enableInAppNotifications]) {
            setInAppWordRowIndex = count++;
        }
        
        if ([APNSHandler sharedHandler].isAvailable) {
            enablePushNotificationdRowIndex = count++;
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
    if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        if (indexPath.row == setInAppWordRowIndex) {
            return 110;
        }

        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_ROOMS_INDEX) {
        return 44;
    } else if (indexPath.section == SETTINGS_SECTION_CONFIGURATION_INDEX) {
        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, MAXFLOAT)];
        textView.font = [UIFont systemFontOfSize:14];
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        textView.text = [NSString stringWithFormat:kConfigurationFormatText, mxHandler.homeServerURL, nil, mxHandler.userId, mxHandler.accessToken];
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
    
    if (section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
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

- (void)refreshWordsList {
    NSMutableString* wordsList = [[NSMutableString alloc] init];
    NSArray* patterns = [AppSettings sharedSettings].specificWordsToAlertOn;
    
    for(NSString* string in patterns) {
        [wordsList appendFormat:@"%@,", string];
    }
    
    if (wordsList.length > 0) {
        wordsListTextField.text = [wordsList substringToIndex:wordsList.length - 1];
    }
    else {
        wordsListTextField.text = nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (indexPath.section == SETTINGS_SECTION_NOTIFICATIONS_INDEX) {
        
        if (indexPath.row == setInAppWordRowIndex) {
            SettingsCellWithLabelAndTextField* settingsCellWithLabelAndTextField = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithLabelAndTextField" forIndexPath:indexPath];
            
            settingsCellWithLabelAndTextField.settingTextField.delegate = self;
            wordsListTextField = settingsCellWithLabelAndTextField.settingTextField;
            
            // update the text only if it is not the first responder
            if (!wordsListTextField.isFirstResponder) {
                [self refreshWordsList];
            }
        
            cell = settingsCellWithLabelAndTextField;
        }
        else {
            SettingsTableCellWithSwitch *notificationsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            if (indexPath.row == enableInAppRowIndex) {
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
            
            cell.textLabel.text = [NSString stringWithFormat:@"Clear cache (%@)", [NSByteCountFormatter stringFromByteCount:[MatrixHandler sharedHandler].cachesSize countStyle:NSByteCountFormatterCountStyleFile]];
 ;
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor =  [AppDelegate theDelegate].masterTabBarController.tabBar.tintColor;
        } else {
            SettingsTableCellWithSwitch *roomsSettingCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithSwitch" forIndexPath:indexPath];
            
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
        SettingsTableCellWithTextView *configCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
        configCell.settingTextView.text = [NSString stringWithFormat:kConfigurationFormatText, mxHandler.homeServerURL, nil, mxHandler.userId, mxHandler.accessToken];
        cell = configCell;
    } else if (indexPath.section == SETTINGS_SECTION_COMMANDS_INDEX) {
        SettingsTableCellWithTextView *commandsCell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCellWithTextView" forIndexPath:indexPath];
        commandsCell.settingTextView.text = kCommandsDescriptionText;
        cell = commandsCell;
    }
    
    return cell;
}

# pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (selectedImage) {
        [self updateAvatarImage:selectedImage];
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

# pragma mark - UITextViewDelegate

@end
