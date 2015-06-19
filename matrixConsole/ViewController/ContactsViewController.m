/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "ContactsViewController.h"

#import "AppDelegate.h"

#import "RageShakeManager.h"

NSString *const kInvitationMessage = @"I'd like to chat with you with matrix. Please, visit the website http://matrix.org to have more information.";

@interface ContactsViewController ()
{
    /**
     Tap on thumbnail --> display matrix information.
     */
    MXKContact* selectedContact;
}

@property (strong, nonatomic) MXKAlert *startChatMenu;
@property (strong, nonatomic) MXKAlert *allowContactSyncAlert;
@end

@implementation ContactsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setSectionIndexColor:[AppDelegate theDelegate].masterTabBarController.tabBar.tintColor];
    [self.tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
    
    // Set rageShake handler
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    // The view controller handles itself the selected contact
    self.delegate = self;
}

- (void)destroy
{
    if (self.startChatMenu)
    {
        [self.startChatMenu dismiss:NO];
    }
    if (self.allowContactSyncAlert)
    {
        [self.allowContactSyncAlert dismiss:NO];
    }
    
    selectedContact = nil;
    
    [super destroy];
}

#pragma mark - Actions

- (IBAction)onSegmentValueChange:(id)sender
{
    [super onSegmentValueChange:sender];
    
    if (sender == self.contactsControls)
    {
        // Did the user select local contacts?
        if (self.contactsControls.selectedSegmentIndex)
        {
            MXKAppSettings* appSettings = [MXKAppSettings standardAppSettings];
            
            if (!appSettings.syncLocalContacts)
            {
                __weak typeof(self) weakSelf = self;
                
                self.allowContactSyncAlert = [[MXKAlert alloc] initWithTitle:@"Allow local contacts synchronization?"  message:nil style:MXKAlertStyleAlert];
                
                [self.allowContactSyncAlert addActionWithTitle:@"No" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                {
                    weakSelf.allowContactSyncAlert = nil;
                }];
                
                [self.allowContactSyncAlert addActionWithTitle:@"Yes" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                {
                    weakSelf.allowContactSyncAlert = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        appSettings.syncLocalContacts = YES;
                        [weakSelf.tableView reloadData];
                    });
                }];
                
                [self.allowContactSyncAlert showInViewController:self];
            }
        }
    }
}

#pragma mark - MXKContactListViewControllerDelegate

- (void)contactListViewController:(MXKContactListViewController *)contactListViewController didSelectContact:(NSString*)contactId
{
    MXKContact *contact = [[MXKContactManager sharedManager] contactWithContactID:contactId];
    
    __weak typeof(self) weakSelf = self;
    NSArray* matrixIDs = contact.matrixIdentifiers;
    
    // matrix user ?
    if (matrixIDs.count)
    {
        // Display action sheet only if at least one session is available for this user
        BOOL isSessionAvailable = NO;
        
        NSArray *mxSessions = self.mxSessions;
        for (NSString* userID in matrixIDs)
        {
            for (MXSession *mxSession in mxSessions)
            {
                if ([mxSession userWithUserId:userID])
                {
                    isSessionAvailable = YES;
                    break;
                }
            }
        }
        
        if (isSessionAvailable)
        {
            // only 1 matrix ID
            if (matrixIDs.count == 1)
            {
                NSString* matrixID = [matrixIDs objectAtIndex:0];
                
                self.startChatMenu = [[MXKAlert alloc] initWithTitle:[NSString stringWithFormat:@"Chat with %@", matrixID]  message:nil style:MXKAlertStyleAlert];
                
                [self.startChatMenu addActionWithTitle:@"Cancel" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                 {
                     weakSelf.startChatMenu = nil;
                 }];
                
                [self.startChatMenu addActionWithTitle:@"OK" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                 {
                     weakSelf.startChatMenu = nil;
                     
                     [[AppDelegate theDelegate] startPrivateOneToOneRoomWithUserId:matrixID];
                 }];
            }
            else
            {
                self.startChatMenu = [[MXKAlert alloc] initWithTitle:[NSString stringWithFormat:@"Chat with "]  message:nil style:MXKAlertStyleActionSheet];
                
                for(NSString* matrixID in matrixIDs)
                {
                    [self.startChatMenu addActionWithTitle:matrixID style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                     {
                         weakSelf.startChatMenu = nil;
                         
                         [[AppDelegate theDelegate] startPrivateOneToOneRoomWithUserId:matrixID];
                     }];
                }
                
                [self.startChatMenu addActionWithTitle:@"Cancel" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                 {
                     weakSelf.startChatMenu = nil;
                 }];
                
                self.startChatMenu.sourceView = self.tableView;
            }
            
            [self.startChatMenu showInViewController:self];
        }
    }
    else
    {
        // invite to use matrix
        if (([MFMessageComposeViewController canSendText] ? contact.emailAddresses.count : 0) + (contact.phoneNumbers.count > 0))
        {
            
            self.startChatMenu = [[MXKAlert alloc] initWithTitle:[NSString stringWithFormat:@"Invite this user to use matrix with"]  message:nil style:MXKAlertStyleActionSheet];
            
            // check if the target can send SMSes
            if ([MFMessageComposeViewController canSendText])
            {
                // list phonenumbers
                for(MXKPhoneNumber* phonenumber in contact.phoneNumbers)
                {
                    [self.startChatMenu addActionWithTitle:phonenumber.textNumber style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                     {
                         weakSelf.startChatMenu = nil;
                         
                         // launch SMS composer
                         MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
                         
                         if (messageComposer)
                             
                         {
                             messageComposer.messageComposeDelegate = weakSelf;
                             messageComposer.body =kInvitationMessage;
                             messageComposer.recipients = [NSArray arrayWithObject:phonenumber.textNumber];
                             
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [weakSelf presentViewController:messageComposer animated:YES completion:nil];
                             });
                         }
                     }];
                }
            }
            
            // list emails
            for(MXKEmail* email in contact.emailAddresses)
            {
                [self.startChatMenu addActionWithTitle:email.emailAddress style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
                 {
                     weakSelf.startChatMenu = nil;
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         NSString* subject = [ @"Matrix.org is magic" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                         NSString* body = [kInvitationMessage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                         
                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@", email.emailAddress, subject, body]]];
                     });
                 }];
            }
            
            [self.startChatMenu addActionWithTitle:@"Cancel" style:MXKAlertActionStyleDefault handler:^(MXKAlert *alert)
             {
                 weakSelf.startChatMenu = nil;
             }];
            
            self.startChatMenu.sourceView = self.tableView;
            [self.startChatMenu showInViewController:self];
        }
    }
}

- (void)contactListViewController:(MXKContactListViewController *)contactListViewController didTapContactThumbnail:(NSString*)contactId
{
    MXKContact *contact = [[MXKContactManager sharedManager] contactWithContactID:contactId];
    
    // open detailled sheet if there
    if (contact.matrixIdentifiers.count > 0)
    {
        selectedContact = contact;
        [self performSegueWithIdentifier:@"showContactDetails" sender:self];
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Keep ref on destinationViewController
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:@"showContactDetails"])
    {
        MXKContactDetailsViewController *contactDetailsViewController = segue.destinationViewController;
        // Set rageShake handler
        contactDetailsViewController.rageShakeManager = [RageShakeManager sharedManager];
        // Set delegate to handle start chat option
        contactDetailsViewController.delegate = [AppDelegate theDelegate];
        
        contactDetailsViewController.contact = selectedContact;
        selectedContact = nil;
    }
}

#pragma mark MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
