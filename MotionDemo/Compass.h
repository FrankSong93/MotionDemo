//
//  Compass.h
//  MotionDemo
//
//  Created by songziqiang on 2016/12/19.
//  Copyright © 2016年 songziqiang. All rights reserved.
//

#include <CoreMotion/CoreMotion.h>
#import <CoreFoundation/CoreFoundation.h>
#import <GLKit/GLKit.h>
#import "constants.h"

@interface Compass : NSObject

+ (id) getSingleton:(UIView*)view;
- (double) getHeading;

@end
