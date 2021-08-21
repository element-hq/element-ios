//
//  TTVCodeScanViewController.m
//  TouchTV
//
//  Created by liaoshen on 2020/4/22.
//  Copyright © 2020 TouchTV. All rights reserved.
//

#import "TTVCodeScanViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MMAlertView.h>
static const char *kQRCodeScanQueueName = "QRCodeScanQueue";
@interface TTVCodeScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) BOOL isLightOn;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CGFloat number;
@property (nonatomic ,strong) UIButton *backBtn;
@property (strong, nonatomic) UIImageView *bgImageView;
@property (strong, nonatomic) UIImageView *scanningLine;
@property (strong, nonatomic) UILabel *tipLabel;
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIView *bottomView;
@property (strong, nonatomic) UIView *leftView;
@property (strong, nonatomic) UIView *rightView;
@property (nonatomic , strong)YXNaviView *naviView;
@end

@implementation TTVCodeScanViewController


-(YXNaviView *)naviView{
    if (!_naviView) {
        _naviView = [[YXNaviView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, STATUS_AND_NAVIGATION_HEIGHT)];
        _naviView.title = @"扫描二维码";
        _naviView.titleColor = UIColor.whiteColor;
        _naviView.backgroundColor = UIColor.clearColor;
        YXWeakSelf
        _naviView.backBlock = ^{
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
 
    }
    return _naviView;
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //隐藏导航栏
    self.navigationController.navigationBar.hidden = YES;

}


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopScan];
    [self.timer invalidate];
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化UI
    [self seupUI];
    // 添加定时器
    [self seupTimer];
    // 开启扫描
    [self startScan];
    
    [self addNoti];//添加进入后台监听和后台返回前台的监听

}

- (void)seupUI{
    
    [self.view addSubview:self.naviView];
    
    UIImageView *imageView = [[UIImageView alloc]init];
    imageView.image = [UIImage imageNamed:@"img_scanning_qr"];
    [self.view addSubview:imageView];
    [imageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(kPtBy2xScaleF(165) + kStatusBarHeight);
        make.centerX.mas_equalTo(self.view);
        make.width.height.mas_equalTo(kPtBy2xScaleF(257));
    }];
    self.bgImageView = imageView;
    
    UIImageView *scanningLine = [[UIImageView alloc]init];
    scanningLine.image = [UIImage imageNamed:@"img_scanning_line"];
    [imageView addSubview:scanningLine];
    [scanningLine mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.mas_equalTo(0);
        make.height.mas_equalTo(kPtBy2xScaleF(37));
    }];
    self.scanningLine = scanningLine;
    
    CGFloat alpha = 0.6;
    
    UIView *topView = [[UIView alloc]init];
    [self.view addSubview:topView];
    topView.backgroundColor = RGBA(1, 1, 1, alpha);
    [topView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.offset(0);
        make.bottom.mas_equalTo(imageView.mas_top).offset(0);
    }];
    
    UIView *bottomView = [[UIView alloc]init];
    [self.view addSubview:bottomView];
    bottomView.backgroundColor = RGBA(1, 1, 1, alpha);
    [bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.offset(0);
        make.top.mas_equalTo(imageView.mas_bottom).offset(0);
    }];
    
    UIView *leftView = [[UIView alloc]init];
    [self.view addSubview:leftView];
    leftView.backgroundColor = RGBA(1, 1, 1, alpha);
    [leftView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(0);
        make.right.mas_equalTo(imageView.mas_left).offset(0);
        make.top.mas_equalTo(topView.mas_bottom).offset(0);
        make.bottom.mas_equalTo(bottomView.mas_top).offset(0);
    }];
    
    UIView *rightView = [[UIView alloc]init];
    [self.view addSubview:rightView];
    rightView.backgroundColor = RGBA(1, 1, 1, alpha);
    [rightView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(0);
        make.left.mas_equalTo(imageView.mas_right).offset(0);
        make.top.mas_equalTo(topView.mas_bottom).offset(0);
        make.bottom.mas_equalTo(bottomView.mas_top).offset(0);
    }];
    
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:backBtn];
    [backBtn setImage:[UIImage imageNamed:@"ico_close_qr"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [backBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.width.mas_offset(kPtBy2xScaleF(26));
        make.top.mas_equalTo(kStatusBarHeight);
        make.left.mas_equalTo(kPtBy2xScaleF(18));
    }];
    self.backBtn = backBtn;
    
    
    UILabel *label = [[UILabel alloc]init];
    label.textColor = [UIColor colorWithHexString:@"#DCDCDC"];
    label.font = [UIFont systemFontOfSize:14];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;
    label.text = @"放入框内，自动扫描";
    [self.view addSubview:label];
    [label mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(imageView.mas_bottom).offset(kPtBy2xScaleF(30));
        make.centerX.mas_equalTo(self.view);
        make.height.mas_equalTo(kPtBy2xScaleF(14));
    }];
    self.tipLabel = label;
    self.topView = topView;
    self.bottomView = bottomView;
    self.leftView = leftView;
    self.rightView = rightView;
}

