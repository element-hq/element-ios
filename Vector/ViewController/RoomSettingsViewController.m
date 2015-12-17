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

#import "RoomSettingsViewController.h"

#import <Photos/Photos.h>
#import <MediaPlayer/MediaPlayer.h>

#import "TableViewCellWithLabelAndTextField.h"
#import "TableViewCellWithLabelAndLargeTextView.h"
#import "TableViewCellWithLabelAndMXKImageView.h"
#import "TableViewCellWithLabelAndSwitch.h"

#import "TableViewCellSeparator.h"

#import "RageShakeManager.h"

#import "VectorDesignValues.h"

#import "AvatarGenerator.h"

#import "MXRoom+Vector.h"

#define ROOM_SECTION 0

#define ROOM_SECTION_PHOTO               0
#define ROOM_SECTION_NAME                1
#define ROOM_SECTION_TOPIC               2
#define ROOM_SECTION_PRIV_PUB            3
#define ROOM_SECTION_MUTE_NOTIFICATIONS  4
#define ROOM_SECTION_COUNT               5

#define ROOM_TOPIC_CELL_HEIGHT 99

@interface RoomSettingsViewController ()
{
    // updated user data
    NSMutableDictionary<NSString*, id> *updatedItemsDict;
    
    // active items
    UITextView* topicTextView;
    UITextField* nameTextField;
    
    // pending http operation
    MXHTTPOperation* pendingOperation;
    
    // the updating spinner
    UIActivityIndicatorView* updatingSpinner;
    
    MXKAlert *currentAlert;
    
    // listen to more events than the mother class
    id extraEventsListener;
    
    // picker
    MediaPickerViewController* mediaPicker;
    
    // switches
    UISwitch *roomNotifSwitch;
}
@end

@implementation RoomSettingsViewController

- (UINavigationItem*) getNavigationItem
{
    // this viewController can be displayed
    // 1- with a "standard" push mode
    // 2- within a segmentedViewController i.e. inside another viewcontroller
    // so, we need to use the parent controller when it is required.
    UIViewController* topViewController = (self.parentViewController) ? self.parentViewController : self;
    
    return topViewController.navigationItem;
}

- (void)setNavBarButtons
{
    [self getNavigationItem].rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onSave:)];
    [self getNavigationItem].rightBarButtonItem.enabled = ([self getUpdatedItemsDict].count != 0);
    [self getNavigationItem].leftBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onCancel:)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO use a color panel
    // not an hard coded one.
    CGFloat item = (242.0f / 255.0);
    
    self.tableView.backgroundColor = [UIColor colorWithRed:item green:item blue:item alpha:item];
    self.tableView.separatorColor = [UIColor clearColor];
    
    // Setup `RoomSettingsViewController` properties
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    [self setNavBarButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMXSessionStateChange:) name:kMXSessionStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateRules:) name:kMXNotificationCenterDidUpdateRules object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAccountUserInfoDidChange:) name:kMXKAccountUserInfoDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self dismissFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXSessionStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXNotificationCenterDidUpdateRules object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKAccountUserInfoDidChangeNotification object:nil];
}

// this method is called when the viewcontroller is displayed inside another one.
- (void)didMoveToParentViewController:(nullable UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    [self setNavBarButtons];
}

- (void)destroy
{
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (pendingOperation)
    {
        [pendingOperation cancel];
        pendingOperation = nil;
    }
    
    [super destroy];
}

#pragma mark - private

- (NSMutableDictionary*)getUpdatedItemsDict
{
    if (!updatedItemsDict)
    {
        updatedItemsDict = [[NSMutableDictionary alloc] init];
    }
    
    return updatedItemsDict;
}

- (void)dismissFirstResponder
{
    if ([topicTextView isFirstResponder])
    {
        [topicTextView resignFirstResponder];
    }
    
    if ([nameTextField isFirstResponder])
    {
        [nameTextField resignFirstResponder];
    }
}

- (void)showUpdatingSpinner
{
    if (!updatingSpinner)
    {
        self.tableView.userInteractionEnabled = NO;
        
        // Add a spinner
        updatingSpinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        updatingSpinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
        updatingSpinner.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
        updatingSpinner.hidesWhenStopped = NO;
        [updatingSpinner startAnimating];
        updatingSpinner.center = self.view.center;
        [self.view addSubview:updatingSpinner];
    }
}

