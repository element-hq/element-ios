//
//  SearchViewController.h
//  Vector
//
//  Created by Emmanuel ROHEE on 03/12/15.
//  Copyright © 2015 matrix.org. All rights reserved.
//

#import "SegmentedViewController.h"

@class MXSession;

@interface SearchViewController : SegmentedViewController

- (void)displayWithSession:(MXSession*)session;

@end
