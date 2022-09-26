/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKAttachmentsViewController.h"

#import <WebKit/WebKit.h>

@import MatrixSDK.MXMediaManager;

#import "MXKMediaCollectionViewCell.h"

#import "MXKPieChartView.h"

#import "MXKConstants.h"

#import "MXKTools.h"

#import "NSBundle+MatrixKit.h"

#import "MXKEventFormatter.h"

#import "MXKAttachmentInteractionController.h"

#import "MXKSwiftHeader.h"

#import "LegacyAppDelegate.h"

@interface MXKAttachmentsViewController () <UINavigationControllerDelegate, UIViewControllerTransitioningDelegate>
{
    /**
     Current alert (if any).
     */
    UIAlertController *currentAlert;
    
    /**
     Navigation bar handling
     */
    NSTimer *navigationBarDisplayTimer;
    
    /**
     SplitViewController handling
     */
    BOOL shouldRestoreBottomBar;
    UISplitViewControllerDisplayMode savedSplitViewControllerDisplayMode;
    
    /**
     Audio session handling
     */
    NSString *savedAVAudioSessionCategory;
    
    /**
     The attachments array (MXAttachment instances).
     */
    NSMutableArray *attachments;
    
    /**
     The index of the current visible collection item
     */
    NSInteger currentVisibleItemIndex;
    
    /**
     The document interaction Controller used to share attachment
     */
    UIDocumentInteractionController *documentInteractionController;
    MXKAttachment *currentSharedAttachment;
    
    /**
     Tells whether back pagination is in progress.
     */
    BOOL isBackPaginationInProgress;
    
    /**
     A temporary file used to store decrypted attachments
     */
    NSString *tempFile;
    
    /**
     Path to a file containing video data for the currently selected
     attachment, if it's a video attachment and the data is
     available.
     */
    NSString *videoFile;
}

//animations
@property (nonatomic) MXKAttachmentInteractionController *interactionController;

@property (nonatomic, weak) UIViewController <MXKSourceAttachmentAnimatorDelegate> *sourceViewController;

@property (nonatomic) UIImageView *originalImageView;
@property (nonatomic) CGRect convertedFrame;

@property (nonatomic) BOOL customAnimationsEnabled;

@end

@implementation MXKAttachmentsViewController
@synthesize attachments;

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKAttachmentsViewController class])
                          bundle:[NSBundle bundleForClass:[MXKAttachmentsViewController class]]];
}

+ (instancetype)attachmentsViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKAttachmentsViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKAttachmentsViewController class]]];
}

+ (instancetype)animatedAttachmentsViewControllerWithSourceViewController:(UIViewController <MXKSourceAttachmentAnimatorDelegate> *)sourceViewController
{
    MXKAttachmentsViewController *attachmentsController = [[[self class] alloc] initWithNibName:NSStringFromClass([MXKAttachmentsViewController class])
                                                                                         bundle:[NSBundle bundleForClass:[MXKAttachmentsViewController class]]];
    
    //create an interactionController for it to handle the gestue recognizer and control the interactions
    attachmentsController.interactionController = [[MXKAttachmentInteractionController alloc] initWithDestinationViewController:attachmentsController sourceViewController:sourceViewController];
    
    //we use the animationsEnabled property to enable/disable animations. Instances created not using this method should use the default animations
    attachmentsController.customAnimationsEnabled = YES;
    
    //this properties will be needed by animationControllers in order to perform the animations
    attachmentsController.sourceViewController = sourceViewController;
    
    //setting transitioningDelegate and navigationController.delegate so that the animations will work for present/dismiss as well as push/pop
    attachmentsController.transitioningDelegate = attachmentsController;
    sourceViewController.navigationController.delegate = attachmentsController;
    
    
    return attachmentsController;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    tempFile = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!_attachmentsCollection)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    self.backButton.image = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"back_icon"];
    
    // Register collection view cell class
    [self.attachmentsCollection registerClass:MXKMediaCollectionViewCell.class forCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier]];
    
    // Hide collection to hide first scrolling into the attachments.
    _attachmentsCollection.hidden = YES;
    
    // Display collection cell in full screen
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated"
    self.automaticallyAdjustsScrollViewInsets = NO;
    #pragma clang diagnostic pop
}

