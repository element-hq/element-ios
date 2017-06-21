/*
 Copyright 2017 Aram Sargsyan
 
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

#import "ReadReceiptsViewController.h"
#import <MatrixKit/MatrixKit.h>

@interface ReadReceiptsViewController () <UITableViewDataSource>

@property (nonatomic) MXRestClient* restClient;

@property (nonatomic) NSArray <MXRoomMember *> *roomMembers;
@property (nonatomic) NSArray <UIImage *> *placeholders;
@property (nonatomic) NSArray <NSString *> *recieptDescriptions;

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic) IBOutlet UITableView *receiptsTableView;

@end

@implementation ReadReceiptsViewController

#pragma mark - Public

+ (void)openInViewController:(UIViewController *)viewController withRestClient:(MXRestClient *)restClient withRoomMembers:(NSArray <MXRoomMember *> *)roomMembers placeholders:(NSArray <UIImage *> *)placeholders receiptDescriptions:(NSArray <NSString *> *)receiptDescriptions
{
    ReadReceiptsViewController *receiptsController = [[[self class] alloc] initWithNibName:NSStringFromClass([self class]) bundle:nil];
    receiptsController.restClient = restClient;
    receiptsController.roomMembers = roomMembers;
    receiptsController.placeholders = placeholders;
    receiptsController.recieptDescriptions = receiptDescriptions;
    
    receiptsController.providesPresentationContextTransitionStyle = YES;
    receiptsController.definesPresentationContext = YES;
    receiptsController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    receiptsController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [viewController presentViewController:receiptsController animated:YES completion:nil];
}

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configureViews];
    [self configureReceiptsTableView];
    [self addOverlayViewGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Views

- (void)configureViews {
    self.containerView.layer.cornerRadius = 20;
    self.titleLabel.text = @"Read Receipts List";
}

- (void)configureReceiptsTableView {
    self.receiptsTableView.dataSource = self;
    [self.receiptsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"id"];
    
    //[self.receiptsTableView registerNib:[MXKReadReceiptTableview nib] forCellReuseIdentifier:@"s"];
    
}

- (void)addOverlayViewGesture {
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTap)];
    [tapRecognizer setNumberOfTapsRequired:1];
    [tapRecognizer setNumberOfTouchesRequired:1];
    [self.overlayView addGestureRecognizer:tapRecognizer];
}

#pragma mark - Actions

- (void)overlayTap {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.roomMembers.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"id" forIndexPath:indexPath];
    
    //configure cell
    //add custom cell later
    if (indexPath.row < self.roomMembers.count)
    {
        cell.textLabel.text = self.roomMembers[indexPath.row].displayname;
    }
    if (indexPath.row < self.placeholders.count)
    {
        [cell.imageView setImage:self.placeholders[indexPath.row]];
    }
    if (indexPath.row < self.recieptDescriptions.count)
    {
        cell.detailTextLabel.text = self.recieptDescriptions[indexPath.row];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}


@end
