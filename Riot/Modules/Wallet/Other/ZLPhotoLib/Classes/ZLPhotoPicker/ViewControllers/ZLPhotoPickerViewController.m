//
//  PickerViewController.m
//  ZLAssetsPickerDemo
//
//  Created by 张磊 on 14-11-11.
//  Copyright (c) 2014年 com.zixue101.www. All rights reserved.
//

#import "ZLPhotoPickerViewController.h"
#import "ZLNavigationController.h"
#import "ZLPhoto.h"
#import "UIViewController+Alert.h"

@interface ZLPhotoPickerViewController () <UIAlertViewDelegate>
@property (nonatomic , weak) ZLPhotoPickerGroupViewController *groupVc;
@end

@implementation ZLPhotoPickerViewController

#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self addNotification];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - init Action
- (void) createNavigationController{
    ZLPhotoPickerGroupViewController *groupVc = [[ZLPhotoPickerGroupViewController alloc] init];
    ZLNavigationController *nav = [[ZLNavigationController alloc] initWithRootViewController:groupVc];
    nav.view.frame = self.view.bounds;
    [self addChildViewController:nav];
    [self.view addSubview:nav.view];
    self.groupVc = groupVc;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self createNavigationController];
    }
    return self;
}

- (void)setIsShowCamera:(BOOL)isShowCamera{
    _isShowCamera = isShowCamera;
    self.groupVc.isShowCamera = isShowCamera;
}

- (void)setSelectPickers:(NSArray *)selectPickers{
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:selectPickers.count];
    for (id asset in selectPickers) {
        if ([asset isKindOfClass:[ZLPhotoAssets class]]) {
            [assets addObject:asset];
            continue;
        }else if ([asset isKindOfClass:[ZLPhotoPickerBrowserPhoto class]]){
            [assets addObject:[(ZLPhotoPickerBrowserPhoto *)asset asset]?:@""];
        }
    }
    self.groupVc.selectAsstes = assets;
}

- (void)setStatus:(PickerViewShowStatus)status{
    _status = status;
    self.groupVc.status = status;
}

- (void)setPhotoStatus:(PickerPhotoStatus)photoStatus{
    _photoStatus = photoStatus;
    self.groupVc.photoStatus = photoStatus;
}

- (void)setMaxCount:(NSInteger)maxCount{
    _maxCount = maxCount <= 0 ? -1 : maxCount;
    self.groupVc.maxCount = _maxCount;
}

- (void)setTopShowPhotoPicker:(BOOL)topShowPhotoPicker{
    _topShowPhotoPicker = topShowPhotoPicker;
    self.groupVc.topShowPhotoPicker = topShowPhotoPicker;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self hideWaitingAnimation];
}

#pragma mark - 展示控制器
- (void)showPickerVc:(UIViewController *)vc{

    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == ALAuthorizationStatusRestricted || author ==ALAuthorizationStatusDenied) {
        CGFloat kSystemMainVersion = [UIDevice currentDevice].systemVersion.floatValue;
        NSString *title = nil;
        NSString *msg = @"还没有开启相册权限~请在系统设置中开启";
        NSString *cancelTitle = @"暂不";
        NSString *otherButtonTitles = @"去设置";
        
        if (kSystemMainVersion < 8.0) {
            title = @"相册权限未开启";
            msg = @"请在系统设置中开启相机服务\n(设置>隐私>相册>开启)";
            cancelTitle = @"知道了";
            otherButtonTitles = nil;
        }
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:otherButtonTitles, nil];
        [alertView show];
    }
    __weak typeof(vc)weakVc = vc;
    if (weakVc != nil) {
        [weakVc presentViewController:self animated:YES completion:nil];
    }
}

- (void) addNotification{
    // 监听异步done通知
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(done:) name:PICKER_TAKE_DONE object:nil];
    });
    
    // 监听异步点击第一个Cell的拍照通知
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCamera:) name:PICKER_TAKE_PHOTO object:nil];
    });
}

#pragma mark - 监听点击第一个Cell进行拍照
- (void)selectCamera:(NSNotification *)noti{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([self.delegate respondsToSelector:@selector(pickerCollectionViewSelectCamera:withImage:)]){
            [self.delegate pickerCollectionViewSelectCamera:self withImage:noti.userInfo[@"image"]];
        }
    });
}

#pragma mark - 监听点击Done按钮
- (void)done:(NSNotification *)note{
    NSArray *selectArray =  note.userInfo[@"selectAssets"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(pickerViewControllerDoneAsstes:)]) {
            [self.delegate pickerViewControllerDoneAsstes:selectArray];
        }else if (self.callBack){
            self.callBack(selectArray);
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)setDelegate:(id<ZLPhotoPickerViewControllerDelegate>)delegate{
    _delegate = delegate;
    self.groupVc.delegate = delegate;
}

#pragma mark - <UIAlertDelegate>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        CGFloat kSystemMainVersion = [UIDevice currentDevice].systemVersion.floatValue;
        if (kSystemMainVersion >= 8.0) { // ios8 以后支持跳转到设置
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }
}

@end
