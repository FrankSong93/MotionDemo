//
//  EffectViewController.m
//  MotionDemo
//
//  Created by songziqiang on 2017/1/9.
//  Copyright © 2017年 songziqiang. All rights reserved.
//

#import "EffectViewController.h"
#import "MotionEffectView.h"

@interface EffectViewController ()<MotionEffectViewDelegate>

@end

@implementation EffectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	UIImageView *imageView = [[UIImageView alloc] init];
	NSMutableArray *images = [NSMutableArray arrayWithCapacity:79];
	for (int i = 0; i < 79; i++) {
		UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"Comp2_%05d", i]];
		
		[images addObject:image];
	}
	imageView.animationImages = [images copy];
	imageView.animationDuration = 1/79;
	[imageView startAnimating];
	
//	imageView.frame = CGRectMake(-self.view.frame.size.width, -(self.view.frame.size.height/2), 300, 300);
//	imageView.center = self.view.center;
	
	
	MotionEffectView *effectView = [[MotionEffectView alloc] initWithFrame:CGRectMake(-self.view.frame.size.width, -(self.view.frame.size.height/2), 300, 300)];
	effectView.center = self.view.center;
	effectView.delegate = self;
	[effectView setImage:imageView];
	[self.view addSubview:effectView];
	[effectView enableMotionEffect];
	
}


#pragma MotionEffectViewDelegate

- (void)didTapMotionEffectView:(MotionEffectView *)view {
	
}

@end
