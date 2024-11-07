/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKPreviewViewController.h"
@import QuickLook;

@interface MXKPreviewViewController () <QLPreviewControllerDataSource>

/// A specialized view controller for previewing an item.
@property (nonatomic, weak) QLPreviewController *previewController;

/// URL of the file to preview
@property (nonatomic, strong) NSURL *fileURL;

/// YES to display actions Button. NO otherwise
@property (nonatomic) BOOL allowActions;

@property (nonatomic, weak) id<MXKPreviewViewControllerDelegate> previewDelegate;

@end

@implementation MXKPreviewViewController

+ (MXKPreviewViewController *)presentFrom:(UIViewController *)presenting fileUrl:(NSURL *)fileUrl allowActions:(BOOL)allowActions delegate:(nullable id<MXKPreviewViewControllerDelegate>)delegate
{
    MXKPreviewViewController *previewController = [[MXKPreviewViewController alloc] initWithFileUrl: fileUrl allowActions: allowActions];
    previewController.previewDelegate = delegate;
    if ([delegate respondsToSelector:@selector(previewViewControllerWillBeginPreview:)]) {
        [delegate previewViewControllerWillBeginPreview:previewController];
    }
    [presenting presentViewController:previewController animated:YES completion:^{
    }];
    
    return previewController;
}

- (instancetype)initWithFileUrl: (NSURL *)fileUrl allowActions: (BOOL)allowActions
{
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    self = [super initWithRootViewController:previewController];
    self.previewController = previewController;
    
    if (self)
    {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.fileURL = fileUrl;
        self.allowActions = allowActions;
        self.previewController.dataSource = self;
        self.previewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    }
    
    return self;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!self.allowActions)
    {
        NSMutableArray *items = [NSMutableArray arrayWithArray: self.previewController.navigationItem.rightBarButtonItems];
        if (items.count > 0)
        {
            [items removeObjectAtIndex:0];
        }
        self.previewController.navigationItem.rightBarButtonItems = items;
    }
}

- (IBAction)doneAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.previewDelegate respondsToSelector:@selector(previewViewControllerDidEndPreview:)]) {
            [self.previewDelegate previewViewControllerDidEndPreview:self];
        }
    }];
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(nonnull QLPreviewController *)controller
{
    return self.fileURL ? 1 : 0;
}

- (nonnull id<QLPreviewItem>)previewController:(nonnull QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return self.fileURL;
}

@end
