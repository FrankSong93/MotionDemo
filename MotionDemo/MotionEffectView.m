//
//  MotionEffectView.m
//  MotionDemo
//
//  Created by songziqiang on 2017/1/9.
//  Copyright © 2017年 songziqiang. All rights reserved.
//

#import "MotionEffectView.h"
#import <CoreMotion/CoreMotion.h>

#define kDEGREESTORADIANS(__ANGLE__) ((__ANGLE__) * (M_PI / 180)) // PI / 180

#define kRADIANSTODEGREES(__ANGLE__) ((__ANGLE__) * 180 / M_PI)

#define kXPositionMultiplier [UIScreen mainScreen].bounds.size.width/(kXRange) // 代表每一度的像素个数

#define kXRange 30 // 代表将在屏幕一半宽度处显示的度数,*2表示显示的范围

#define kXPosition [UIScreen mainScreen].bounds.size.width/2

#define kYPositionMultiplier [UIScreen mainScreen].bounds.size.height/(kYRange) // 代表每一度的像素个数

#define kYRange 60 // 代表将在屏幕一半高度处显示的度数,*2表示显示的范围

#define kYPosition [UIScreen mainScreen].bounds.size.height/2

@implementation MotionEffectView {
	CMMotionManager *_motionManager;
	CADisplayLink *_displayLink;
	CMAttitude *_initialAttitude;
	
	float _yawPosition; // 保存初始位置
	float _pitchPosition;
	
	UITapGestureRecognizer *_tapGestureRecognizer;
}

- (instancetype)init {
	if (self = [super init]) {
		// 初始化原始位置
		_yawPosition = 0;
		_pitchPosition = 0;
	}
	
	return self;
}

- (void)onTapImageView {
	if ([_delegate respondsToSelector:@selector(didTapMotionEffectView:)]) {
		[_delegate didTapMotionEffectView:self];
	}
}

- (void)enableMotionEffect {
	_motionManager = [[CMMotionManager alloc] init];
	
	if ([_motionManager isDeviceMotionAvailable]) {
		_motionManager.deviceMotionUpdateInterval = 1/60.f;
		[_motionManager startDeviceMotionUpdates];
		_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMotion)];
		[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	}
}

- (void)disableMotionEffect {
	[_motionManager stopDeviceMotionUpdates];
	_motionManager = nil;
}

- (void)setImage:(UIImageView *)imageView {
	_imageView = imageView;
	_imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width);
	[self addSubview:_imageView];
	
	_tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapImageView)];
	[self addGestureRecognizer:_tapGestureRecognizer];
}

- (void)updateMotion {
	CMDeviceMotion *motion = _motionManager.deviceMotion;
	
	if (!_initialAttitude) {
		_initialAttitude = motion.attitude;
	}
	[motion.attitude multiplyByInverseOfAttitude:_initialAttitude];
	
	CMQuaternion quat = motion.attitude.quaternion;
	
	float myPitch;
	float myYaw;
	float myRoll;
//	__block double rotation = atan2(motion.gravity.x, motion.gravity.y) - M_PI;
	
	myPitch = (atan2(2*(quat.x*quat.w + quat.y*quat.z), 1 - 2*quat.x*quat.x - 2*quat.z*quat.z));
	myYaw = (asin(2*quat.x*quat.y + 2*quat.w*quat.z));
	myRoll = atan2(2*(quat.y*quat.w - quat.x*quat.z), 1 - 2*quat.y*quat.y - 2*quat.z*quat.z);
	// kalman filtering 卡尔曼滤波
	static float q1 = 0.1;   // process noise
	static float r1 = 0.1;   // sensor noise
	static float p1 = 0.1;   // estimated error
	static float k1 = 0.5;   // kalman filter gain
	
	static float x = 0;
	if (x == 0) {
		x = myYaw;
	}
	
	p1 = p1 + q1;
	k1 = p1 / (p1 + r1);
	x = x + k1*(myYaw - x);
	p1 = (1 - k1)*p1;
	myYaw = x;
	
	static float q2 = 0.1;   // process noise
	static float r2 = 0.1;   // sensor noise
	static float p2 = 0.1;   // estimated error
	static float k2 = 0.5;
	static float y = 0;
	if (y == 0) {
		y = myRoll;
	}
	
	p2 = p2 + q2;
	k2 = p2 / (p2 + r2);
	y = y + k2*(myRoll - y);
	p2 = (1 - k2)*p2;
	myRoll = y;
	
	static float q3 = 0.1;   // process noise
	static float r3 = 0.1;   // sensor noise
	static float p3 = 0.1;   // estimated error
	static float k3 = 0.5;
	static float z = 0;
	if (z == 0) {
		z = myPitch;
	}
	p3 = p3 + q3;
	k3 = p3 / (p3 + r3);
	z = z + k3*(myPitch - z);
	p3 = (1 - k3)*p3;
	myPitch = z;
	
	// Convert the radians yaw value to degrees then round up/down
	float yaw = roundf((float)(kRADIANSTODEGREES(myYaw)));
	float pitch = roundf((float)(kRADIANSTODEGREES(myPitch)));
	float roll = roundf((float)(kRADIANSTODEGREES(myRoll)));
	
	static float roll0  = 0;
	if (roll0) {
		roll0 = roll;
	}
	if (_yawPosition==0) {
		_yawPosition = yaw;
		_pitchPosition = pitch;
	}
	
	__block int xPosition;
	__block int yPosition;
	
	//	__block double rotation = atan2(motion.gravity.x, motion.gravity.y) - M_PI;
	//
	// self.imageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, rotation);
	
	if (ABS(roll0 - roll) > 90 ) {
		self.hidden = YES;
	} else {
		self.hidden = NO;
		
		xPosition = [self getXPositionIn360:yaw];
		
		yPosition = [self getYPositionIn360:pitch];
	}
	
	
	[UIView animateWithDuration:0.1f
						  delay:0.0f
						options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 NSLog(@"xPosition:%d, yPosition:%d", xPosition, yPosition);
						 //						  self.imageView.transform = CGAffineTransformMakeRotation(rotation);
						 
						 [self setCenter:CGPointMake(xPosition, yPosition)];
					 }
					 completion:nil];
	
}