- (BOOL)prefersStatusBarHidden
{
    // Hide status bar.
    // Caution: Enable [UIViewController prefersStatusBarHidden] use at application level
    // by turning on UIViewControllerBasedStatusBarAppearance in Info.plist.
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    videoFile = nil;
    
    savedAVAudioSessionCategory = [[AVAudioSession sharedInstance] category];
    
    // Hide navigation bar by default.
    [self hideNavigationBar];
    
    // Hide status bar
    // TODO: remove this [UIApplication statusBarHidden] use (deprecated since iOS 9).
    // Note: setting statusBarHidden does nothing if your application is using the default UIViewController-based status bar system.
    UIApplication *sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
    if (sharedApplication)
    {
        sharedApplication.statusBarHidden = YES;
    }
    
    // Handle here the case of splitviewcontroller use on iOS 8 and later.
    if (self.splitViewController && [self.splitViewController respondsToSelector:@selector(displayMode)])
    {
        if (self.hidesBottomBarWhenPushed)
        {
            // This screen should be displayed without tabbar, but hidesBottomBarWhenPushed flag has no effect in case of splitviewcontroller use.
            // Trick: on iOS 8 and later the tabbar is hidden manually
            shouldRestoreBottomBar = YES;
            self.tabBarController.tabBar.hidden = YES;
        }
        
        // Hide the primary view controller to allow full screen display
        savedSplitViewControllerDisplayMode = [self.splitViewController displayMode];
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
        [self.splitViewController.view layoutIfNeeded];
    }
    
    [_attachmentsCollection reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Adjust content offset and make visible the attachmnet collections
    [self refreshAttachmentCollectionContentOffset];
    _attachmentsCollection.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (tempFile)
    {
        NSError *err;
        [[NSFileManager defaultManager] removeItemAtPath:tempFile error:&err];
        tempFile = nil;
    }
    
    if (currentAlert)
    {
        [currentAlert dismissViewControllerAnimated:NO completion:nil];
        currentAlert = nil;
    }
    
    // Stop playing any video
    for (MXKMediaCollectionViewCell *cell in self.attachmentsCollection.visibleCells)
    {
        [cell.moviePlayer.player pause];
        cell.moviePlayer.player = nil;
    }
    
    // Restore audio category
    if (savedAVAudioSessionCategory)
    {
        [[AVAudioSession sharedInstance] setCategory:savedAVAudioSessionCategory error:nil];
        savedAVAudioSessionCategory = nil;
    }
    
    [navigationBarDisplayTimer invalidate];
    navigationBarDisplayTimer = nil;
    
    // Restore status bar
    // TODO: remove this [UIApplication statusBarHidden] use (deprecated since iOS 9).
    // Note: setting statusBarHidden does nothing if your application is using the default UIViewController-based status bar system.
    UIApplication *sharedApplication = [UIApplication performSelector:@selector(sharedApplication)];
    if (sharedApplication)
    {
        sharedApplication.statusBarHidden = NO;
    }
    
    if (shouldRestoreBottomBar)
    {
        self.tabBarController.tabBar.hidden = NO;
    }
    
    if (self.splitViewController && [self.splitViewController respondsToSelector:@selector(displayMode)])
    {
        self.splitViewController.preferredDisplayMode = savedSplitViewControllerDisplayMode;
        [self.splitViewController.view layoutIfNeeded];
    }
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    [self destroy];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(coordinator.transitionDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // Cell width will be updated, force collection layout refresh to take into account the changes
        [self->_attachmentsCollection.collectionViewLayout invalidateLayout];
        
        // Refresh the current attachment display
        [self refreshAttachmentCollectionContentOffset];
        
    });
}

#pragma mark - Override MXKViewController

- (void)destroy
{
    if (documentInteractionController)
    {
        [documentInteractionController dismissPreviewAnimated:NO];
        [documentInteractionController dismissMenuAnimated:NO];
        documentInteractionController = nil;
    }
    
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
    
    if (self.sourceViewController)
    {
        self.sourceViewController.navigationController.delegate = nil;
        self.sourceViewController = nil;
    }
    
    [super destroy];
}

#pragma mark - Public API

- (void)displayAttachments:(NSArray*)attachmentArray focusOn:(NSString*)eventId
{
    if ([attachmentArray isEqualToArray:attachments] && eventId.length == 0)
    {
        //  neither the attachments nor the focus changed, can be ignored
        return;
    }
    NSString *currentAttachmentEventId = eventId;
    NSString *currentAttachmentOriginalFileName = nil;
    
    if (currentAttachmentEventId.length == 0 && attachments)
    {
        if (isBackPaginationInProgress && currentVisibleItemIndex == 0)
        {
            // Here the spinner were displayed, we update the viewer by displaying the first added attachment
            // (the one just added before the first item of the current attachments array).
            if (attachments.count)
            {
                // Retrieve the event id of the first item in the current attachments array
                MXKAttachment *attachment = attachments[0];
                NSString *firstAttachmentEventId = attachment.eventId;
                NSString *firstAttachmentOriginalFileName = nil;
                
                // The original file name is used when the attachment is a local echo.
                // Indeed its event id may be replaced by the actual one in the new attachments array.
                if ([firstAttachmentEventId hasPrefix:kMXEventLocalEventIdPrefix])
                {
                    firstAttachmentOriginalFileName = attachment.originalFileName;
                }
                
                // Look for the attachment added before this attachment in new array.
                for (attachment in attachmentArray)
                {
                    if (firstAttachmentOriginalFileName && [attachment.originalFileName isEqualToString:firstAttachmentOriginalFileName])
                    {
                        break;
                    }
                    else if ([attachment.eventId isEqualToString:firstAttachmentEventId])
                    {
                        break;
                    }
                    currentAttachmentEventId = attachment.eventId;
                }
            }
        }
        else if (currentVisibleItemIndex != NSNotFound)
        {
            // Compute the attachment index
            NSUInteger currentAttachmentIndex = (isBackPaginationInProgress ? currentVisibleItemIndex - 1 : currentVisibleItemIndex);
            
            if (currentAttachmentIndex < attachments.count)
            {
                MXKAttachment *attachment = attachments[currentAttachmentIndex];
                currentAttachmentEventId = attachment.eventId;
                
                // The original file name is used when the attachment is a local echo.
                // Indeed its event id may be replaced by the actual one in the new attachments array.
                if ([currentAttachmentEventId hasPrefix:kMXEventLocalEventIdPrefix])
                {
                    currentAttachmentOriginalFileName = attachment.originalFileName;
                }
            }
        }
    }
    
    // Stop back pagination (Do not call here 'stopBackPaginationActivity' because a full collection reload is planned at the end).
    isBackPaginationInProgress = NO;
    
    // Set/reset the attachments array
    attachments = [NSMutableArray arrayWithArray:attachmentArray];
    
    // Update the index of the current displayed attachment by looking for the
    // current event id (or the current original file name, if any) in the new attachments array.
    currentVisibleItemIndex = 0;
    if (currentAttachmentEventId)
    {
        for (NSUInteger index = 0; index < attachments.count; index++)
        {
            MXKAttachment *attachment = attachments[index];
            
            // Check first the original filename if any.
            if (currentAttachmentOriginalFileName && [attachment.originalFileName isEqualToString:currentAttachmentOriginalFileName])
            {
                currentVisibleItemIndex = index;
                break;
            }
            // Check the event id then
            else if ([attachment.eventId isEqualToString:currentAttachmentEventId])
            {
                currentVisibleItemIndex = index;
                break;
            }
        }
    }
    
    // Refresh
    [_attachmentsCollection reloadData];
    
    // Adjust content offset
    [self refreshAttachmentCollectionContentOffset];
}

