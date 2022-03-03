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

#import "MXKContactDetailsViewController.h"

#import "MXKTableViewCellWithLabelAndButton.h"

#import "NSBundle+MatrixKit.h"
#import "MXKSwiftHeader.h"

@interface MXKContactDetailsViewController ()
{
    NSArray* matrixIDs;
}

@end

@implementation MXKContactDetailsViewController

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKContactDetailsViewController class])
                          bundle:[NSBundle bundleForClass:[MXKContactDetailsViewController class]]];
}

+ (instancetype)contactDetailsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKContactDetailsViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKContactDetailsViewController class]]];
}

- (void)finalizeInit
{
    [super finalizeInit];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!_contactThumbnail)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    [self updatePictureButton:self.picturePlaceholder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThumbnailUpdate:) name:kMXKContactThumbnailUpdateNotification object:nil];
    
    // Force refresh
    self.contact = _contact;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)destroy
{
    matrixIDs = nil;
    
    self.delegate = nil;
    
    [super destroy];
}

#pragma mark -

- (void)setContact:(MXKContact *)contact
{
    _contact = contact;
    
    self.contactDisplayName.text = _contact.displayName;
    
    // set the thumbnail info
    [self.contactThumbnail.imageView setContentMode: UIViewContentModeScaleAspectFill];
    [self.contactThumbnail.imageView setClipsToBounds:YES];
    
    if (_contact.thumbnail)
    {
        [self updatePictureButton:_contact.thumbnail];
    }
    else
    {
        [self updatePictureButton:self.picturePlaceholder];
    }
}

- (UIImage*)picturePlaceholder
{
    return [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"default-profile"];
}

- (IBAction)onContactThumbnailPressed:(id)sender
{
    // Do nothing by default
}

#pragma mark - UITableView datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    matrixIDs = _contact.matrixIdentifiers;
    return matrixIDs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    MXKTableViewCellWithLabelAndButton *cell = [tableView dequeueReusableCellWithIdentifier:[MXKTableViewCellWithLabelAndButton defaultReuseIdentifier]];
    if (!cell)
    {
        cell = [[MXKTableViewCellWithLabelAndButton alloc] init];
    }
    
    if (row < matrixIDs.count)
    {
        cell.mxkLabel.text = [matrixIDs objectAtIndex:row];
    }
    else
    {
        // should never happen
        cell.mxkLabel.text = @"";
    }
    
    [cell.mxkButton setTitle:[VectorL10n startChat] forState:UIControlStateNormal];
    [cell.mxkButton setTitle:[VectorL10n startChat] forState:UIControlStateHighlighted];
    cell.mxkButton.tag = row;
    [cell.mxkButton addTarget:self action:@selector(startChat:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

#pragma mark - Internals

- (void)updatePictureButton:(UIImage*)image
{
    [self.contactThumbnail setImage:image forState:UIControlStateNormal];
    [self.contactThumbnail setImage:image forState:UIControlStateHighlighted];
    [self.contactThumbnail setImage:image forState:UIControlStateDisabled];
}

- (void)startChat:(UIButton*)sender
{
    if (self.delegate && sender.tag < matrixIDs.count)
    {
        sender.enabled = NO;
        
        [self.delegate contactDetailsViewController:self startChatWithMatrixId:[matrixIDs objectAtIndex:sender.tag] completion:^{
            
            sender.enabled = YES;
            
        }];
    }
}

- (void)onThumbnailUpdate:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* contactID = notif.object;
        
        if ([contactID isEqualToString:self.contact.contactID])
        {
            if (_contact.thumbnail)
            {
                [self updatePictureButton:_contact.thumbnail];
            }
            else
            {
                [self updatePictureButton:self.picturePlaceholder];
            }
        }
    }
}

@end