- (void)hideUpdatingSpinner
{
    self.tableView.userInteractionEnabled = YES;
    
    if (updatingSpinner)
    {
        [updatingSpinner removeFromSuperview];
        updatingSpinner = nil;
    }
}

#pragma mark - actions

- (void)textViewDidChange:(UITextView *)textView
{
    // avoid nil pointer
    NSString* text = (textView.text) ? textView.text : @"";
    
    if (topicTextView == textView)
    {
        NSMutableDictionary* dict = [self getUpdatedItemsDict];
        
        if ([text isEqualToString:mxRoomState.topic])
        {
            [dict removeObjectForKey:@"ROOM_SECTION_TOPIC"];
        }
        else
        {
            [dict setObject:text forKey:@"ROOM_SECTION_TOPIC"];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (dict.count != 0);
    }
}

- (IBAction)onTextFieldUpdate:(UITextField*)textField
{
    // avoid nil pointer
    NSString* text = (textField.text) ? textField.text : @"";
    
    if (nameTextField == textField)
    {
        NSMutableDictionary* dict = [self getUpdatedItemsDict];
        
        if ([text isEqualToString:mxRoomState.name])
        {
            [dict removeObjectForKey:@"ROOM_SECTION_NAME"];
        }
        else
        {
            [dict setObject:text forKey:@"ROOM_SECTION_NAME"];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (dict.count != 0);
    }
}

- (void)didMXSessionStateChange:(NSNotification *)notif
{
    // Check this is our Matrix session that has changed
    if (notif.object == self.session)
    {
        // refresh when the session sync is done.
        if (MXSessionStateRunning == self.session.state)
        {
            [self.tableView reloadData];
        }
    }
}

- (void)didUpdateRules:(NSNotification *)notif
{
    [self.tableView reloadData];
}

- (void)didAccountUserInfoDidChange:(NSNotification *)notif
{
    [self.tableView reloadData];
}

- (IBAction)onCancel:(id)sender
{
    // if there are some updated fields
    if (updatedItemsDict && (updatedItemsDict.count > 0))
    {
        // ensure that the user understands that the updates will be lost if
        MXKAlert* alert = [[MXKAlert alloc] initWithTitle:nil message:NSLocalizedStringFromTable(@"room_details_with_updates", @"Vector", nil) style:MXKAlertStyleAlert];
        
        [alert addActionWithTitle:NSLocalizedStringFromTable(@"cancel", @"Vector", nil) style:MXKAlertActionStyleCancel handler:^(MXKAlert *alert) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        
        [alert addActionWithTitle:NSLocalizedStringFromTable(@"save", @"Vector", nil) style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert) {
            [self onSave:nil];
        }];
        
        [alert showInViewController:self];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onSaveFailed:(NSString*)message withKey:(NSString*)key
{
    __weak typeof(self) weakSelf = self;
    
    currentAlert = [[MXKAlert alloc] initWithTitle:nil
                                           message:message
                                             style:MXKAlertStyleAlert];
    
    currentAlert.cancelButtonIndex = [currentAlert addActionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                                style:MXKAlertActionStyleCancel
                                                              handler:^(MXKAlert *alert) {
                                                                  
                                                                  // save anything else
                                                                  __strong __typeof(weakSelf)strongSelf = weakSelf;
                                                                  [strongSelf->updatedItemsDict removeObjectForKey:key];
                                                                  strongSelf->currentAlert = nil;
                                                                  [strongSelf onSave:nil];
                                                                  
                                                              }];
    
    [currentAlert addActionWithTitle:NSLocalizedStringFromTable(@"retry", @"Vector", nil)
                               style:MXKAlertActionStyleDefault
                             handler:^(MXKAlert *alert) {
                                 
                                 // try again
                                 __strong __typeof(weakSelf)strongSelf = weakSelf;
                                 strongSelf->currentAlert = nil;
                                 [strongSelf onSave:nil];
                                 
                             }];
    
    [currentAlert showInViewController:self];
}

- (IBAction)onSave:(id)sender
{
    [self showUpdatingSpinner];
    
    // check if there is some update
    if (mxRoomState && updatedItemsDict && (updatedItemsDict.count > 0))
    {
        if ([updatedItemsDict objectForKey:@"ROOM_SECTION_PHOTO"])
        {
            // Retrieve the current picture and make sure its orientation is up
            UIImage *updatedPicture = [MXKTools forceImageOrientationUp:[updatedItemsDict objectForKey:@"ROOM_SECTION_PHOTO"]];
            
            // Upload picture
            MXKMediaLoader *uploader = [MXKMediaManager prepareUploaderWithMatrixSession:mxRoom.mxSession initialRange:0 andRange:1.0];
            
            [uploader uploadData:UIImageJPEGRepresentation(updatedPicture, 0.5) filename:nil mimeType:@"image/jpeg" success:^(NSString *url)
             {
                 [updatedItemsDict removeObjectForKey:@"ROOM_SECTION_PHOTO"];
                 [updatedItemsDict setObject:url forKey:@"ROOM_SECTION_PHOTO_URL"];
                 
                 [self onSave:nil];
             } failure:^(NSError *error)
             {
                 NSLog(@"[Vector RoomSettingsViewController] Failed to upload image: %@", error);
                 [updatedItemsDict removeObjectForKey:@"ROOM_SECTION_PHOTO"];
                 [self onSave:nil];
             }];
            
            return;
        }
        
        if ([updatedItemsDict objectForKey:@"ROOM_SECTION_PHOTO_URL"])
        {
            __weak typeof(self) weakSelf = self;
            
            NSString* photoUrl = [updatedItemsDict objectForKey:@"ROOM_SECTION_PHOTO_URL"];
            
            [mxRoom setAvatar:photoUrl success:^{
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf->updatedItemsDict removeObjectForKey:@"ROOM_SECTION_PHOTO_URL"];
                [strongSelf onSave:nil];
                
            } failure:^(NSError *error) {
                
                NSLog(@"[Vector RoomSettingsViewController] Failed to update the room avatar %@", error);
                
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf->updatedItemsDict removeObjectForKey:@"ROOM_SECTION_PHOTO_URL"];
                [strongSelf onSave:nil];
                
            }];
            
            return;
        }
        
        // has a new room name
        if ([updatedItemsDict objectForKey:@"ROOM_SECTION_NAME"])
        {
            NSString* newName = [updatedItemsDict objectForKey:@"ROOM_SECTION_NAME"];
            
            if (![newName isEqualToString:mxRoomState.name])
            {
                __weak typeof(self) weakSelf = self;
                
                pendingOperation = [mxRoom setName:newName success:^{
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    strongSelf->pendingOperation = nil;
                    [strongSelf->updatedItemsDict removeObjectForKey:@"ROOM_SECTION_NAME"];
                    [strongSelf onSave:nil];
                    
                } failure:^(NSError *error) {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    strongSelf->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                
                        [strongSelf onSaveFailed:NSLocalizedStringFromTable(@"room_details_fail_to_update_room_name", @"Vector", nil) withKey:@"ROOM_SECTION_NAME"];
                        
                    });
                    
                    NSLog(@"[onDone] Rename room failed: %@", error);
                }];
                
                return;
            }
        }
        
        // has a new room topic
        if ([updatedItemsDict objectForKey:@"ROOM_SECTION_TOPIC"])
        {
            NSString* newTopic = [updatedItemsDict objectForKey:@"ROOM_SECTION_TOPIC"];
            
            if (![newTopic isEqualToString:mxRoomState.topic])
            {
                __weak typeof(self) weakSelf = self;
                
                pendingOperation = [mxRoom setTopic:newTopic success:^{
                    __strong __typeof(weakSelf)strongSelf = weakSelf;
                    
                    strongSelf->pendingOperation = nil;
                    [strongSelf->updatedItemsDict removeObjectForKey:@"ROOM_SECTION_TOPIC"];
                    [strongSelf onSave:nil];
                    
                } failure:^(NSError *error) {
                    __strong __typeof(weakSelf)strongSelf = weakSelf;

                    strongSelf->pendingOperation = nil;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [strongSelf onSaveFailed:NSLocalizedStringFromTable(@"room_details_fail_to_update_topic", @"Vector", nil) withKey:@"ROOM_SECTION_TOPIC"];
                        
                    });
                    
                    NSLog(@"[onDone] Rename topic failed: %@", error);
                }];
                
                return;
            }
        }
    }
    
    if ([updatedItemsDict objectForKey:@"ROOM_SECTION_MUTE_NOTIFICATIONS"])
    {
        [mxRoom toggleRoomNotifications:roomNotifSwitch.on];
        [updatedItemsDict removeObjectForKey:@"ROOM_SECTION_MUTE_NOTIFICATIONS"];
        [self onSave:nil];
    }
    
    [self getNavigationItem].rightBarButtonItem.enabled = (updatedItemsDict.count != 0);
    
    [self hideUpdatingSpinner];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == ROOM_SECTION)
    {
        // add separators
        return ROOM_SECTION_COUNT * 2 + 1;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 33.0f;
}