- (void)setComplete:(BOOL)complete
{
    _complete = complete;
    
    if (complete)
    {
        [self stopBackPaginationActivity];
    }
}

- (IBAction)onButtonPressed:(id)sender
{
    if (sender == self.backButton)
    {
        [self withdrawViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Privates

- (IBAction)hideNavigationBar
{
    self.navigationBarContainer.hidden = YES;
    
    [navigationBarDisplayTimer invalidate];
    navigationBarDisplayTimer = nil;
}

- (void)refreshCurrentVisibleItemIndex
{
    // Check whether the collection is actually rendered
    if (_attachmentsCollection.contentSize.width)
    {
        // Get the window from the app delegate as this can be called before the view is presented.
        UIWindow *window = LegacyAppDelegate.theDelegate.window;
        currentVisibleItemIndex = _attachmentsCollection.contentOffset.x / window.bounds.size.width;
    }
    else
    {
        currentVisibleItemIndex = NSNotFound;
    }
}

- (void)refreshAttachmentCollectionContentOffset
{
    if (currentVisibleItemIndex != NSNotFound && _attachmentsCollection)
    {
        // Get the window from the app delegate as this can be called before the view is presented.
        UIWindow *window = LegacyAppDelegate.theDelegate.window;
        
        // Set the content offset to display the current attachment
        CGPoint contentOffset = _attachmentsCollection.contentOffset;
        contentOffset.x = currentVisibleItemIndex * window.bounds.size.width;
        _attachmentsCollection.contentOffset = contentOffset;
    }
}

- (void)refreshCurrentVisibleCell
{
    // In case of attached image, load here the high res image.
    
    [self refreshCurrentVisibleItemIndex];
    
    if (currentVisibleItemIndex == NSNotFound) {
        // Tell the delegate that no attachment is displayed for the moment
        if ([self.delegate respondsToSelector:@selector(displayedNewAttachmentWithEventId:)])
        {
            [self.delegate displayedNewAttachmentWithEventId:nil];
        }
    }
    else
    {
        NSInteger item = currentVisibleItemIndex;
        if (isBackPaginationInProgress)
        {
            if (item == 0)
            {
                // Tell the delegate that no attachment is displayed for the moment
                if ([self.delegate respondsToSelector:@selector(displayedNewAttachmentWithEventId:)])
                {
                    [self.delegate displayedNewAttachmentWithEventId:nil];
                }
                
                return;
            }
            
            item --;
        }
        
        if (item < attachments.count)
        {
            MXKAttachment *attachment = attachments[item];
            NSString *mimeType = attachment.contentInfo[@"mimetype"];
            
            // Tell the delegate which attachment has been shown using its eventId
            if ([self.delegate respondsToSelector:@selector(displayedNewAttachmentWithEventId:)])
            {
                [self.delegate displayedNewAttachmentWithEventId:attachment.eventId];
            }
            
            // Check attachment type
            if (attachment.type == MXKAttachmentTypeImage && attachment.contentURL && ![mimeType isEqualToString:@"image/gif"])
            {
                // Retrieve the related cell
                UICollectionViewCell *cell = [_attachmentsCollection cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentVisibleItemIndex inSection:0]];
                if ([cell isKindOfClass:[MXKMediaCollectionViewCell class]])
                {
                    MXKMediaCollectionViewCell *mediaCollectionViewCell = (MXKMediaCollectionViewCell*)cell;
                    
                    // Load high res image
                    mediaCollectionViewCell.mxkImageView.stretchable = YES;
                    mediaCollectionViewCell.mxkImageView.enableInMemoryCache = NO;
                    
                    [mediaCollectionViewCell.mxkImageView setAttachment:attachment];
                }
            }
        }
    }
}

- (void)stopBackPaginationActivity
{
    if (isBackPaginationInProgress)
    {
        isBackPaginationInProgress = NO;
        
        [self.attachmentsCollection deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    }
}

- (void)prepareVideoForItem:(NSInteger)item success:(void(^)(void))success failure:(void(^)(NSError *))failure
{
    MXKAttachment *attachment = attachments[item];
    if (attachment.isEncrypted)
    {
        [attachment decryptToTempFile:^(NSString *file) {
            if (self->tempFile)
            {
                [[NSFileManager defaultManager] removeItemAtPath:self->tempFile error:nil];
            }
            self->tempFile = file;
            self->videoFile = file;
            success();
        } failure:^(NSError *error) {
            if (failure) failure(error);
        }];
    }
    else
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:attachment.cacheFilePath])
        {
            videoFile = attachment.cacheFilePath;
            success();
        }
        else
        {
            [attachment prepare:^{
                self->videoFile = attachment.cacheFilePath;
                success();
            } failure:^(NSError *error) {
                if (failure) failure(error);
            }];
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (isBackPaginationInProgress)
    {
        return (attachments.count + 1);
    }
    
    return attachments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MXKMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier]
                                                                                 forIndexPath:indexPath];
    
    NSInteger item = indexPath.item;
    
    if (isBackPaginationInProgress)
    {
        if (item == 0)
        {
            cell.mxkImageView.hidden = YES;
            cell.customView.hidden = NO;
            
            // Add back pagination spinner
            UIActivityIndicatorView* spinner  = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
            spinner.hidesWhenStopped = NO;
            spinner.backgroundColor = [UIColor clearColor];
            [spinner startAnimating];
            
            spinner.center = cell.customView.center;
            [cell.customView addSubview:spinner];
            
            return cell;
        }
        
        item --;
    }
    
    if (item < attachments.count)
    {
        MXKAttachment *attachment = attachments[item];
        NSString *mimeType = attachment.contentInfo[@"mimetype"];
        
        // Use the cached thumbnail (if any) as preview
        UIImage* preview = [attachment getCachedThumbnail];
        
        // Check attachment type
        if ((attachment.type == MXKAttachmentTypeImage || attachment.type == MXKAttachmentTypeSticker) && attachment.contentURL)
        {
            if ([mimeType isEqualToString:@"image/gif"])
            {
                cell.mxkImageView.hidden = YES;
                // Set the preview as the default image even if the image view is hidden. It will be used during zoom out animation.
                cell.mxkImageView.image = preview;
                
                cell.customView.hidden = NO;
                
                // Animated gif is displayed in webview
                CGFloat minSize = (cell.frame.size.width < cell.frame.size.height) ? cell.frame.size.width : cell.frame.size.height;
                CGFloat width, height;
                if (attachment.contentInfo[@"w"] && attachment.contentInfo[@"h"])
                {
                    width = [attachment.contentInfo[@"w"] integerValue];
                    height = [attachment.contentInfo[@"h"] integerValue];
                    if (width > minSize || height > minSize)
                    {
                        if (width > height)
                        {
                            height = (height * minSize) / width;
                            height = floorf(height / 2) * 2;
                            width = minSize;
                        }
                        else
                        {
                            width = (width * minSize) / height;
                            width = floorf(width / 2) * 2;
                            height = minSize;
                        }
                    }
                    else
                    {
                        width = minSize;
                        height = minSize;
                    }
                }
                else
                {
                    width = minSize;
                    height = minSize;
                }

                WKWebView *animatedGifViewer = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
                animatedGifViewer.center = cell.customView.center;
                animatedGifViewer.opaque = NO;
                animatedGifViewer.backgroundColor = cell.customView.backgroundColor;
                animatedGifViewer.contentMode = UIViewContentModeScaleAspectFit;
                animatedGifViewer.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
                animatedGifViewer.userInteractionEnabled = NO;
                [cell.customView addSubview:animatedGifViewer];
                
                UIImageView *previewImage = [[UIImageView alloc] initWithFrame:animatedGifViewer.frame];
                previewImage.contentMode = animatedGifViewer.contentMode;
                previewImage.autoresizingMask = animatedGifViewer.autoresizingMask;
                previewImage.image = preview;
                previewImage.center = cell.customView.center;
                [cell.customView addSubview:previewImage];
                
                MXKPieChartView *pieChartView = [[MXKPieChartView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
                pieChartView.progress = 0;
                pieChartView.progressColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
                pieChartView.unprogressColor = [UIColor clearColor];
                pieChartView.autoresizingMask = animatedGifViewer.autoresizingMask;
                pieChartView.center = cell.customView.center;
                [cell.customView addSubview:pieChartView];
                
                // Add download progress observer
                NSString *downloadId = attachment.downloadId;
                cell.notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXMediaLoaderStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                    
                    MXMediaLoader *loader = (MXMediaLoader*)notif.object;
                    if ([loader.downloadId isEqualToString:downloadId])
                    {
                        // update the image
                        switch (loader.state) {
                            case MXMediaLoaderStateDownloadInProgress:
                            {
                                NSNumber* progressNumber = [loader.statisticsDict valueForKey:kMXMediaLoaderProgressValueKey];
                                if (progressNumber)
                                {
                                    pieChartView.progress = progressNumber.floatValue;
                                }
                                break;
                            }
                            default:
                                break;
                        }
                    }
                    
                }];
                
                void (^onDownloaded)(NSData *) = ^(NSData *data){
                    if (cell.notificationObserver)
                    {
                        [[NSNotificationCenter defaultCenter] removeObserver:cell.notificationObserver];
                        cell.notificationObserver = nil;
                    }
                    
                    if (animatedGifViewer.superview)
                    {
                        [animatedGifViewer loadData:data MIMEType:@"image/gif" characterEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:@"http://"]];
                        
                        [pieChartView removeFromSuperview];
                        [previewImage removeFromSuperview];
                    }
                };
                
                void (^onFailure)(NSError *) = ^(NSError *error){
                    if (cell.notificationObserver)
                    {
                        [[NSNotificationCenter defaultCenter] removeObserver:cell.notificationObserver];
                        cell.notificationObserver = nil;
                    }
                    
                    MXLogDebug(@"[MXKAttachmentsVC] gif download failed");
                    // Notify MatrixKit user
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                };
                
                
                [attachment getAttachmentData:^(NSData *data) {
                    onDownloaded(data);
                } failure:^(NSError *error) {
                    onFailure(error);
                }];
            }
            else if (indexPath.item == currentVisibleItemIndex)
            {
                // Load high res image
                cell.mxkImageView.stretchable = YES;
                [cell.mxkImageView setAttachment:attachment];
            }
            else
            {
                // Use the thumbnail here - Full res images should only be downloaded explicitly when requested (see [self refreshCurrentVisibleItemIndex])
                cell.mxkImageView.stretchable = YES;
                [cell.mxkImageView setAttachmentThumb:attachment];
            }
        }
        else if (attachment.type == MXKAttachmentTypeVideo && attachment.contentURL)
        {
            cell.mxkImageView.mediaFolder = attachment.eventRoomId;
            cell.mxkImageView.stretchable = NO;
            cell.mxkImageView.enableInMemoryCache = YES;
            // Display video thumbnail, the video is played only when user selects this cell
            [cell.mxkImageView setAttachmentThumb:attachment];
            
            cell.centerIcon.image = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"play"];
            cell.centerIcon.hidden = NO;
        }
        
        // Add gesture recognizers on collection cell to handle tap and long press on collection cell.
        // Note: tap gesture recognizer is required here because mxkImageView enables user interaction to allow image stretching.
        // [collectionView:didSelectItemAtIndexPath] is not triggered when mxkImageView is displayed.
        UITapGestureRecognizer *cellTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCollectionViewCellTap:)];
        [cellTapGesture setNumberOfTouchesRequired:1];
        [cellTapGesture setNumberOfTapsRequired:1];
        cell.tag = item;
        [cell addGestureRecognizer:cellTapGesture];
        
        UILongPressGestureRecognizer *cellLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onCollectionViewCellLongPress:)];
        [cell addGestureRecognizer:cellLongPressGesture];
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger item = indexPath.item;
    
    BOOL navigationBarDisplayHandled = NO;
    
    if (isBackPaginationInProgress)
    {
        if (item == 0)
        {
            return;
        }
        
        item --;
    }
    
    // Check whether the selected attachment is a video
    if (item < attachments.count)
    {
        MXKAttachment *attachment = attachments[item];
        
        if (attachment.type == MXKAttachmentTypeVideo && attachment.contentURL)
        {
            MXKMediaCollectionViewCell *selectedCell = (MXKMediaCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
            
            // Add movie player if none
            if (selectedCell.moviePlayer == nil)
            {
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                
                selectedCell.moviePlayer = [[AVPlayerViewController alloc] init];
                if (selectedCell.moviePlayer != nil)
                {
                    // Switch in custom view
                    selectedCell.mxkImageView.hidden = YES;
                    selectedCell.customView.hidden = NO;
                    
                    // Report the video preview
                    UIImageView *previewImage = [[UIImageView alloc] initWithFrame:selectedCell.customView.frame];
                    previewImage.contentMode = UIViewContentModeScaleAspectFit;
                    previewImage.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
                    previewImage.image = selectedCell.mxkImageView.image;
                    previewImage.center = selectedCell.customView.center;
                    [selectedCell.customView addSubview:previewImage];
                    
                    selectedCell.moviePlayer.videoGravity = AVLayerVideoGravityResizeAspect;
                    selectedCell.moviePlayer.view.frame = selectedCell.customView.frame;
                    selectedCell.moviePlayer.view.center = selectedCell.customView.center;
                    selectedCell.moviePlayer.view.hidden = YES;
                    [selectedCell.customView addSubview:selectedCell.moviePlayer.view];

                    // Force the video to stay in fullscreen
                    NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:selectedCell.moviePlayer.view
                                                                                     attribute:NSLayoutAttributeTop
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:selectedCell.customView
                                                                                     attribute:NSLayoutAttributeTop
                                                                                    multiplier:1.0f
                                                                                      constant:0.0f];

                    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:selectedCell.moviePlayer.view
                                                                                          attribute:NSLayoutAttributeLeading
                                                                                          relatedBy:0
                                                                                             toItem:selectedCell.customView
                                                                                          attribute:NSLayoutAttributeLeading
                                                                                         multiplier:1.0
                                                                                           constant:0];

                    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:selectedCell.moviePlayer.view
                                                                                        attribute:NSLayoutAttributeBottom
                                                                                        relatedBy:0
                                                                                           toItem:selectedCell.customView
                                                                                        attribute:NSLayoutAttributeBottom
                                                                                       multiplier:1
                                                                                         constant:0];

                    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:selectedCell.moviePlayer.view
                                                                                         attribute:NSLayoutAttributeTrailing
                                                                                         relatedBy:0
                                                                                            toItem:selectedCell.customView
                                                                                         attribute:NSLayoutAttributeTrailing
                                                                                        multiplier:1.0
                                                                                          constant:0];
                    
                    selectedCell.moviePlayer.view.translatesAutoresizingMaskIntoConstraints = NO;

                    [NSLayoutConstraint activateConstraints:@[topConstraint, leadingConstraint, bottomConstraint, trailingConstraint]];
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(moviePlayerPlaybackDidFinishWithErrorNotification:)
                                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                               object:nil];
                }
            }
            
            if (selectedCell.moviePlayer)
            {
                if (selectedCell.moviePlayer.player.status == AVPlayerStatusReadyToPlay)
                {
                    // Show or hide the navigation bar

                    // The video controls bar display is automatically managed by MPMoviePlayerController.
                    // We have no control on it and no notifications about its displays changes.
                    // The following code synchronizes the display of the navigation bar with the
                    // MPMoviePlayerController controls bar.

                    // Check the MPMoviePlayerController controls bar display status by an hacky way
                    BOOL controlsVisible = NO;
                    for(id views in [[selectedCell.moviePlayer view] subviews])
                    {
                        for(id subViews in [views subviews])
                        {
                            for (id controlView in [subViews subviews])
                            {
                                if ([controlView isKindOfClass:[UIView class]] && ((UIView*)controlView).tag == 1004)
                                {
                                    UIView *subView = (UIView*)controlView;
                                    
                                    controlsVisible = (subView.alpha <= 0.0) ? NO : YES;
                                }
                            }
                        }
                    }
                    
                    // Apply the same display to the navigation bar
                    self.navigationBarContainer.hidden = !controlsVisible;
                    
                    navigationBarDisplayHandled = YES;
                    if (!self.navigationBarContainer.hidden)
                    {
                        // Automaticaly hide the nav bar after 5s. This is the same timer value that
                        // MPMoviePlayerController uses for its controls bar
                        [navigationBarDisplayTimer invalidate];
                        navigationBarDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideNavigationBar) userInfo:self repeats:NO];
                    }
                }
                else
                {
                    MXKPieChartView *pieChartView = [[MXKPieChartView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
                    pieChartView.progress = 0;
                    pieChartView.progressColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.25];
                    pieChartView.unprogressColor = [UIColor clearColor];
                    pieChartView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
                    pieChartView.center = selectedCell.customView.center;
                    [selectedCell.customView addSubview:pieChartView];
                    
                    // Add download progress observer
                    NSString *downloadId = attachment.downloadId;
                    selectedCell.notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXMediaLoaderStateDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                        
                        MXMediaLoader *loader = (MXMediaLoader*)notif.object;
                        if ([loader.downloadId isEqualToString:downloadId])
                        {
                            // update progress
                            switch (loader.state) {
                                case MXMediaLoaderStateDownloadInProgress:
                                {
                                    NSNumber* progressNumber = [loader.statisticsDict valueForKey:kMXMediaLoaderProgressValueKey];
                                    if (progressNumber)
                                    {
                                        pieChartView.progress = progressNumber.floatValue;
                                    }
                                    break;
                                }
                                default:
                                    break;
                            }
                        }
                        
                    }];
                    
                    [self prepareVideoForItem:item success:^{
                        
                        if (selectedCell.notificationObserver)
                        {
                            [[NSNotificationCenter defaultCenter] removeObserver:selectedCell.notificationObserver];
                            selectedCell.notificationObserver = nil;
                        }
                        
                        if (selectedCell.moviePlayer.view.superview)
                        {
                            selectedCell.moviePlayer.view.hidden = NO;
                            selectedCell.centerIcon.hidden = YES;
                            selectedCell.moviePlayer.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self->videoFile]];
                            [selectedCell.moviePlayer.player play];
                            
                            [pieChartView removeFromSuperview];
                            
                            [self hideNavigationBar];
                        }
                        
                    } failure:^(NSError *error) {
                        
                        if (selectedCell.notificationObserver)
                        {
                            [[NSNotificationCenter defaultCenter] removeObserver:selectedCell.notificationObserver];
                            selectedCell.notificationObserver = nil;
                        }
                        
                        MXLogDebug(@"[MXKAttachmentsVC] video download failed");
                        
                        [pieChartView removeFromSuperview];
                        
                        // Display the navigation bar so that the user can leave this screen
                        self.navigationBarContainer.hidden = NO;
                        
                        // Notify MatrixKit user
                        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                        
                    }];
                    
                    // Do not animate the navigation bar on video playback preparing
                    return;
                }
            }
        }
    }
    
    // Animate navigation bar if it is has not been handled
    if (!navigationBarDisplayHandled)
    {
        if (self.navigationBarContainer.hidden)
        {
            self.navigationBarContainer.hidden = NO;
            [navigationBarDisplayTimer invalidate];
            navigationBarDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(hideNavigationBar) userInfo:self repeats:NO];
        }
        else
        {
            [self hideNavigationBar];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Here the cell is not displayed anymore, but it may be displayed again if the user swipes on it.
    if ([cell isKindOfClass:[MXKMediaCollectionViewCell class]])
    {
        MXKMediaCollectionViewCell *mediaCollectionViewCell = (MXKMediaCollectionViewCell*)cell;
        
        // Check whether a video was playing in this cell.
        if (mediaCollectionViewCell.moviePlayer)
        {
            // This cell concerns an attached video.
            // We stop the player, and restore the default display based on the video thumbnail
            [mediaCollectionViewCell.moviePlayer.player pause];
            mediaCollectionViewCell.moviePlayer.player = nil;
            mediaCollectionViewCell.moviePlayer = nil;
            
            mediaCollectionViewCell.mxkImageView.hidden = NO;
            mediaCollectionViewCell.centerIcon.hidden = NO;
            mediaCollectionViewCell.customView.hidden = YES;
            
            // Remove potential media download observer
            if (mediaCollectionViewCell.notificationObserver)
            {
                [[NSNotificationCenter defaultCenter] removeObserver:mediaCollectionViewCell.notificationObserver];
                mediaCollectionViewCell.notificationObserver = nil;
            }
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    // Detect horizontal bounce at the beginning of the collection to trigger pagination
    if (scrollView == self.attachmentsCollection && !isBackPaginationInProgress && !self.complete && self.delegate)
    {
        if (scrollView.contentOffset.x < -30)
        {
            isBackPaginationInProgress = YES;
            [self.attachmentsCollection insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.attachmentsCollection)
    {
        if (isBackPaginationInProgress)
        {
            MXKAttachment *attachment = self.attachments.firstObject;
            self.complete = ![self.delegate attachmentsViewController:self paginateAttachmentBefore:attachment.eventId];
        }
        else
        {
            [self refreshCurrentVisibleCell];
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Use the window from the app delegate as this can be called before the view is presented.
    return LegacyAppDelegate.theDelegate.window.bounds.size;
}

#pragma mark - Movie Player

- (void)moviePlayerPlaybackDidFinishWithErrorNotification:(NSNotification *)notification
{
    NSDictionary *notificationUserInfo = [notification userInfo];

    NSError *mediaPlayerError = [notificationUserInfo objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey];
    if (mediaPlayerError)
    {
        MXLogDebug(@"[MXKAttachmentsVC] Playback failed with error description: %@", [mediaPlayerError localizedDescription]);

        // Display the navigation bar so that the user can leave this screen
        self.navigationBarContainer.hidden = NO;

        // Notify MatrixKit user
        [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:mediaPlayerError];
    }
}

#pragma mark - Gesture recognizer

- (void)onCollectionViewCellTap:(UIGestureRecognizer*)gestureRecognizer
{
    MXKMediaCollectionViewCell *selectedCell;
    
    UIView *view = gestureRecognizer.view;
    if ([view isKindOfClass:[MXKMediaCollectionViewCell class]])
    {
        selectedCell = (MXKMediaCollectionViewCell*)view;
    }
    
    // Notify the collection view delegate a cell has been selected.
    if (selectedCell && selectedCell.tag < attachments.count)
    {
        [self collectionView:self.attachmentsCollection didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:(isBackPaginationInProgress ? selectedCell.tag + 1: selectedCell.tag) inSection:0]];
    }
}

- (void)onCollectionViewCellLongPress:(UIGestureRecognizer*)gestureRecognizer
{
    MXKMediaCollectionViewCell *selectedCell;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        UIView *view = gestureRecognizer.view;
        if ([view isKindOfClass:[MXKMediaCollectionViewCell class]])
        {
            selectedCell = (MXKMediaCollectionViewCell*)view;
        }
    }
    
    // Notify the collection view delegate a cell has been selected.
    if (selectedCell && selectedCell.tag < attachments.count)
    {
        MXKAttachment *attachment = attachments[selectedCell.tag];
        
        if (currentAlert)
        {
            [currentAlert dismissViewControllerAnimated:NO completion:nil];
        }
        
        __weak __typeof(self) weakSelf = self;
        
        currentAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        if ([MXKAppSettings standardAppSettings].messageDetailsAllowSaving)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n save]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                
                typeof(self) self = weakSelf;
                self->currentAlert = nil;
                
                [self startActivityIndicator];
                
                [attachment save:^{
                    
                    typeof(self) self = weakSelf;
                    [self stopActivityIndicator];
                    
                } failure:^(NSError *error) {
                    
                    typeof(self) self = weakSelf;
                    [self stopActivityIndicator];
                    
                    // Notify MatrixKit user
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                    
                }];
                
            }]];
        }
        
        if ([MXKAppSettings standardAppSettings].messageDetailsAllowCopyingMedia)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n copyButtonName]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                
                typeof(self) self = weakSelf;
                self->currentAlert = nil;
                
                [self startActivityIndicator];
                
                [attachment copy:^{
                    
                    typeof(self) self = weakSelf;
                    [self stopActivityIndicator];
                    
                } failure:^(NSError *error) {
                    
                    typeof(self) self = weakSelf;
                    [self stopActivityIndicator];
                    
                    // Notify MatrixKit user
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                    
                }];
                
            }]];
        }
        
        if ([MXKAppSettings standardAppSettings].messageDetailsAllowSharing)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n share]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                
                MXWeakify(self);
                
                self->currentAlert = nil;
                
                [self startActivityIndicator];
                
                [attachment prepareShare:^(NSURL *fileURL) {
                    
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self stopActivityIndicator];
                    
                    self->documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
                    [self->documentInteractionController setDelegate:self];
                    self->currentSharedAttachment = attachment;
                    
                    if (![self->documentInteractionController presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES])
                    {
                        self->documentInteractionController = nil;
                        [attachment onShareEnded];
                        self->currentSharedAttachment = nil;
                    }
                    
                } failure:^(NSError *error) {
                    
                    MXStrongifyAndReturnIfNil(self);
                    
                    [self stopActivityIndicator];
                    
                    // Notify MatrixKit user
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKErrorNotification object:error];
                    
                }];
                
            }]];
        }
        
        if ([MXMediaManager existingDownloaderWithIdentifier:attachment.downloadId])
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancelDownload]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                               // Get again the loader
                                                               MXMediaLoader *loader = [MXMediaManager existingDownloaderWithIdentifier:attachment.downloadId];
                                                               if (loader)
                                                               {
                                                                   [loader cancel];
                                                               }
                                                               
                                                           }]];
        }
        
        if (currentAlert.actions.count)
        {
            [currentAlert addAction:[UIAlertAction actionWithTitle:[VectorL10n cancel]
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               
                                                               typeof(self) self = weakSelf;
                                                               self->currentAlert = nil;
                                                               
                                                           }]];
            
            [currentAlert popoverPresentationController].sourceView = _attachmentsCollection;
            [currentAlert popoverPresentationController].sourceRect = _attachmentsCollection.bounds;
            [self presentViewController:currentAlert animated:YES completion:nil];
        }
        else
        {
            currentAlert = nil;
        }
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller
{
    return self;
}

