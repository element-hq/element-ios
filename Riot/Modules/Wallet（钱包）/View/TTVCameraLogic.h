//
//  TTVCameraLogic.h
//  TouchTV
//
//  Created by rhc on 16/10/4.
//  Copyright © 2016年 AceWei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TTVUploadImagesDelegate <NSObject>
- (void)uploadCommunityImages:(NSArray *)imagesArray;
@end


@interface TTVCameraLogic : NSObject

singleton_interface(TTVCameraLogic);

@property (nonatomic,strong,readonly) NSMutableArray  * imagesArray;
@property (nonatomic, weak) id <TTVUploadImagesDelegate>delegate;
@property (nonatomic, weak) id  withController ;
@property (nonatomic, assign) BOOL  isVerified;
- (void)didSelectPhotos ;

@end

NS_ASSUME_NONNULL_END
