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
#import "MatrixHandler.h"
#import "MediaManager.h"

@interface SettingsViewController () {
    id imageLoader;
    
    NSString *currentDisplayName;
    NSString *currentPictureURL;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *tableHeader;
@property (weak, nonatomic) IBOutlet UIButton *userPicture;
@property (weak, nonatomic) IBOutlet UITextField *userDisplayName;
@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
@property (weak, nonatomic) IBOutlet UIView *tableFooter;
@property (weak, nonatomic) IBOutlet UIButton *logoutBtn;

- (IBAction)onButtonPressed:(id)sender;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self reset];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
}

- (void)dealloc {
    // Cancel picture loader (if any)
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update User information
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // Get Display name
    [mxHandler.mxSession displayName:mxHandler.mxSession.user_id success:^(NSString *displayname) {
        currentDisplayName = displayname;
        self.userDisplayName.text = displayname;
    } failure:^(NSError *error) {
        NSLog(@"Get displayName failed: %@", error);
        //Alert user
        [[AppDelegate theDelegate] showErrorAsAlert:error];
    }];
    
    // Get picture url
    [mxHandler.mxSession avatarUrl:mxHandler.mxSession.user_id success:^(NSString *avatar_url) {
        if (currentPictureURL == nil || [currentPictureURL isEqualToString:avatar_url] == NO) {
            // Cancel previous loader (if any)
            if (imageLoader) {
                [MediaManager cancel:imageLoader];
                imageLoader = nil;
            }

            currentPictureURL = [avatar_url isEqual:[NSNull null]] ? nil : avatar_url;
            if (currentPictureURL) {
                // Load user's picture
                imageLoader = [MediaManager loadPicture:currentPictureURL success:^(UIImage *image) {
                    [self.userPicture setImage:image forState:UIControlStateNormal];
                    [self.userPicture setImage:image forState:UIControlStateHighlighted];
                } failure:^(NSError *error) {
                    // Reset picture URL in order to try next time
                    currentPictureURL = nil;
                }];
            } else {
                // Set placeholder
                UIImage *image = [UIImage imageNamed:@"default-profile"];
                [self.userPicture setImage:image forState:UIControlStateNormal];
                [self.userPicture setImage:image forState:UIControlStateHighlighted];
            }
        }
    } failure:^(NSError *error) {
        NSLog(@"Get picture url failed: %@", error);
        //Alert user
        [[AppDelegate theDelegate] showErrorAsAlert:error];
    }];
}

#pragma mark -

- (void)reset {
    // Cancel picture loader (if any)
    if (imageLoader) {
        [MediaManager cancel:imageLoader];
        imageLoader = nil;
    }
    
    currentPictureURL = nil;
    UIImage *image = [UIImage imageNamed:@"default-profile"];
    [self.userPicture setImage:image forState:UIControlStateNormal];
    [self.userPicture setImage:image forState:UIControlStateHighlighted];
    
    currentDisplayName = nil;
    self.userDisplayName.text = nil;
}

#pragma mark -

- (IBAction)onButtonPressed:(id)sender {
    [self dismissKeyboard];
    
    if (sender == _userPicture) {
        // TODO open gallery
    } else if (sender == _saveBtn) {
        // Save Change (if any)
        NSString *displayname = self.userDisplayName.text;
        if ([displayname isEqualToString:currentDisplayName] == NO) {
            MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
            [mxHandler.mxSession setDisplayName:displayname success:^{
                currentDisplayName = displayname;
            } failure:^(NSError *error) {
                NSLog(@"Set displayName failed: %@", error);
                //Alert user
                [[AppDelegate theDelegate] showErrorAsAlert:error];
            }];
        }
        // TODO check picture change
    } else if (sender == _logoutBtn) {
        [self reset];
        [[AppDelegate theDelegate] logout];
    }
}

#pragma mark - keyboard

- (void)dismissKeyboard
{
    // Hide the keyboard
    [_userDisplayName resignFirstResponder];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*) textField
{
    // "Done" key has been pressed
    [textField resignFirstResponder];
    
    return YES;
}
@end
