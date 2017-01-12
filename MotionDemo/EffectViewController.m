//
//  EffectViewController.m
//  MotionDemo
//
//  Created by songziqiang on 2017/1/9.
//  Copyright © 2017年 songziqiang. All rights reserved.
//

#import "EffectViewController.h"
#import "MotionEffectView.h"
#import "FINCamera.h"

@interface EffectViewController () <
    MotionEffectViewDelegate, FINCameraDelagate,
    AVCaptureVideoDataOutputSampleBufferDelegate>

@property(nonatomic, strong) FINCamera *camera;

@property(nonatomic, strong) MotionEffectView *effectView;

@end

@implementation EffectViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.

  [self openCamera];

  CGSize imageViewSize = CGSizeMake(200, 200);
  NSMutableArray *images = [NSMutableArray arrayWithCapacity:79];
  for (int i = 0; i < 79; i++) {
    UIImage *image =
        [UIImage imageNamed:[NSString stringWithFormat:@"Comp2_%05d", i]];

    [images addObject:image];
  }

  UIImageView *imageView = [[UIImageView alloc] init];
  imageView.animationImages = [images copy];
  imageView.animationDuration = 1 / 79;
  [imageView startAnimating];

  //	imageView.frame = CGRectMake(-self.view.frame.size.width,
  //-(self.view.frame.size.height/2), 300, 300);
  //	imageView.center = self.view.center;

  _effectView = [[MotionEffectView alloc]
      initWithFrame:CGRectMake(0, 0, imageViewSize.width,
                               imageViewSize.height)];
  _effectView.center = self.view.center;
  _effectView.delegate = self;
  [_effectView setImage:imageView];
  [self.view addSubview:_effectView];
  [_effectView enableMotionEffect];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [_effectView disableMotionEffect];
  _effectView = nil;
}

#pragma MotionEffectViewDelegate

- (void)didTapMotionEffectView:(MotionEffectView *)view {
}

#pragma mark - 相机
- (void)openCamera {
  __weak typeof(self) weakSelf = self;
  self.camera = [FINCamera createWithBuilder:^(FINCamera *builder) {
      // input
      [builder useBackCamera];
      // output
      [builder useVideoDataOutputWithDelegate:weakSelf];
      // delegate
      [builder setDelegate:weakSelf];
      // setting
      [builder setPreset:AVCaptureSessionPresetPhoto];
  }];
  [self.camera startSession];

  [self.view insertSubview:[self.camera previewWithFrame:self.view.frame]
                   atIndex:0];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
  //    NSLog(@"TEST");
}
- (void)camera:(FINCamera *)camera adjustingFocus:(BOOL)adjustingFocus {
  //    NSLog(@"%@",adjustingFocus?@"正在对焦":@"对焦完毕");
}

@end