- (UITableViewHeaderFooterView *)headerViewForSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = [[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0, 0, 10, 33)];
    
    header.backgroundColor = [UIColor redColor];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ROOM_SECTION)
    {
        NSInteger row = indexPath.row;
        
        // is a separator ?
        if ((row % 2) == 0)
        {
            return 1.0f;
        }
        
        // retrieve row as a ROOM_SECTION_XX index
        row = (row - 1) / 2;
        
        if (row == ROOM_SECTION_TOPIC)
        {
            return ROOM_TOPIC_CELL_HEIGHT;
        }
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    UITableViewCell* cell = nil;
    
    // general settings
    if (indexPath.section == ROOM_SECTION)
    {
        if ((row % 2) == 0)
        {
            UITableViewCell* sepCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellSeparator defaultReuseIdentifier]];
            
            if (!sepCell)
            {
                sepCell = [[TableViewCellSeparator alloc] init];
            }
            
            // the borders are drawn in dark grey
            sepCell.contentView.backgroundColor = ((row == 0) || (row == ROOM_SECTION_COUNT * 2)) ? [UIColor darkGrayColor] : [UIColor lightGrayColor];
            
            return sepCell;
        }
        
        // retrieve row as a ROOM_SECTION_XX index
        row = (row - 1) / 2;
        
        if (row == ROOM_SECTION_MUTE_NOTIFICATIONS)
        {
            TableViewCellWithLabelAndSwitch *roomNotifCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndSwitch defaultReuseIdentifier]];
            
            if (!roomNotifCell)
            {
                roomNotifCell = [[TableViewCellWithLabelAndSwitch alloc] init];
                [roomNotifCell.mxkSwitch addTarget:self action:@selector(onSwitchUpdate:) forControlEvents:UIControlEventValueChanged];
                roomNotifCell.mxkSwitch.onTintColor = VECTOR_GREEN_COLOR;
            }
            
            roomNotifCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_mute_notifs", @"Vector", nil);
            roomNotifSwitch = roomNotifCell.mxkSwitch;
            
            if (updatedItemsDict && [updatedItemsDict objectForKey:@"ROOM_SECTION_MUTE_NOTIFICATIONS"])
            {
                roomNotifSwitch.on = ((NSNumber*)[updatedItemsDict objectForKey:@"ROOM_SECTION_MUTE_NOTIFICATIONS"]).boolValue;
            }
            else
            {
                roomNotifSwitch.on = mxRoom.areRoomNotificationsMuted;
            }
            
            cell = roomNotifCell;
        }
        else if (row == ROOM_SECTION_PHOTO)
        {
            TableViewCellWithLabelAndMXKImageView *roomPhotoCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndMXKImageView defaultReuseIdentifier]];
            
            if (!roomPhotoCell)
            {
                roomPhotoCell = [[TableViewCellWithLabelAndMXKImageView alloc] init];
                
                // tap on avatar to update it
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onRoomAvatarTap:)];
                [roomPhotoCell.mxkImageView addGestureRecognizer:tap];
            }
            
            roomPhotoCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_photo", @"Vector", nil);
            
            if (updatedItemsDict && [updatedItemsDict objectForKey:@"ROOM_SECTION_PHOTO"])
            {
                roomPhotoCell.mxkImageView.image = (UIImage*)[updatedItemsDict objectForKey:@"ROOM_SECTION_PHOTO"];
            }
            else
            {
                [mxRoom setRoomAvatarImageIn:roomPhotoCell.mxkImageView];
                roomPhotoCell.mxkImageView.alpha = mxRoom.isModerator ? 1.0f : 0.5f;
            }
            
            [roomPhotoCell.mxkImageView.layer setCornerRadius:roomPhotoCell.mxkImageView.frame.size.width / 2];
            roomPhotoCell.mxkImageView.clipsToBounds = YES;
            roomPhotoCell.userInteractionEnabled = mxRoom.isModerator;
            
            cell = roomPhotoCell;
        }
        else if (row == ROOM_SECTION_TOPIC)
        {
            TableViewCellWithLabelAndLargeTextView *roomTopicCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndLargeTextView defaultReuseIdentifier]];
            
            if (!roomTopicCell)
            {
                roomTopicCell = [[TableViewCellWithLabelAndLargeTextView alloc] init];
                
                // define the cell height
                CGRect frame = roomTopicCell.frame;
                frame.size.height = ROOM_TOPIC_CELL_HEIGHT;
                roomTopicCell.frame = frame;
            }
            
            roomTopicCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_topic", @"Vector", nil);
            topicTextView = roomTopicCell.mxkTextView;
            
            if (updatedItemsDict && [updatedItemsDict objectForKey:@"ROOM_SECTION_TOPIC"])
            {
                roomTopicCell.mxkTextView.text = (NSString*)[updatedItemsDict objectForKey:@"ROOM_SECTION_TOPIC"];
            }
            else
            {
                roomTopicCell.mxkTextView.text = mxRoomState.topic;
            }
                        
            roomTopicCell.mxkTextView.tintColor = VECTOR_GREEN_COLOR;
            roomTopicCell.mxkTextView.delegate = self;
            
            // disable the edition if the user cannoy update it
            roomTopicCell.mxkTextView.editable = mxRoom.isModerator;
            roomTopicCell.mxkTextView.textColor = mxRoom.isModerator ? [UIColor blackColor] : [UIColor lightGrayColor];
            
            cell = roomTopicCell;
        }
        else if (row == ROOM_SECTION_NAME)
        {
            TableViewCellWithLabelAndTextField *roomNameCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndTextField defaultReuseIdentifier]];
            
            if (!roomNameCell)
            {
                roomNameCell = [[TableViewCellWithLabelAndTextField alloc] init];
            }
            
            roomNameCell.mxkLabel.text = NSLocalizedStringFromTable(@"room_details_room_name", @"Vector", nil);
            roomNameCell.mxkTextField.userInteractionEnabled = YES;
            roomNameCell.mxkTextField.tintColor = VECTOR_GREEN_COLOR;
            
            if (updatedItemsDict && [updatedItemsDict objectForKey:@"ROOM_SECTION_NAME"])
            {
                roomNameCell.mxkTextField.text = (NSString*)[updatedItemsDict objectForKey:@"ROOM_SECTION_NAME"];
            }
            else
            {
                roomNameCell.mxkTextField.text = mxRoomState.name;
            }
            roomNameCell.accessoryType = UITableViewCellAccessoryNone;
            
            cell = roomNameCell;
            nameTextField = roomNameCell.mxkTextField;
            
            // disable the edition if the user cannoy update it
            roomNameCell.editable = mxRoom.isModerator;
            roomNameCell.mxkTextField.textColor = mxRoom.isModerator ? [UIColor blackColor] : [UIColor lightGrayColor];
            
            
            // Add a "textFieldDidChange" notification method to the text field control.
            [roomNameCell.mxkTextField addTarget:self action:@selector(onTextFieldUpdate:) forControlEvents:UIControlEventEditingChanged];
        }
        else if (row == ROOM_SECTION_PRIV_PUB)
        {
            TableViewCellWithLabelAndTextField *privPublicCell = [tableView dequeueReusableCellWithIdentifier:[TableViewCellWithLabelAndTextField defaultReuseIdentifier]];
            
            if (!privPublicCell)
            {
                privPublicCell = [[TableViewCellWithLabelAndTextField alloc] init];
            }
            
            privPublicCell.mxkTextField.userInteractionEnabled = NO;
            privPublicCell.mxkTextField.text = @"";
            privPublicCell.mxkLabel.text = mxRoom.state.isPublic ?  NSLocalizedStringFromTable(@"room_details_room_is_public", @"Vector", nil) : NSLocalizedStringFromTable(@"room_details_room_is_private", @"Vector", nil);
            
            cell = privPublicCell;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView == aTableView)
    {
        [self dismissFirstResponder];
        
        if (indexPath.section == ROOM_SECTION)
        {
            NSUInteger row = indexPath.row;
            
            // the even views are the line separator
            if ((row % 2) == 0)
            {
                return;
            }
            
            // retrieve row as a ROOM_SECTION_XX index
            row = (row - 1) / 2;
            
            if (row == ROOM_SECTION_PHOTO)
            {
                [self onRoomAvatarTap:nil];
            }
        }
    }
}

