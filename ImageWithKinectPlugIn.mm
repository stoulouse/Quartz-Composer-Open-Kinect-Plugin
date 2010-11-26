//
//  ImageWithKinectPlugIn.m
//  ImageWithKinect
//
//  Created by Samuel Toulouse on 26/11/10.
//  Copyright (c) 2010 Pirate & Co. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>
#import "ImageWithKinectPlugIn.h"
#import "RGBOutputImageProvider.h"
#import "DepthOutputImageProvider.h"

#define	kQCPlugIn_Name				@"ImageWithKinect"
#define	kQCPlugIn_Description		@"ImageWithKinect description"

@implementation ImageWithKinectPlugIn

/*
Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
@dynamic inputFoo, outputBar;
*/

@dynamic inputDeviceIdx, inputAngle, inputLED, inputUseDepthTransform;
@dynamic outputAx, outputAy, outputAz;
@dynamic outputDx, outputDy, outputDz;
@dynamic outputImageRGB, outputImageDepth;
@dynamic outputVertices;

+ (NSDictionary*) attributes
{
	/*
	Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
	*/
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			kQCPlugIn_Name, QCPlugInAttributeNameKey, 
			kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/*
	Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
	*/
	if ([key isEqualToString:@"inputDeviceIdx"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInteger:0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithUnsignedInteger:0], QCPortAttributeMinimumValueKey,
				@"Device", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"inputAngle"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInteger:0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithInteger:-31], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithInteger:31], QCPortAttributeMaximumValueKey,
				@"Angle", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"inputUseDepthTransform"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Depth Transform", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"inputLED"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInteger:LED_RED], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithInteger:LED_OFF], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithInteger:LED_BLINK_RED_YELLOW], QCPortAttributeMaximumValueKey,
				[NSArray arrayWithObjects:@"Off", @"Green", @"Red", @"Yellow", @"Blink Yellow", @"Blink Green", @"Blink Red Yellow", nil], QCPortAttributeMenuItemsKey,
				@"LED", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputVertices"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Vertices", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputAx"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Raw Accel X", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputAy"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Raw Accel Y", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputAz"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Raw Accel Z", QCPortAttributeNameKey, nil];
	}

	if ([key isEqualToString:@"outputDx"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Mks Accel X", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputDy"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Mks Accel Y", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputDz"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Mks Accel Z", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputImageRGB"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"RGB Image", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputImageDepth"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Depth Image", QCPortAttributeNameKey, nil];
	}

	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/*
	Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	*/
	
	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode) timeMode
{
	/*
	Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	*/
	
	return kQCPlugInTimeModeIdle;
}

- (id) init
{
	if(self = [super init]) {
		/*
		Allocate any permanent resource required by the plug-in.
		*/
		pthread_mutex_init(&_backbuf_mutex, 0);
		pthread_cond_init(&_frame_cond, 0);
		
		_rgbImage = [[RGBOutputImageProvider alloc] initWithPlugin:self];	
		_depthImage = [[DepthOutputImageProvider alloc] initWithPlugin:self];	

		for (int i = 0; i < 2048; ++i) {
			float v = i/2048.0f;
			v = powf(v, 3)* 6;
			_t_gamma[i] = v*6*256;
		}
		
		_vertices = [[NSMutableDictionary alloc] initWithCapacity: 0];
		
//		for (int i = 0; i < FREENECT_FRAME_H; ++i) {
//			for (int j = 0; j < FREENECT_FRAME_W; ++j) {
//				[_vertices setObject:[NSMutableArray arrayWithObjects: 
//									  [NSNumber numberWithInt:j],
//									  [NSNumber numberWithInt:i],
//									  [NSNumber numberWithFloat:0.0f],
//									  nil] 
//							  forKey:[NSNumber numberWithInt: j + i * (int)FREENECT_FRAME_W]];
//			}
//		}
	}
	
	return self;
}

- (void) finalize
{
	/*
	Release any non garbage collected resources created in -init.
	*/
	
	[super finalize];
}

- (void) dealloc
{
	/*
	Release any resources created in -init.
	*/
	pthread_mutex_destroy(&_backbuf_mutex);
	pthread_cond_destroy(&_frame_cond);
	[_rgbImage release];
	[_depthImage release];
	[_vertices release];
	
	[super dealloc];
}

