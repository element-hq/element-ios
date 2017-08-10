//
//  ShareExtensionManager.h
//  Riot
//
//  Created by Aram Sargsyan on 8/10/17.
//  Copyright © 2017 matrix.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MatrixKit/MatrixKit.h>

@interface ShareExtensionManager : NSObject

@property NSExtensionContext *shareExtensionContext;

+ (instancetype)sharedManager;

- (void)sendContentToRoom:(MXRoom *)room failureBlock:(void(^)())failureBlock;

- (void)cancelSharing;

- (void)cancelSharingWithFailure;

@end
