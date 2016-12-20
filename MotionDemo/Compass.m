//
//  Compass.m
//  MotionDemo
//
//  Created by songziqiang on 2016/12/19.
//  Copyright © 2016年 songziqiang. All rights reserved.
//

//
// Compass.m
// AugmentedReality
//
// Created by Dany Humbert on 20/02/2014.
// Copyright (c) 2014 Dany Humbert. All rights reserved.
//

#import "Compass.h"

#define IN_DEGREES(__ANGLE__) ((__ANGLE__) * 180 / M_PI)

@implementation Compass
CMAttitude *attitude;
CMQuaternion quaternion;
CMRotationMatrix rotationMatrix;
double yaw;
double pitch;
double roll;
double gyro_x;
double gyro_y;
double gyro_z;
double acc_x;
double acc_y;
double acc_z;
float updateSpeed;
UIView *userview;
CADisplayLink *motionDisplayLink;
CMMotionManager *motionManager;
/**
 @author Dany
 @date 20 fev 2014
 @brief Singleton for Compass class
 **/
+ (id) getSingleton:(UIView *)view
{
 userview = view;
 static Compass *sharedMyManager = nil;
 static dispatch_once_t onceToken;
 dispatch_once(&onceToken, ^{
  sharedMyManager = [[self alloc] init];
 });
 return sharedMyManager;
}
/**
 @author Dany
 @date 21 fev 2014
 @brief init method for compass class
 **/
-(id) init
{
 if((self=[super init])) {
  updateSpeed = 1.0/60.0;
  motionManager = [[CMMotionManager alloc] init];
  motionManager.deviceMotionUpdateInterval = updateSpeed;
  motionDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(motionRefresh:)];
  [motionDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  if ([motionManager isGyroAvailable]) {
   [motionManager startGyroUpdates];
   [motionManager startDeviceMotionUpdates];
   [motionManager startMagnetometerUpdates];
  }
 }
 return self;
}
/**
 @author Dany
 @date 21 fev 2014
 @brief Refresh all values from sensors
 **/
-(void)motionRefresh:(id)sender
{
 attitude = motionManager.deviceMotion.attitude;
 rotationMatrix = motionManager.deviceMotion.attitude.rotationMatrix;
 quaternion = motionManager.deviceMotion.attitude.quaternion;
 yaw =  IN_DEGREES(motionManager.deviceMotion.attitude.yaw);
 roll = IN_DEGREES(motionManager.deviceMotion.attitude.roll);
 pitch = IN_DEGREES(motionManager.deviceMotion.attitude.pitch);
 gyro_x = IN_DEGREES(motionManager.gyroData.rotationRate.x);
 gyro_y = IN_DEGREES(motionManager.gyroData.rotationRate.y);
 gyro_z = IN_DEGREES(motionManager.gyroData.rotationRate.z);
 acc_x = IN_DEGREES(motionManager.accelerometerData.acceleration.x);
 acc_y = IN_DEGREES(motionManager.accelerometerData.acceleration.y);
 acc_z = IN_DEGREES(motionManager.accelerometerData.acceleration.z);
}
#pragma mark -
#pragma Getters Sensors Values
/**
 @author Dany
 @date 21 fev 2014
 @brief return current heading relative to sensors values
 **/