@end

@implementation ImageWithKinectPlugIn (Execution)

void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	ImageWithKinectPlugIn* plugin = (ImageWithKinectPlugIn*)freenect_get_user(dev);
	if (plugin) {
		int i;
		freenect_depth* depth = (freenect_depth*)v_depth;
		
		pthread_mutex_lock(&plugin->_backbuf_mutex);
		for (i = 0; i < FREENECT_FRAME_PIX; ++i) {
			if (plugin->_useDepthTransform) {
			int pval = plugin->_t_gamma[depth[i]];			
			int lb = pval & 0xff;
			switch (pval>>8) {
				case 0:
					plugin->_depth_back[3*i+0] = 255;
					plugin->_depth_back[3*i+1] = 255-lb;
					plugin->_depth_back[3*i+2] = 255-lb;
					break;
				case 1:
					plugin->_depth_back[3*i+0] = 255;
					plugin->_depth_back[3*i+1] = lb;
					plugin->_depth_back[3*i+2] = 0;
					break;
				case 2:
					plugin->_depth_back[3*i+0] = 255-lb;
					plugin->_depth_back[3*i+1] = 255;
					plugin->_depth_back[3*i+2] = 0;
					break;
				case 3:
					plugin->_depth_back[3*i+0] = 0;
					plugin->_depth_back[3*i+1] = 255;
					plugin->_depth_back[3*i+2] = lb;
					break;
				case 4:
					plugin->_depth_back[3*i+0] = 0;
					plugin->_depth_back[3*i+1] = 255-lb;
					plugin->_depth_back[3*i+2] = 255;
					break;
				case 5:
					plugin->_depth_back[3*i+0] = 0;
					plugin->_depth_back[3*i+1] = 0;
					plugin->_depth_back[3*i+2] = 255-lb;
					break;
				default:
					plugin->_depth_back[3*i+0] = 0;
					plugin->_depth_back[3*i+1] = 0;
					plugin->_depth_back[3*i+2] = 0;
					break;
			}
			} else {				
				int pval = depth[i];
				int lb = pval;
				plugin->_depth_back[3*i+0] = lb;
				plugin->_depth_back[3*i+1] = lb;
				plugin->_depth_back[3*i+2] = lb;
			}

		}
		plugin->_got_frames++;
		pthread_cond_signal(&plugin->_frame_cond);
		pthread_mutex_unlock(&plugin->_backbuf_mutex);
	}
	
	[pool release];
}

void rgb_cb(freenect_device *dev, freenect_pixel *rgb, uint32_t timestamp) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	ImageWithKinectPlugIn* plugin = (ImageWithKinectPlugIn*)freenect_get_user(dev);
	if (plugin) {
		pthread_mutex_lock(&plugin->_backbuf_mutex);
		plugin->_got_frames++;
		memcpy(plugin->_rgb_back, rgb, FREENECT_RGB_SIZE);
		pthread_cond_signal(&plugin->_frame_cond);
		pthread_mutex_unlock(&plugin->_backbuf_mutex);
	}
	
	[pool release];
}

void* freenect_threadfunc(void *arg) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	ImageWithKinectPlugIn* plugin = (ImageWithKinectPlugIn*)arg;
	
	plugin->_got_frames = 0;
	freenect_set_tilt_degs(plugin->_f_dev,plugin->_freenect_angle);
	freenect_set_led(plugin->_f_dev,LED_RED);
	freenect_set_depth_callback(plugin->_f_dev, depth_cb);
	freenect_set_rgb_callback(plugin->_f_dev, rgb_cb);
	freenect_set_rgb_format(plugin->_f_dev, FREENECT_FORMAT_RGB);
	freenect_set_depth_format(plugin->_f_dev, FREENECT_FORMAT_11_BIT);
	
	freenect_start_depth(plugin->_f_dev);
	freenect_start_rgb(plugin->_f_dev);
	
	while(!plugin->_die && freenect_process_events(plugin->_f_ctx) >= 0 )
	{
		freenect_get_raw_accel(plugin->_f_dev, &plugin->_ax, &plugin->_ay, &plugin->_az);
		freenect_get_mks_accel(plugin->_f_dev, &plugin->_dx, &plugin->_dy, &plugin->_dz);
	}
	
	NSLog(@"\nshutting down streams...\n");
	
	freenect_set_led(plugin->_f_dev,LED_OFF);

	freenect_stop_depth(plugin->_f_dev);
	freenect_stop_rgb(plugin->_f_dev);
	
	freenect_close_device(plugin->_f_dev);
	
	plugin->_f_dev = 0;
	
	NSLog(@"-- done!\n");
	
	[pool release];

	return 0;
}

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	*/
	if (freenect_init(&_f_ctx, NULL) < 0) {
		NSLog(@"freenect_init() failed\n");
		return NO;
	}
	
	freenect_set_log_level(_f_ctx, FREENECT_LOG_DEBUG);		
	
	_freenect_angle = 0;
	_die = false;
	
	return YES;
}

