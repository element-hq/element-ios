//
//  SCEazyTableViewCellProtocol.h
//  SCEazyTableView
//
//  Created by ty.Chen on 2019/3/6.
//  Copyright © 2019 ty.Chen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SCEazyTableViewCellProtocol <NSObject>

@optional

- (void)setupCellWithRowData:(id)rowData;

- (void)addInfoFlowNormalRoundedCorner;

- (void)addInfoFlowTagRoundCorner;

@end
