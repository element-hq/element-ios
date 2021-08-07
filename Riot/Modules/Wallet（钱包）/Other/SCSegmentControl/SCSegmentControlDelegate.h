//
//  SCSegmentControlDelegate.h
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/18.
//

#import <Foundation/Foundation.h>
@class SCSegmentControl;

@protocol SCSegmentControlDelegate <NSObject>

@optional

- (void)segmentControl:(UIView *)segmentControl didSelectItemAtIndex:(NSInteger)currentItemIndex;

@end

