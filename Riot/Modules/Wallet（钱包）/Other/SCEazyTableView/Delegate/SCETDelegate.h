//
//  SCETDelegate.h
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/7.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCETDataSource.h"

@interface SCETDelegate : NSObject <UITableViewDelegate>

@property (strong, nonatomic) SCETDataSource *dataSource;

+ (instancetype)sc_tableViewDelegateWithDataSource:(SCETDataSource *)dataSource;

- (instancetype)initTableViewDelegateWithDatSource:(SCETDataSource *)dataSource;

@end
