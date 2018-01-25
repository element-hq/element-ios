//
//  TestVideoViewController.m
//  Memento
//
//  Created by Ömer Faruk Gül on 22/05/15.
//  Copyright (c) 2015 Ömer Faruk Gül. All rights reserved.
//

#import "VideoViewController.h"
#import "ViewUtils.h"
@import AVFoundation;

@interface VideoViewController ()
@property (strong, nonatomic) NSURL *videoUrl;
@property (strong, nonatomic) AVPlayer *avPlayer;
@property (strong, nonatomic) AVPlayerLayer *avPlayerLayer;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIButton *sendButton;
@end

@implementation VideoViewController

- (instancetype)initWithVideoUrl:(NSURL *)url {
    self = [super init];
    if(self) {
        _videoUrl = url;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // the video player
    self.avPlayer = [AVPlayer playerWithURL:self.videoUrl];
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[self.avPlayer currentItem]];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    self.avPlayerLayer.frame = CGRectMake(0, 0, screenRect.size.width, screenRect.size.height);
    [self.view.layer addSublayer:self.avPlayerLayer];
    
    //back button
    
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.backButton.frame = CGRectMake(5, 5, 22.0f + 20.0f, 22.0f + 20.0f);
    self.backButton.tintColor = [UIColor whiteColor];
    [self.backButton setImage:[UIImage imageNamed:@"cancel2.png"] forState:UIControlStateNormal];
    self.backButton.imageEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    self.backButton.imageView.clipsToBounds = NO;
    self.backButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.backButton.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.backButton.layer.shadowOpacity = 0.4f;
    self.backButton.layer.shadowRadius = 1.0f;
    self.backButton.clipsToBounds = NO;
    [self.backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];
    
    //send button
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.sendButton.frame = CGRectMake(0, 0, 22.0f + 20.0f, 22.0f + 20.0f);
    self.sendButton.tintColor = [UIColor whiteColor];
    [self.sendButton setImage:[UIImage imageNamed:@"send.png"] forState:UIControlStateNormal];
    self.sendButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    self.sendButton.imageView.clipsToBounds = NO;
    self.sendButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.sendButton.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.sendButton.layer.shadowOpacity = 0.4f;
    self.sendButton.layer.shadowRadius = 1.0f;
    self.sendButton.clipsToBounds = NO;
    [self.sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.sendButton];

}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.avPlayer play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)backButtonPressed:(UIButton *)button{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendButtonPressed:(UIButton *)button {
    [self.delegate videoViewController:self didSelectVideo:self.videoUrl isPhotoLibraryAsset:self.isPhotoLibraryAsset];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
        
    self.backButton.top = 5.0f;
    self.backButton.left = 5.0f;
    
    self.sendButton.bottom = self.view.height - 5;
    self.sendButton.right = self.view.width - 5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
