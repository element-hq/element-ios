/*
 Copyright 2015 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 
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

#import "MediaAlbumContentViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "GeneratedInterface-Swift.h"

@interface MediaAlbumContentViewController ()
{
    /**
     Observe UIApplicationWillEnterForegroundNotification to refresh bubbles when app leaves the background state.
     */
    id UIApplicationWillEnterForegroundNotificationObserver;
    
    /**
     The current list of assets retrieved from collection.
     */
    PHFetchResult *assets;

    /**
     The currently selected media. Nil when the multiselection is not active.
     */
    NSMutableArray <PHAsset*> *selectedAssets;
    
    /**
     Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
     */
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@end

@implementation MediaAlbumContentViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MediaAlbumContentViewController class])
                          bundle:[NSBundle bundleForClass:[MediaAlbumContentViewController class]]];
}

+ (instancetype)mediaAlbumContentViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MediaAlbumContentViewController class])
                                          bundle:[NSBundle bundleForClass:[MediaAlbumContentViewController class]]];
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Register collection view cell class
    [self.assetsCollectionView registerClass:MXKMediaCollectionViewCell.class forCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier]];
    
    if (!_mediaTypes)
    {
        // Set default media type
        self.mediaTypes = @[(NSString *)kUTTypeImage];
    }
    
    MXWeakify(self);
    
    // Observe UIApplicationWillEnterForegroundNotification to refresh captures collection when app leaves the background state.
    UIApplicationWillEnterForegroundNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        // Force a full refresh of the displayed collection
        self.assetsCollection = self->_assetsCollection;
        
    }];

    if (_allowsMultipleSelection)
    {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[VectorL10n mediaPickerSelect] style:UIBarButtonItemStylePlain target:self action:@selector(onSelect:)];
    }
    
    // Observe user interface theme change.
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        
        [self userInterfaceThemeDidChange];
        
    }];
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [ThemeService.shared.theme applyStyleOnNavigationBar:self.navigationController.navigationBar];

    self.assetsCollectionView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    // Return the preferred value of the delegate if it is a view controller itself.
    // This is required to handle correctly the full screen mode when a media is selected.
    if ([self.delegate isKindOfClass:UIViewController.class])
    {
        return [(UIViewController*)self.delegate prefersStatusBarHidden];
    }
    
    // Keep visible the status bar by default.
    return NO;
}

