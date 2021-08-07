//
//  YXBasicSCETDelegate.h
//  UniversalApp
//
//  Created by liaoshen on 2021/6/16.
//  Copyright © 2021 voidcat. All rights reserved.
//

#import "SCETDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface YXBasicSCETDelegate : SCETDelegate
@property (nonatomic, copy) void(^BlockTableViewDidSelectRowAtIndexPath) (UITableView *tableView, NSIndexPath *indexPath);

@property (nonatomic, copy) CGFloat(^BlockTableViewheightForHeaderInSection) (UITableView *tableView, NSInteger section);

@property (nonatomic, copy) UIView *(^BlockTableViewviewForHeaderInSection) (UITableView *tableView, NSInteger section);

@property (nonatomic, copy) void(^BlockscrollViewDidScroll) (UIScrollView *scrollView);
@end

NS_ASSUME_NONNULL_END