// Preview presented/dismissed on document.  Use to set up any HI underneath.
- (void)documentInteractionControllerWillBeginPreview:(UIDocumentInteractionController *)controller
{
    documentInteractionController = controller;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    documentInteractionController = nil;
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    documentInteractionController = nil;
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    documentInteractionController = nil;
    if (currentSharedAttachment)
    {
        [currentSharedAttachment onShareEnded];
        currentSharedAttachment = nil;
    }
}

#pragma mark - MXKDestinationAttachmentAnimatorDelegate

- (BOOL)prepareSubviewsForTransition:(BOOL)isStartInteraction
{
    // Sanity check
    if (currentVisibleItemIndex >= attachments.count)
    {
        return NO;
    }
    
    MXKAttachment *attachment = attachments[currentVisibleItemIndex];
    NSString *mimeType = attachment.contentInfo[@"mimetype"];

    // Check attachment type for GIFs - this is required because of the extra WKWebView
    if (attachment.type == MXKAttachmentTypeImage && attachment.contentURL && [mimeType isEqualToString:@"image/gif"])
    {
        MXKMediaCollectionViewCell *cell = (MXKMediaCollectionViewCell *)[self.attachmentsCollection.visibleCells firstObject];
        UIView *customView = cell.customView;
        for (UIView *v in customView.subviews)
        {
            if ([v isKindOfClass:[WKWebView class]])
            {
                v.hidden = isStartInteraction;
                return YES;
            }
        }
    }
    return NO;
}

