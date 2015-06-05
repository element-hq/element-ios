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
#import <MatrixKit/MXKImageView.h>

#import <UIKit/UIKit.h>

#import "MXCContact.h"

@interface ContactTableCell : UITableViewCell

@property (strong, nonatomic) IBOutlet MXKImageView *thumbnailView;
@property (strong, nonatomic) IBOutlet UILabel *contactDisplayNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *matrixDisplayNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *matrixIDLabel;
@property (strong, nonatomic) IBOutlet UIImageView *matrixUserIconView;

/**
 The contact displayed in the table view cell.
 Set this property nil to dispose listeners and other resources.
 */
@property (strong, nonatomic) MXCContact *contact;

@end

