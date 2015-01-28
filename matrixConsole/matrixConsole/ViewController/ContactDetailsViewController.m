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

#import "ContactDetailsViewController.h"

#import "ContactDetailsTableCell.h"

#import "MatrixSDKHandler.h"

@interface ContactDetailsViewController () {
    NSArray* matrixIDs;
}

@property (weak, nonatomic) IBOutlet UIButton *memberThumbnailButton;
@property (weak, nonatomic) IBOutlet UITextView *roomMemberMID;

@end

@implementation ContactDetailsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.memberThumbnailButton = nil;
    self.roomMemberMID = nil;
    matrixIDs = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // remove the line separator color
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.rowHeight = 44;
    self.tableView.allowsSelection = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    self.roomMemberMID.text = _contact.displayName;
    
    // set the thumbnail info
    [self.memberThumbnailButton.imageView setContentMode: UIViewContentModeScaleAspectFill];
    [self.memberThumbnailButton.imageView setClipsToBounds:YES];
    
    if (_contact.thumbnail) {
        self.memberThumbnailButton.imageView.image = _contact.thumbnail;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThumbnailUpdate:) name:kMXCContactThumbnailUpdateNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    matrixIDs = _contact.matrixIdentifiers;
    return matrixIDs.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = indexPath.row;
    ContactDetailsTableCell* contactDetailsTableCell = (ContactDetailsTableCell*)[aTableView dequeueReusableCellWithIdentifier:@"ContactDetailsTableCell" forIndexPath:indexPath];
    
    if (row < matrixIDs.count) {
        contactDetailsTableCell.matrixUserIDLabel.text = [matrixIDs objectAtIndex:row];
    } else {
        // should never happen
        contactDetailsTableCell.matrixUserIDLabel.text = @"";
    }
    
    contactDetailsTableCell.startChatButton.layer.cornerRadius = 5;
    contactDetailsTableCell.startChatButton.layer.borderColor = [UIColor blackColor].CGColor;
    contactDetailsTableCell.startChatButton.layer.borderWidth = 2;
    contactDetailsTableCell.startChatButton.clipsToBounds = YES;
    [contactDetailsTableCell.startChatButton addTarget:self action:@selector(startChat:) forControlEvents:UIControlEventTouchUpInside];
    
    return contactDetailsTableCell;
}

- (void)startChat:(UIButton*)sender {
    UIView* view = sender;
    
    // search the parentce cell
    while (view && ![view isKindOfClass:[ContactDetailsTableCell class]]) {
        view = view.superview;
    }
    
    if ([view isKindOfClass:[ContactDetailsTableCell class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MatrixSDKHandler sharedHandler] startPrivateOneToOneRoomWith:((ContactDetailsTableCell*)view).matrixUserIDLabel.text];
        });
    }
}

- (void)onThumbnailUpdate:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* matrixID = notif.object;
        
        if ([matrixID isEqualToString:self.contact.contactID]) {
            if (_contact.thumbnail) {
                self.memberThumbnailButton.imageView.image = _contact.thumbnail;
            }
        }
    }
}

@end
