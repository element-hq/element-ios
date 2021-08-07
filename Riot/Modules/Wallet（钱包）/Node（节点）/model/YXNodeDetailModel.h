//
//  YXNodeDetailModel.h
//  lianliao
//
//  Created by liaoshen on 2021/6/28.
//  Copyright © 2021 https://www.vpubchain.info. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YXNodeListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface YXNodeDetailModel : NSObject
@property (nonatomic , assign) CGFloat cellHeight;
@property (nonatomic , assign) CGFloat descHeight;
@property (nonatomic , assign) BOOL showLine;
@property (nonatomic , copy) NSString *cellName;
@property (nonatomic , copy) NSString *title;
@property (nonatomic , copy) NSString *desc;

- (NSMutableArray <YXNodeDetailModel *>*)getCellArray:(YXNodeListdata *)model;

@end

NS_ASSUME_NONNULL_END