- (void)destroy
{
    [super destroy];
    
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:kThemeServiceDidChangeThemeNotificationObserver];
        kThemeServiceDidChangeThemeNotificationObserver = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = _assetsCollection.localizedTitle;
    
    [self.assetsCollectionView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark -

- (void)setMediaTypes:(NSArray *)mediaTypes
{
    _mediaTypes = mediaTypes;
    
    self.assetsCollection = _assetsCollection;
}

- (void)setAssetsCollection:(PHAssetCollection *)assetsCollection
{
    if (assetsCollection)
    {
        if (!_mediaTypes)
        {
            // Set default media type
            _mediaTypes = @[(NSString *)kUTTypeImage];
        }
        
        // Set up fetch options.
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        if ([_mediaTypes indexOfObject:(NSString *)kUTTypeImage] != NSNotFound)
        {
            if ([_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
            {
                options.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d) || (mediaType == %d)", PHAssetMediaTypeImage, PHAssetMediaTypeVideo];
            }
            else
            {
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeImage];
            }
        }
        else if ([_mediaTypes indexOfObject:(NSString *)kUTTypeMovie] != NSNotFound)
        {
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d",PHAssetMediaTypeVideo];
        }
        
        assets = [PHAsset fetchAssetsInAssetCollection:assetsCollection options:options];
        
        MXLogDebug(@"[MediaAlbumVC] lists %tu assets", assets.count);
    }
    else
    {
        assets = nil;
    }
    
    _assetsCollection = assetsCollection;

    self.navigationItem.title = _assetsCollection.localizedTitle;
    
    [self.assetsCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MXKMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MXKMediaCollectionViewCell defaultReuseIdentifier] forIndexPath:indexPath];
    
    // Sanity check: cancel pending asynchronous request (if any)
    if (cell.tag)
    {
        [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)cell.tag];
        cell.tag = 0;
    }
    
    if (indexPath.item < assets.count)
    {
        PHAsset *asset = assets[indexPath.item];
        
        CGFloat collectionViewSquareSize = ((collectionView.frame.size.width - 6) / 4); // Here 6 = 3 * cell margin (= 2).
        CGSize cellSize = CGSizeMake(collectionViewSquareSize, collectionViewSquareSize);
        
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.synchronous = NO;
        cell.tag = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:cellSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
            
            cell.mxkImageView.imageView.contentMode = UIViewContentModeScaleAspectFill;
            cell.mxkImageView.image = result;
            cell.tag = 0;
            
        }];
        
        cell.bottomLeftIcon.image = AssetImages.videoIcon.image;
        cell.bottomLeftIcon.hidden = (asset.mediaType == PHAssetMediaTypeImage);

        cell.bottomRightIcon.image = AssetImages.selectionTick.image;
        cell.bottomRightIcon.tintColor = ThemeService.shared.theme.tintColor;
        cell.bottomRightIcon.hidden = !selectedAssets || (NSNotFound == [selectedAssets indexOfObject:asset]);

        // Disable user interaction in mxkImageView, in order to let collection handle user selection
        cell.mxkImageView.userInteractionEnabled = NO;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item < assets.count && self.delegate)
    {
        PHAsset *asset = assets[indexPath.item];

        // Are we in multiselection mode ?
        if (!selectedAssets)
        {
            // NO
            [self.delegate mediaAlbumContentViewController:self didSelectAsset:asset];
        }
        else
        {
            // YES. Toggle the selection of the cell
            MXKMediaCollectionViewCell *cell = (MXKMediaCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];

            if (NSNotFound == [selectedAssets indexOfObject:asset])
            {
                cell.bottomRightIcon.hidden = NO;
                [selectedAssets addObject:asset];
            }
            else
            {
                cell.bottomRightIcon.hidden = YES;
                [selectedAssets removeObject:asset];
            }

            self.navigationItem.rightBarButtonItem.enabled = (0 < selectedAssets.count);
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    // Check whether a asynchronous request is pending
    if (cell.tag)
    {
        [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)cell.tag];
        cell.tag = 0;
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item < assets.count)
    {
        CGFloat collectionViewSquareSize = ((collectionView.frame.size.width - 6) / 4); // Here 6 = 3 * cell margin (= 2).
        CGSize cellSize = CGSizeMake(collectionViewSquareSize, collectionViewSquareSize);
        
        return cellSize;
    }
    return CGSizeZero;
}

#pragma mark - Actions

- (void)onSelect:(id)sender
{
    selectedAssets = [NSMutableArray array];

    // Update the nav buttons
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[VectorL10n send] style:UIBarButtonItemStylePlain target:self action:@selector(onSelectionSend:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onSelectionCancel:)];
}

- (void)onSelectionSend:(id)sender
{
    if (selectedAssets.count > 1)
    {
        [self.delegate mediaAlbumContentViewController:self didSelectAssets:selectedAssets];
    }
    else
    {
        [self.delegate mediaAlbumContentViewController:self didSelectAsset:selectedAssets[0]];
    }
}

- (void)onSelectionCancel:(id)sender
{
    selectedAssets = nil;

    // Update the nav buttons
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[VectorL10n mediaPickerSelect] style:UIBarButtonItemStylePlain target:self action:@selector(onSelect:)];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem = nil;

    // Do not use [UICollectionView reloadData] because it creates flickering
    // Unselecting manually the cells is more efficient
    for (MXKMediaCollectionViewCell *cell in self.assetsCollectionView.visibleCells)
    {
        cell.bottomRightIcon.hidden = YES;
    }
}

@end