- (UIImageView *)finalImageView
{
    MXKMediaCollectionViewCell *cell = (MXKMediaCollectionViewCell *)[self.attachmentsCollection.visibleCells firstObject];
    return cell.mxkImageView.imageView;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if (self.customAnimationsEnabled)
    {
        return [[MXKAttachmentAnimator alloc] initWithAnimationType:PhotoBrowserZoomInAnimation sourceViewController:self.sourceViewController];
    }
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    [self hideNavigationBar];
    
    if (self.customAnimationsEnabled)
    {
        return [[MXKAttachmentAnimator alloc] initWithAnimationType:PhotoBrowserZoomOutAnimation sourceViewController:self.sourceViewController];
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    //if there is an interaction, use the custom interaction controller to handle it
    if (self.interactionController.interactionInProgress)
    {
        return self.interactionController;
    }
    return nil;
}

#pragma mark - UINavigationControllerDelegate

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController {
    if (self.customAnimationsEnabled && self.interactionController.interactionInProgress)
    {
        return self.interactionController;
    }
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    
    if (self.customAnimationsEnabled)
    {
        if (operation == UINavigationControllerOperationPush)
        {
            return [[MXKAttachmentAnimator alloc] initWithAnimationType:PhotoBrowserZoomInAnimation sourceViewController:self.sourceViewController];
        }
        if (operation == UINavigationControllerOperationPop)
        {
            return [[MXKAttachmentAnimator alloc] initWithAnimationType:PhotoBrowserZoomOutAnimation sourceViewController:self.sourceViewController];
        }
        return nil;
    }
    
    return nil;
}

@end
