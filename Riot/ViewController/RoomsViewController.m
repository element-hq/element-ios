/*
 Copyright 2017 Vector Creations Ltd

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

#import "RoomsViewController.h"

#import "AppDelegate.h"

#import "RecentsDataSource.h"

@implementation RoomsViewController

- (void)finalizeInit
{
    [super finalizeInit];
    
    self.screenName = @"Rooms";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.accessibilityIdentifier = @"RoomsVCView";
    self.recentsTableView.accessibilityIdentifier = @"RoomsVCTableView";
    
    [AppDelegate theDelegate].masterTabBarController.navigationItem.title = NSLocalizedStringFromTable(@"title_rooms", @"Vector", nil);
    
    // Add room creation button programatically
    [self addRoomCreationButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.dataSource isKindOfClass:RecentsDataSource.class])
    {
        // Take the lead on the shared data source.
        RecentsDataSource *recentsDataSource = (RecentsDataSource*)self.dataSource;
        recentsDataSource.areSectionsShrinkable = NO;
        [recentsDataSource setDelegate:self andRecentsDataSourceMode:RecentsDataSourceModeRooms];
    }
}

- (void)dealloc
{
    
}

- (void)destroy
{
    [super destroy];
}

@end
