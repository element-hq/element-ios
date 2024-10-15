/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKErrorAlertPresentation.h"

#import "MXKErrorPresentableBuilder.h"
#import "NSBundle+MatrixKit.h"

#import "MXKSwiftHeader.h"

@interface MXKErrorAlertPresentation()

@property (nonatomic, strong) MXKErrorPresentableBuilder *errorPresentableBuidler;

@end

#pragma mark - Implementation

@implementation MXKErrorAlertPresentation

#pragma mark - Setup & Teardown

- (instancetype)init
{
    self = [super init];
    if (self) {
        _errorPresentableBuidler = [[MXKErrorPresentableBuilder alloc] init];
    }
    return self;
}

#pragma mark - MXKErrorPresentation

- (void)presentErrorFromViewController:(UIViewController*)viewController
                                 title:(NSString*)title
                               message:(NSString*)message
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler
{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:[VectorL10n ok]
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                if (handler)
                                                {
                                                    handler();
                                                }
                                            }]];
    
    [viewController presentViewController:alert animated:animated completion:nil];
}

- (void)presentErrorFromViewController:(UIViewController*)viewController
                              forError:(NSError*)error
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler
{
    id <MXKErrorPresentable> errorPresentable = [self.errorPresentableBuidler errorPresentableFromError:error];
    
    if (errorPresentable)
    {
        [self presentErrorFromViewController:viewController
                         forErrorPresentable:errorPresentable
                                    animated:animated
                                     handler:handler];
    }
}

- (void)presentGenericErrorFromViewController:(UIViewController*)viewController
                                     animated:(BOOL)animated
                                      handler:(void (^)(void))handler
{
    id <MXKErrorPresentable> errorPresentable = [self.errorPresentableBuidler commonErrorPresentable];
    
    [self presentErrorFromViewController:viewController
                     forErrorPresentable:errorPresentable
                                animated:animated
                                 handler:handler];
}

- (void)presentErrorFromViewController:(UIViewController*)viewController
                   forErrorPresentable:(id<MXKErrorPresentable>)errorPresentable
                              animated:(BOOL)animated
                               handler:(void (^)(void))handler
{
    [self presentErrorFromViewController:viewController
                                   title:errorPresentable.title
                                 message:errorPresentable.message
                                animated:animated
                                 handler:handler];
}

@end
