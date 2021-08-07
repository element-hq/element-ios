//
//  SCSegmentControl.h
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/18.
//

#import <UIKit/UIKit.h>
#import "SCSegmentControlProtocol.h"

@interface SCSegmentControl : UIView <
SCSegmentControlProtocol
>

@property (nonatomic, assign, readonly) CGSize scrollContentSize;
@property (nonatomic, assign, readonly) CGPoint scrollContentOffset;
    
@end