- (void) enableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
	*/
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	/*
	Called by Quartz Composer whenever the plug-in instance needs to execute.
	Only read from the plug-in inputs and produce a result (by writing to the plug-in outputs or rendering to the destination OpenGL context) within that method and nowhere else.
	Return NO in case of failure during the execution (this will prevent rendering of the current frame to complete).
	
	The OpenGL context for rendering can be accessed and defined for CGL macros using:
	CGLContextObj cgl_ctx = [context CGLContextObj];
	*/
	self.outputImageRGB = _rgbImage;
	self.outputImageDepth = _depthImage;

	if ([self didValueForInputKeyChange: @"inputAngle"] && _f_dev ) {
		_freenect_angle = self.inputAngle;
		freenect_set_tilt_degs(_f_dev,_freenect_angle);
	}
	if ([self didValueForInputKeyChange: @"inputLED"] && _f_dev ) {
		freenect_led_options led = (freenect_led_options)self.inputLED;
		freenect_set_led(_f_dev, led);
	}
	
	if ([self didValueForInputKeyChange: @"inputDeviceIdx"] ) {
		int nr_devices = freenect_num_devices (_f_ctx);
		NSLog(@"Number of devices found: %d\n", nr_devices);
		
		if (nr_devices >= 1) {
			NSUInteger idx = self.inputDeviceIdx;
			
			if (idx >= nr_devices)
				idx = 0;
			
			if (_freenect_thread) {
				_die = true;
				pthread_join(_freenect_thread, 0);
				_freenect_thread = 0;
			}
			
			if (freenect_open_device(_f_ctx, &_f_dev, idx) >= 0) {
				freenect_set_user(_f_dev, self);
				
				_die = false;
				int res = pthread_create(&_freenect_thread, NULL, freenect_threadfunc, self);
				if (res) {
					freenect_close_device(_f_dev);
					_f_dev = 0;
					_freenect_thread = 0;
					NSLog(@"pthread_create failed\n");
				}
			} else {
				_f_dev = 0;
				NSLog(@"Could not open device\n");
			}
		}
	}
	
	self.outputAx = _ax;
	self.outputAy = _ay;
	self.outputAz = _az;
	
	self.outputDx = _dx;
	self.outputDy = _dy;
	self.outputDz = _dz;

	_useDepthTransform = self.inputUseDepthTransform;

//	for (int i = 0; i < FREENECT_FRAME_H; ++i) {
//		for (int j = 0; j < FREENECT_FRAME_W; ++j) {
//			NSMutableArray* tmp = [_vertices objectForKey:[NSNumber numberWithInt: j + i * (int)FREENECT_FRAME_W]];
//			[tmp replaceObjectAtIndex:2 withObject:			
//			 [NSNumber numberWithFloat:
//			  (_depth_back[j * 3 + i * (int)FREENECT_FRAME_W * 3 + 0] +
//			   _depth_back[j * 3 + i * (int)FREENECT_FRAME_W * 3 + 1] +
//			   _depth_back[j * 3 + i * (int)FREENECT_FRAME_W * 3 + 2]) / 3.0f]];
//		}
//	}
	self.outputVertices = _vertices;

	return YES;
}

- (void) disableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
	*/
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
	*/
	_die = true;
	pthread_join(_freenect_thread, 0);
	_freenect_thread = 0;
	
	freenect_shutdown(_f_ctx);
	_f_ctx = 0;
}

@end
