//
//  ImageWithKinectPlugIn.h
//  ImageWithKinect
//
//  Created by Samuel Toulouse on 26/11/10.
//  Copyright (c) 2010 Pirate & Co. All rights reserved.
//

#import <Quartz/Quartz.h>
#include "libfreenect.h"
#include <pthread.h>

@class RGBOutputImageProvider;
@class DepthOutputImageProvider;

@interface ImageWithKinectPlugIn : QCPlugIn
{
@public
	freenect_context*	_f_ctx;
	freenect_device*	_f_dev;
	pthread_t	_freenect_thread;
	bool	_die;
	int	_freenect_angle;
	
	int16_t _ax,_ay,_az;
	double _dx,_dy,_dz;	
	
	pthread_mutex_t	_backbuf_mutex;
	pthread_cond_t	_frame_cond;
	
	int	_got_frames;
	uint8_t _rgb_back[FREENECT_RGB_SIZE];
	uint8_t _depth_back[FREENECT_RGB_SIZE];
	RGBOutputImageProvider*	_rgbImage;
	DepthOutputImageProvider*	_depthImage;
	uint16_t	_t_gamma[2048];
	
	bool	_useDepthTransform;
	NSMutableDictionary*	_vertices;
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

@property(assign) double outputAx;
@property(assign) double outputAy;
@property(assign) double outputAz;

@property(assign) double outputDx;
@property(assign) double outputDy;
@property(assign) double outputDz;

@property(assign) id<QCPlugInOutputImageProvider>	outputImageRGB;
@property(assign) id<QCPlugInOutputImageProvider>	outputImageDepth;

@property(assign) NSDictionary*	outputVertices;

@end