#pragma mark - MediaPickerViewController Delegate

- (void)dismissMediaPicker
{
    if (mediaPicker)
    {
        [mediaPicker withdrawViewControllerAnimated:YES completion:nil];
        mediaPicker = nil;
    }
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectImage:(UIImage*)image withURL:(NSURL *)imageURL
{
    [self dismissMediaPicker];
    
    if (image)
    {
        [self getNavigationItem].rightBarButtonItem.enabled = YES;
        
        NSMutableDictionary* dict = [self getUpdatedItemsDict];
        [dict setObject:image forKey:@"ROOM_SECTION_PHOTO"];
        
        [self.tableView reloadData];
    }
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectVideo:(NSURL*)videoURL isCameraRecording:(BOOL)isCameraRecording
{
    // this method should not be called
    [self dismissMediaPicker];
}

- (void)mediaPickerController:(MediaPickerViewController *)mediaPickerController didSelectAssets:(NSArray *)assets
{
    if (assets.count > 0)
    {
        PHAsset* asset = [assets objectAtIndex:0];
        PHContentEditingInputRequestOptions *editOptions = [[PHContentEditingInputRequestOptions alloc] init];
        
        [asset requestContentEditingInputWithOptions:editOptions
                                   completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                                       
                                       if (contentEditingInput.mediaType == PHAssetMediaTypeImage)
                                       {
                                           // Here the fullSizeImageURL is related to a local file path
                                           NSData *data = [NSData dataWithContentsOfURL:contentEditingInput.fullSizeImageURL];
                                           UIImage *image = [UIImage imageWithData:data];
                                           
                                           if (image)
                                           {
                                               [self getNavigationItem].rightBarButtonItem.enabled = YES;
                                               
                                               NSMutableDictionary* dict = [self getUpdatedItemsDict];
                                               [dict setObject:image forKey:@"ROOM_SECTION_PHOTO"];
                                               
                                               [self.tableView reloadData];
                                           }
                                       }
                                   }];
    }
    
    [self dismissMediaPicker];
}

#pragma mark - actions

- (void)onRoomAvatarTap:(UITapGestureRecognizer *)recognizer
{
    mediaPicker = [MediaPickerViewController mediaPickerViewController];
    mediaPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    mediaPicker.multipleSelections = NO;
    mediaPicker.selectionButtonCustomLabel = NSLocalizedStringFromTable(@"media_picker_attach", @"Vector", nil);
    mediaPicker.delegate = self;
    UINavigationController *navigationController = [UINavigationController new];
    [navigationController pushViewController:mediaPicker animated:NO];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)onSwitchUpdate:(UISwitch*)uiSwitch
{
    if (uiSwitch == roomNotifSwitch)
    {
        NSMutableDictionary* dict = [self getUpdatedItemsDict];
        
        if (roomNotifSwitch.on == mxRoom.areRoomNotificationsMuted)
        {
           [dict removeObjectForKey:@"ROOM_SECTION_MUTE_NOTIFICATIONS"];
        }
        else
        {
            [dict setObject:[NSNumber numberWithBool:roomNotifSwitch.on] forKey:@"ROOM_SECTION_MUTE_NOTIFICATIONS"];
        }
        
        [self getNavigationItem].rightBarButtonItem.enabled = (dict.count != 0);
        [self.tableView reloadData];
    }
}

@end


