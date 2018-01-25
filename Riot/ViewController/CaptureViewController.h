//
//  CaptureViewController.h
//  Riot
//
//  Created by Ian on 1/13/18.
//  Copyright © 2018 matrix.org. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLSimpleCamera.h"

@interface CaptureViewController : UIViewController

/**
 The array of the media types supported by the camera (default value is an array containing kUTTypeImage).
 */
@property (nonatomic) NSArray *mediaTypes;

@end
