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

#import "HomeSearchViewController.h"

#import "HomeSearchCellData.h"
#import "HomeSearchTableViewCell.h"

#import "EventFormatter.h"

#import "VectorDesignValues.h"

#import "RageShakeManager.h"

@implementation HomeSearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup `MXKViewControllerHandling` properties
    self.defaultBarTintColor = kVectorNavBarTintColor;
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];

    [self.searchTableView registerNib:HomeSearchTableViewCell.nib forCellReuseIdentifier:HomeSearchTableViewCell.defaultReuseIdentifier];

    self.searchTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    // Hide line separators of empty cells
    self.searchTableView.tableFooterView = [[UIView alloc] init];
}

- (void)displaySearch:(MXKSearchDataSource *)searchDataSource
{
    // Customize cell data processing for Vector
    [searchDataSource registerCellDataClass:HomeSearchCellData.class forCellIdentifier:kMXKSearchCellDataIdentifier];
    searchDataSource.eventFormatter = [[EventFormatter alloc] initWithMatrixSession:searchDataSource.mxSession];

    [super displaySearch:searchDataSource];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    return HomeSearchTableViewCell.class;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    return HomeSearchTableViewCell.defaultReuseIdentifier;
}

@end
