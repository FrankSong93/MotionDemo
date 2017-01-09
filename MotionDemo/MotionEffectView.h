//
//  MotionEffectView.h
//  MotionDemo
//
//  Created by songziqiang on 2017/1/9.
//  Copyright © 2017年 songziqiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MotionEffectView;
@protocol MotionEffectViewDelegate <NSObject>

- (void)didTapMotionEffectView:(MotionEffectView *)view;

@end

@interface MotionEffectView : UIView

@property (nonatomic, weak)id<MotionEffectViewDelegate> delegate;

@property (nonatomic, strong, readonly) UIImageView *imageView;

- (void)enableMotionEffect;

- (void)disableMotionEffect;

- (void)setImage:(UIImageView *)imageView;

@end
