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

#import "SegmentedViewController.h"

@interface HomeViewController : SegmentedViewController <UISearchBarDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarButtonIem;


- (void)displayWithSession:(MXSession*)session;

/**
 Action registered on `UIControlEventTouchUpInside` event for both buttons.
 */
- (IBAction)onButtonPressed:(id)sender;

@end