- (double) getHeading
{
 double heading = 0.0;
 /**
  // @remarks FROM http://www.dulaccc.me/2013/03/computing-the-ios-device-tilt.html || Wrong values returned
  heading = asin(2*(currentSensorState.quaternion.x*currentSensorState.quaternion.z - currentSensorState.quaternion.w*currentSensorState.quaternion.y));
  heading = RAD2DEG * yaw;
  **/
 /**
  // @remarks FROM http://stackoverflow.com/questions/9341223/how-can-i-get-the-heading-of-the-device-with-cmdevicemotion-in-ios-5 || Wrong values returned
  heading = M_PI + atan2(currentSensorState.rotationMatrix.m22, currentSensorState.rotationMatrix.m12);
  heading = heading*RAD2DEG;
  **/
 /**
  // @remarks FROM http://stackoverflow.com/questions/17917016/corelocation-heading-base-on-back-camera-augmented-reality || Wrong values returned
  float aspect = fabsf(userview.bounds.size.width / userview.bounds.size.height);
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0f), aspect, 0.1f, 100.0f);
  CMRotationMatrix r = self.motionManager.deviceMotion.attitude.rotationMatrix;
  GLKMatrix4 camFromIMU = GLKMatrix4Make(r.m11, r.m12, r.m13, 0,
  r.m21, r.m22, r.m23, 0,
  r.m31, r.m32, r.m33, 0,
  0,  0,  0,  1);
  GLKMatrix4 viewFromCam = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, 0);
  GLKMatrix4 imuFromModel = GLKMatrix4Identity;
  GLKMatrix4 viewModel = GLKMatrix4Multiply(imuFromModel, GLKMatrix4Multiply(camFromIMU, viewFromCam));
  bool isInvertible;
  GLKMatrix4 modelView = GLKMatrix4Invert(viewModel, &isInvertible);
  int viewport[4];
  viewport[0] = 0.0f;
  viewport[1] = 0.0f;
  viewport[2] = userview.frame.size.width;
  viewport[3] = userview.frame.size.height;
  bool success;
  //assume center of the view
  GLKVector3 vector3 = GLKVector3Make(userview.frame.size.width/2, userview.frame.size.height/2, 1.0);
  GLKVector3 calculatedPoint = GLKMathUnproject(vector3, modelView, projectionMatrix, viewport, &success);
  if(success)
  {
  //CMAttitudeReferenceFrameXTrueNorthZVertical always point x to true north
  //with that, -y become east in 3D world
  float angleInRadian = atan2f(-calculatedPoint.y, calculatedPoint.x);
  heading = angleInRadian*RAD2DEG;
  }
  **/
 /**
  // @remarks FROM http://stackoverflow.com/questions/10692344/cmdevicemotion-yaw-values-unstable-when-iphone-is-vertical || Wrong values returned
  float yawDegrees = currentSensorState.yaw;
  float rollDegrees = currentSensorState;
  double rotationDegrees;
  if(rollDegrees < 0 && yawDegrees < 0) // This is the condition where simply
  // summing yawDegrees with rollDegrees
  // wouldn't work.
  // Suppose yaw = -177 and pitch = -165.
  // rotationDegrees would then be -342,
  // making your rotation angle jump all
  // the way around the circle.
  {
  rotationDegrees = 360 - (-1 * (yawDegrees + rollDegrees));
  }
  else
  {
  rotationDegrees = yawDegrees + rollDegrees;
  }
  heading = rotationDegrees;
  // Use rotationDegrees with range 0 - 360 to do whatever you want.
  **/
 /**
  // @remarks FROM http://www.raywenderlich.com/3997/augmented-reality-tutorial-for-ios || Wrong values returned
  // Convert the radians yaw value to degrees then round up/down
  float yaw = roundf((float)(currentSensorState.yaw));
  // Convert the yaw value to a value in the range of 0 to 360
  int heading = yaw;
  if (heading < 0) {
  heading += 360;
  }
  **/
 /**
  // @remarks Personnal test from android development experience
  heading = yaw - roll;
  // TODO : use rotation matrix to handle phone position
  **/
 return heading;
}

//// 1. After implementing locationListner i take magnetic and true heading
//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
//{
// globalHeading = newHeading;
//}
//// 2. In a function called 'x time second', i get my heading for AR by :
//- (void) updateCompassValues
//{
//	// 2.1 Get Tilt Compensation
// double tiltCompensation = IN_DEGREES(asin(2*(quaternion.x*quaternion.z - quaternion.w*quaternion.y)));
// // 2.2 I transform magneticHeading with this tilt compensation
// currentHeading = globalHeading.magneticHeading + tiltCompensation;
//}

@end