- (int)getYPositionIn360:(float)pitch {
	self.hidden = NO;
	
	// X
	// Convert the yaw value to a value in the range of 0 to 360
	int positionYIn360 = pitch;
	if (positionYIn360 < 0) {
		positionYIn360 = 360 + positionYIn360;
	}
	
	BOOL checkAlternateRangeY = false;
	
	// Determine the minimum position for enemy ship
	int rangeMinY = positionYIn360 - kYRange;
	if (rangeMinY < 0) {
		rangeMinY = 360 + rangeMinY;
		checkAlternateRangeY = true;
	}
	
	// Determine the maximum position for the enemy ship
	int rangeMaxY = positionYIn360 + kYRange;
	if (rangeMaxY > 360) {
		rangeMaxY = rangeMaxY - 360;
		checkAlternateRangeY = true;
	}
	
	if (checkAlternateRangeY) {
		if ((_pitchPosition < rangeMaxY || _pitchPosition > rangeMinY ) || (_pitchPosition > rangeMinY || _pitchPosition < rangeMaxY)) {
			int difference = 0; // 保存设备的positionXIn360和image的yaw位置的角度差值
			if (positionYIn360 < kYRange) {
				// Run 1
				if (_pitchPosition > 360 - kYRange) {
					difference = (360 - _pitchPosition) + positionYIn360;
					int yPosition = kYPosition + (difference * kYPositionMultiplier);
			
					return yPosition;
					
				} else {
					// Run Standard Position Check
					return [self checkYStandardPoint:positionYIn360];
				}
			} else if(positionYIn360 > 360 - kYRange) {
				// Run 2
				if (_yawPosition < kYRange) {
					difference = _pitchPosition + (360 - positionYIn360);
					int yPosition = kYPosition - (difference * kYPositionMultiplier);
					
					return yPosition;
				} else {
					// Run Standard Position Check
					return [self checkYStandardPoint:positionYIn360];
				}
			} else {
				// Run Standard Position Check
				
				return [self checkYStandardPoint:positionYIn360];
			}
			
		}
	} else {
		if (_pitchPosition > rangeMinY && _pitchPosition < rangeMaxY) {
			int difference = 0;
			if (positionYIn360 < kYRange) {
				// Run 1
				if (_pitchPosition > 360 - kYRange) {
					difference = (360 - _pitchPosition) + positionYIn360;
					int yPosition = kYPosition + (difference * kYPositionMultiplier);
					
					return yPosition;
					
				} else {
					// Run Standard Position Check
					
					return [self checkYStandardPoint:positionYIn360];
					
				}
			} else if(positionYIn360 > 360 - kYRange) {
				// Run 2
				if (_pitchPosition < kYRange) {
					difference = _pitchPosition + (360 - positionYIn360);
					int yPosition = kYPosition - (difference * kYPositionMultiplier);
					
					return yPosition;
					
				} else {
					// Run Standard Position Check
					return [self checkYStandardPoint:positionYIn360];
				}
			} else {
				// Run Standard Position Check
				return [self checkYStandardPoint:positionYIn360];
			}
			
		}
	}
	
	self.hidden = YES;
	
	if (pitch < kYRange ) {
		return - self.frame.size.height;
	}else {
		return [UIScreen mainScreen].bounds.size.height + self.frame.size.height;
	}
}

