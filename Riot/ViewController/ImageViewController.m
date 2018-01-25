//
//  ImageViewController.m
//  LLSimpleCameraExample
//
//  Created by Ömer Faruk Gül on 15/11/14.
//  Copyright (c) 2014 Ömer Faruk Gül. All rights reserved.
//

#import "ImageViewController.h"
#import "ViewUtils.h"
#import "UIImage+Crop.h"

@interface ImageViewController ()
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIButton *sendButton;


@end

@implementation ImageViewController

@synthesize delegate;

- (instancetype)initWithImage:(UIImage *)image {
    self = [super initWithNibName:nil bundle:nil];
    if(self) {
        _image = image;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.imageView.backgroundColor = [UIColor blackColor];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.image = self.image;
    [self.view addSubview:self.imageView];

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
    [self.backButton addTarget:self.parentViewController action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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

-(void)backButtonPressed:(UIButton *)button{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendButtonPressed:(UIButton *)button {
    NSData *imgData = UIImageJPEGRepresentation(self.image, 0.7);
    [self.delegate imageViewController:self didSelectImage:imgData withMimeType:[self getMimeType] isPhotoLibraryAsset:self.isPhotoLibraryAsset];
}

- (NSString *)getMimeType {
    return (self.isPhotoLibraryAsset) ? self.mimetype : @"image/jpeg";
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.imageView.frame = self.view.contentBounds;
    
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
