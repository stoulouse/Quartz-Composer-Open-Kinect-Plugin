//
//  ImageWithKinectPlugIn.h
//  ImageWithKinect
//
//  Created by Samuel Toulouse on 26/11/10.
//  Copyright (c) 2010 Pirate & Co. All rights reserved.
//

#import <Quartz/Quartz.h>
#include "libfreenect.h"
#include "libfakenect.h"
#include <pthread.h>

#define FREENECT_RGB_SIZE 640*480*3

@class RGBOutputImageProvider;
@class DepthOutputImageProvider;

@interface ImageWithKinectPlugIn : QCPlugIn
{
@public
	freenect_context*	_f_ctx;
	freenect_device*	_f_dev;

	freenect_context*	_fake_ctx;
	
	pthread_t	_freenect_thread;
	bool	_die;
	int	_freenect_angle;
	freenect_led_options _freenect_led;
	
	int16_t _ax,_ay,_az;
	double _dx,_dy,_dz;	
	
	pthread_mutex_t	_depthbackbuf_mutex;
	pthread_mutex_t	_backbuf_mutex;
	pthread_cond_t	_frame_cond;
	
//	int	_got_frames;
	int _got_depth;
	int _got_rgb;
	
	uint8_t* _rgb_back;
	uint8_t* _rgb_mid;
	uint8_t* _rgb_front;
	
	uint8_t* _depth_front;
	uint8_t* _depth_mid;

	RGBOutputImageProvider*	_rgbImage;
	DepthOutputImageProvider*	_depthImage;
	
	uint16_t	_t_gamma[2048];
	
	bool	_useDepthTransform;
	
	double _depthMin;
	double _depthMax;
	double _depthAvg;

	double _depthClampMin;
	double _depthClampMax;
	
	BOOL	_useFakenect;
	NSString*	_fakenectDataPath;
	
	double	_depthNearestX;
	double	_depthNearestY;
	double	_depthNearestZ;
}

/*
Declare here the Obj-C 2.0 properties to be used as input and output ports for the plug-in e.g.
@property double inputFoo;
@property(assign) NSString* outputBar;
You can access their values in the appropriate plug-in methods using self.inputFoo or self.inputBar
*/

@property(assign) NSUInteger inputDeviceIdx;

@property(assign) NSUInteger inputLED;

@property(assign) double inputAngle;

@property(assign) BOOL	inputUseDepthTransform;
@property(assign) BOOL	inputUseFakenect;
@property(assign) NSString*	inputFakenectDataPath;

@property(assign) double outputAx;
@property(assign) double outputAy;
@property(assign) double outputAz;

@property(assign) double outputDx;
@property(assign) double outputDy;
@property(assign) double outputDz;

@property(assign) id<QCPlugInOutputImageProvider>	outputImageRGB;
@property(assign) id<QCPlugInOutputImageProvider>	outputImageDepth;

@property(assign) double outputRelativeDepthMin;

@property(assign) double outputNearestDepthX;
@property(assign) double outputNearestDepthY;
@property(assign) double outputNearestDepthZ;

@property(assign) double outputDepthMin;
@property(assign) double outputDepthMax;
@property(assign) double outputDepthAvg;

@property(assign) NSUInteger inputDepthClampMin;
@property(assign) NSUInteger inputDepthClampMax;


@end