- (int)getXPositionIn360:(float)yaw {
	self.hidden = NO;
	// X
	// Convert the yaw value to a value in the range of 0 to 360
	int positionXIn360 = yaw;
	if (positionXIn360 < 0) {
		positionXIn360 = 360 + positionXIn360;
	}
	
	BOOL checkAlternateRangeX = false;
	
	// Determine the minimum position for enemy ship
	int rangeMinX = positionXIn360 - kXRange;
	if (rangeMinX < 0) {
		rangeMinX = 360 + rangeMinX;
		checkAlternateRangeX = true;
	}
	
	// Determine the maximum position for the enemy ship
	int rangeMaxX = positionXIn360 + kXRange;
	if (rangeMaxX > 360) {
		rangeMaxX = rangeMaxX - 360;
		checkAlternateRangeX = true;
	}
	
	if (checkAlternateRangeX) {
		if ((_yawPosition < rangeMaxX || _yawPosition > rangeMinX ) || (_yawPosition > rangeMinX || _yawPosition < rangeMaxX)) {
			int difference = 0; // 保存设备的positionXIn360和image的yaw位置的角度差值
			if (positionXIn360 < kXRange) {
				// Run 1
				if (_yawPosition > 360 - kXRange) {
					difference = (360 - _yawPosition) + positionXIn360;
					int xPosition = kXPosition + (difference * kXPositionMultiplier);
					return xPosition;
				} else {
					// Run Standard Position Check
					return [self checkXStandardPoint:positionXIn360];
				}
			} else if(positionXIn360 > 360 - kXRange) {
				// Run 2
				if (_yawPosition < kXRange) {
					difference = _yawPosition + (360 - positionXIn360);
					int xPosition = kXPosition - (difference * kXPositionMultiplier);
					
					return xPosition;
				} else {
					// Run Standard Position Check
					return [self checkXStandardPoint:positionXIn360];
				}
			} else {
				// Run Standard Position Check
				return [self checkXStandardPoint:positionXIn360];
			}
		}
		
	} else {
		if (_yawPosition > rangeMinX && _yawPosition < rangeMaxX) {
			int difference = 0;
			if (positionXIn360 < kXRange) {
				// Run 1
				if (_yawPosition > 360 - kXRange) {
					difference = (360 - _yawPosition) + positionXIn360;
					int xPosition = kXPosition + (difference * kXPositionMultiplier);
					
					return xPosition;
				} else {
					// Run Standard Position Check
					
					return [self checkXStandardPoint:positionXIn360];
				}
			} else if(positionXIn360 > 360 - kXRange) {
				// Run 2
				if (_yawPosition < kXRange) {
					difference = _yawPosition + (360 - positionXIn360);
					int xPosition = kXPosition - (difference * kXPositionMultiplier);
					return xPosition;
					
				} else {
					// Run Standard Position Check
					return [self checkXStandardPoint:positionXIn360];
				}
			} else {
				// Run Standard Position Check
				return [self checkXStandardPoint:positionXIn360];
			}
			
		}
	}
	
	self.hidden = YES;
	if (yaw< kXRange ) {
		return - self.frame.size.width;
	}else {
		return [UIScreen mainScreen].bounds.size.width + self.frame.size.width;
	}
}

- (int)checkXStandardPoint:(int)positionXIn360 {
	int difference;
	if (_yawPosition > positionXIn360) {
		difference = _yawPosition - positionXIn360;
		int xPosition = kXPosition - (difference * kXPositionMultiplier);
		return xPosition;
		
	} else {
		difference = positionXIn360 - _yawPosition;
		int xPosition = kXPosition + (difference * kXPositionMultiplier);
		return xPosition;
	}
}

- (int)checkYStandardPoint:(int)positionYIn360 {
	int difference;
	if (_pitchPosition > positionYIn360) {
		difference = _pitchPosition - positionYIn360;
		int yPosition = kYPosition - (difference * kYPositionMultiplier);
		return yPosition;
		
	} else {
		difference = positionYIn360 - _pitchPosition;
		int yPosition = kYPosition + (difference * kYPositionMultiplier);
		return yPosition;
	}
}

@end