-(void)addNoti{
    //进入后台
    YXWeakSelf
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationDidEnterBackgroundNotification
     object:nil queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification * _Nonnull note) {
         [weakSelf.timer setFireDate:[NSDate distantFuture]];
     }];
    
    //进入前台
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationWillEnterForegroundNotification
     object:nil queue:[NSOperationQueue mainQueue]
     usingBlock:^(NSNotification * _Nonnull note) {
         [weakSelf.timer setFireDate:[NSDate date]];
     }];
}

-(void)backClick{
    // 扫描到之后，停止扫描
    [self stopScan];
    [self.timer invalidate];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)seupTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animateineAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    self.number = 1;
    // 闪光灯默认关闭
    self.isLightOn = NO;
}
// 开始扫描
- (BOOL)startScan {
    // 获取手机硬件设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 初始化输入流
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@",[error localizedDescription]);
        return NO;
    }
    // 创建会话
    _captureSession = [[AVCaptureSession alloc] init];
    // 添加输入流
    [_captureSession addInput:input];
    // 初始化输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    // 添加输出流
    [_captureSession addOutput:output];
    // 创建dispatch queue
    dispatch_queue_t queue = dispatch_queue_create(kQRCodeScanQueueName, DISPATCH_QUEUE_CONCURRENT);
    //扫描的结果苹果是通过代理的方式区回调，所以outPut需要添加代理，并且因为扫描是耗时的工作，所以把它放到子线程里面
    [output setMetadataObjectsDelegate:self queue:queue];
    // 设置支持二维码和条形码扫描
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    // 创建输出对象
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    _previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    // 开始会话
    [_captureSession startRunning];
    return YES;
}

// 结束扫描
- (void)stopScan {
    // 停止会话
    [_captureSession stopRunning];
    _captureSession = nil;
}


#pragma mark -- AVCaptureMetadataOutputObjectsDelegate
// 扫描结果的代理回调方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && metadataObjects.count > 0) {
        // 扫描到之后，停止扫描
        [self stopScan];
        [self.timer invalidate];

        // 获取结果并对其进行处理
        AVMetadataMachineReadableCodeObject *object = metadataObjects.firstObject;
        if ([[object type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *result = object.stringValue;
            // 处理result
            NSLog(@"%@",result);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self jumpUrl:result];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self backClick];
            });
        }
    }
}

-(void)jumpUrl:(NSString *)result{
    
    if (result.length > 0) {
        [MBProgressHUD showSuccess:@"请扫描正确的活动二维码"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.scanWalletAddrBlock) {
                self.scanWalletAddrBlock(result);
            }
            [self backClick];
        });
    }
    
}


//龙川新时代扫码
-(void)touchtvNewEraWith:(NSString *)result{
    if ([result containsString:@"touchtv_feedback"] || [result containsString:@"touchtv_signin"]){
        [self backClick];
    }else{
        //不符合要求弹框处理
        [self continueScan];
        return;
    }
}

- (void)animateineAction {
    
    if (self.number < kPtBy2xScaleF(220)) {
        [self.scanningLine mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.top.mas_equalTo(self.number);
            make.height.mas_equalTo(37);
        }];
        self.number += 2;
    } else {
        self.number = 1;
        [self.scanningLine mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.top.mas_equalTo(self.number);
            make.height.mas_equalTo(37);
        }];
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//错误链接提示
- (void)continueScan {
    [_previewLayer removeFromSuperlayer];
    [self updataUI:YES];
    UIView *shadowView = [[UIView alloc]init];
    shadowView.backgroundColor = RGBA(1, 1, 1, 0.5);
    [self.view addSubview:shadowView];
    [shadowView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    MMAlertViewConfig *config = [MMAlertViewConfig globalConfig];
    config.itemHighlightColor = [UIColor colorWithHexString:@"#333333"];
    config.titleColor = [UIColor colorWithHexString:@"#333333"];
    config.titleFontSize = 18.0;
    config.detailColor = [UIColor colorWithHexString:@"#999999"];
    NSArray *arr = @[MMItemMake(@"确定", MMItemTypeHighlight, ^(NSInteger index)
                                {
        [shadowView removeFromSuperview];
        [self updataUI:NO];
        [self startScan];
        [self seupTimer];
        
    })];
   MMAlertView *alertView = [[MMAlertView alloc] initWithTitle:@"温馨提示" detail:@"无法匹配此二维码到服务活动" items:arr];
    [alertView show];
}

-(void)updataUI:(BOOL)show{
    self.bgImageView.hidden = show;
    self.scanningLine.hidden = show;
    self.tipLabel.hidden = show;
    self.tipLabel.hidden = show;
    self.topView.hidden = show;
    self.bottomView.hidden = show;
    self.leftView.hidden = show;
    self.rightView.hidden = show;
    self.backBtn.hidden = show;
}

@end
