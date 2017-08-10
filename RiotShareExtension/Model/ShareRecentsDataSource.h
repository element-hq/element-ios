//
//  ShareRecentsDataSource.h
//  Riot
//
//  Created by Aram Sargsyan on 8/10/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

#import <MatrixKit/MatrixKit.h>

typedef NS_ENUM(NSInteger, ShareRecentsDataSourceMode)
{
    RecentsDataSourceModePeople,
    RecentsDataSourceModeRooms
};

@interface ShareRecentsDataSource : MXKRecentsDataSource

- (instancetype)initWithMatrixSession:(MXSession *)mxSession dataSourceMode:(ShareRecentsDataSourceMode)dataSourceMode;

@end
