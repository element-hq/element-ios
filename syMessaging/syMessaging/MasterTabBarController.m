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

#import "MasterTabBarController.h"
#import "MatrixHandler.h"

@interface MasterTabBarController ()

@end

@implementation MasterTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (! [[MatrixHandler sharedHandler] isLogged]) {
        [self showLoginScreen];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showLoginScreen {
    [self performSegueWithIdentifier:@"showLogin" sender:self];
}

- (void)showRoomDetails:(NSString*)roomId {
    // Switch on recent
    [self setSelectedIndex:TABBAR_RECENTS_INDEX];
    //TODO
}

@end
