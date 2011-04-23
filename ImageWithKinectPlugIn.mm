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

@dynamic inputDeviceIdx, inputDepthClampMax, inputDepthClampMin, inputAngle, inputLED, inputUseDepthTransform;
@dynamic inputUseFakenect, inputFakenectDataPath;
@dynamic outputAx, outputAy, outputAz;
@dynamic outputDx, outputDy, outputDz;
@dynamic outputImageRGB, outputImageDepth;
@dynamic outputRelativeDepthMin, outputDepthMin, outputDepthMax, outputDepthAvg;

- (freenect_context*)context {
	return (_useFakenect ? _fake_ctx : _f_ctx);
}

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
	if ([key isEqualToString:@"inputDepthClampMin"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInteger:0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithUnsignedInteger:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithUnsignedInteger:2048], QCPortAttributeMaximumValueKey,
				@"Depth Clamp Min", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"inputDepthClampMax"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInteger:2048], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithUnsignedInteger:0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithUnsignedInteger:2048], QCPortAttributeMaximumValueKey,
				@"Depth Clamp Max", QCPortAttributeNameKey, nil];
	}
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
	if ([key isEqualToString:@"inputUseFakenect"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithBool:NO], QCPortAttributeDefaultValueKey,
				@"Fakenect", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"inputFakenectDataPath"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Fakenect Data Path", QCPortAttributeNameKey, nil];
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
	if ([key isEqualToString:@"outputDepthMin"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Depth Min", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputRelativeDepthMin"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Relative Depth Min", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputDepthMax"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Depth Max", QCPortAttributeNameKey, nil];
	}
	if ([key isEqualToString:@"outputDepthAvg"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				@"Depth Average", QCPortAttributeNameKey, nil];
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
		_useFakenect = NO;
		_fakenectDataPath = @"";
		
		/*
		 Allocate any permanent resource required by the plug-in.
		 */
		pthread_mutex_init(&_backbuf_mutex, 0);
		pthread_mutex_init(&_depthbackbuf_mutex, 0);
		
		_rgbImage = [[RGBOutputImageProvider alloc] initWithPlugin:self];	
		_depthImage = [[DepthOutputImageProvider alloc] initWithPlugin:self];	
		
		for (int i = 0; i < 2048; ++i) {
			float v = i/2048.0f;
			v = powf(v, 3)* 6;
			_t_gamma[i] = v*6*256;
		}		
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
	pthread_mutex_destroy(&_depthbackbuf_mutex);
	[_rgbImage release];
	[_depthImage release];
	
	[super dealloc];
}

@end

@implementation ImageWithKinectPlugIn (Execution)

void depth_cb(freenect_device *dev, void *v_depth, uint32_t timestamp) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	ImageWithKinectPlugIn* plugin = (ImageWithKinectPlugIn*)fakenect_get_user(dev);
	if (plugin && !plugin->_die) {
		int i;
		uint16_t* depth = (uint16_t*)v_depth;

		double depthMin = DBL_MAX;
		double depthMax = DBL_MIN;
		double depthAvg = 0.0;
		
		pthread_mutex_lock(&plugin->_depthbackbuf_mutex);
		for (i = 0; i < FREENECT_FRAME_PIX; ++i) {
			if (plugin->_useDepthTransform) {
				int pval = plugin->_t_gamma[depth[i]];			
				pval = (pval <= plugin->_depthClampMax ? pval : plugin->_depthClampMax);
				pval = (pval >= plugin->_depthClampMin ? pval - plugin->_depthClampMin : 0);
				int lb = pval & 0xff;
				plugin->_depth_mid[4*i+0] = 255;
				switch (pval>>8) {
					case 0:
						plugin->_depth_mid[4*i+1] = 255;
						plugin->_depth_mid[4*i+2] = 255-lb;
						plugin->_depth_mid[4*i+3] = 255-lb;
						break;
					case 1:
						plugin->_depth_mid[4*i+1] = 255;
						plugin->_depth_mid[4*i+2] = lb;
						plugin->_depth_mid[4*i+3] = 0;
						break;
					case 2:
						plugin->_depth_mid[4*i+1] = 255-lb;
						plugin->_depth_mid[4*i+2] = 255;
						plugin->_depth_mid[4*i+3] = 0;
						break;
					case 3:
						plugin->_depth_mid[4*i+1] = 0;
						plugin->_depth_mid[4*i+2] = 255;
						plugin->_depth_mid[4*i+3] = lb;
						break;
					case 4:
						plugin->_depth_mid[4*i+1] = 0;
						plugin->_depth_mid[4*i+2] = 255-lb;
						plugin->_depth_mid[4*i+3] = 255;
						break;
					case 5:
						plugin->_depth_mid[4*i+1] = 0;
						plugin->_depth_mid[4*i+2] = 0;
						plugin->_depth_mid[4*i+3] = 255-lb;
						break;
					default:
						plugin->_depth_mid[4*i+1] = 0;
						plugin->_depth_mid[4*i+2] = 0;
						plugin->_depth_mid[4*i+3] = 0;
						break;
				}
			} else {				
				int pval = depth[i];
				pval = (pval <= plugin->_depthClampMax ? pval : plugin->_depthClampMax);
				pval = (pval >= plugin->_depthClampMin ? pval - plugin->_depthClampMin : 0);
				int lb = 255.0 - (((double)pval) / 2048.0) * 255.0;
//				int lb = pval & 0xff;
				plugin->_depth_mid[4*i+0] = lb;
				plugin->_depth_mid[4*i+1] = lb;
				plugin->_depth_mid[4*i+2] = lb;
				plugin->_depth_mid[4*i+3] = lb;
			}
			
			{
				int pval = depth[i];
				pval = (pval <= plugin->_depthClampMax ? pval : plugin->_depthClampMax);
				pval = (pval >= plugin->_depthClampMin ? pval - plugin->_depthClampMin : 0);
			
				depthMin = (pval < depthMin ? pval : depthMin);
				depthMax = (pval > depthMax ? pval : depthMax);
				
				depthAvg += pval;
			}
		}

		plugin->_depthMax = depthMax;
		plugin->_depthMin = depthMin;
		plugin->_depthAvg = depthAvg / (depthMax * FREENECT_FRAME_PIX);
		
		plugin->_got_depth++;
		pthread_mutex_unlock(&plugin->_depthbackbuf_mutex);
	}
	
	[pool release];
}

void rgb_cb(freenect_device *dev, void *rgb, uint32_t timestamp) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	ImageWithKinectPlugIn* plugin = (ImageWithKinectPlugIn*)fakenect_get_user(dev);
	if (plugin && !plugin->_die) {
		pthread_mutex_lock(&plugin->_backbuf_mutex);
		
		// swap buffers
		assert (plugin->_rgb_back == rgb);
		plugin->_rgb_back = plugin->_rgb_mid;
		
		fakenect_set_video_buffer(dev, plugin->_rgb_back);
		plugin->_rgb_mid = (uint8_t*)rgb;
		
		plugin->_got_rgb++;
		
		pthread_mutex_unlock(&plugin->_backbuf_mutex);
	}
	
	[pool release];
}

void* freenect_threadfunc(void *arg) {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	ImageWithKinectPlugIn* plugin = (ImageWithKinectPlugIn*)arg;
	
	int accelCount = 0;
	
	plugin->_got_depth = 0;
	plugin->_got_rgb = 0;
	fakenect_set_tilt_degs(plugin->_f_dev,plugin->_freenect_angle);
	fakenect_set_led(plugin->_f_dev,plugin->_freenect_led);
	fakenect_set_depth_callback(plugin->_f_dev, depth_cb);
	fakenect_set_video_callback(plugin->_f_dev, rgb_cb);
	fakenect_set_video_format(plugin->_f_dev, FREENECT_VIDEO_RGB);
	fakenect_set_depth_format(plugin->_f_dev, FREENECT_DEPTH_11BIT);
	fakenect_set_video_buffer(plugin->_f_dev, plugin->_rgb_back);
	
	fakenect_start_depth(plugin->_f_dev);
	fakenect_start_video(plugin->_f_dev);
	
	while(!plugin->_die && fakenect_process_events([plugin context]) >= 0 )
	{
		if (accelCount++ >= 2000)
		{
			accelCount = 0;
			freenect_raw_tilt_state* state;
			fakenect_update_tilt_state(plugin->_f_dev);
			state = fakenect_get_tilt_state(plugin->_f_dev);
			double dx,dy,dz;
			fakenect_get_mks_accel(state, &dx, &dy, &dz);			
			fakenect_get_mks_accel(state, &plugin->_dx, &plugin->_dy, &plugin->_dz);
			NSLog(@"\r raw acceleration: %4d %4d %4d  mks acceleration: %4f %4f %4f", state->accelerometer_x, state->accelerometer_y, state->accelerometer_z, dx, dy, dz);
		}
	}
	
	NSLog(@"\nshutting down streams...\n");
	
	fakenect_set_led(plugin->_f_dev,LED_OFF);
	
	fakenect_stop_depth(plugin->_f_dev);
	fakenect_stop_video(plugin->_f_dev);
	
	fakenect_close_device(plugin->_f_dev);
	
	plugin->_f_dev = 0;
	
	NSLog(@"-- done!\n");
	
	[pool release];
	
	return 0;
}

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	_depth_mid = (uint8_t*)malloc(640*480*4);
	_depth_front = (uint8_t*)malloc(640*480*4);
	_rgb_back = (uint8_t*)malloc(640*480*3);
	_rgb_mid = (uint8_t*)malloc(640*480*3);
	_rgb_front = (uint8_t*)malloc(640*480*3);
	
	/*
	 Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	 Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	 */
	if (freenect_init(&_f_ctx, NULL) < 0) {
		NSLog(@"freenect_init() failed\n");
		return NO;
	}
	
	freenect_set_log_level(_f_ctx, FREENECT_LOG_DEBUG);		
	
	if (fakenect_init(&_fake_ctx, NULL) < 0) {
		NSLog(@"freenect_init() failed\n");
		return NO;
	}
	
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
		fakenect_set_tilt_degs(_f_dev,_freenect_angle);
	}
	if ([self didValueForInputKeyChange: @"inputLED"] && _f_dev ) {
		freenect_led_options led = (freenect_led_options)self.inputLED;
		fakenect_set_led(_f_dev, led);
	}
	
	if ([self didValueForInputKeyChange: @"inputDeviceIdx"] || [self didValueForInputKeyChange: @"inputUseFakenect"] || [self didValueForInputKeyChange: @"inputFakenectDataPath"] ) {
		if (_freenect_thread) {
			_die = true;
			pthread_join(_freenect_thread, 0);
			_freenect_thread = 0;
		}
		
		if (self.inputUseFakenect && self.inputFakenectDataPath) {
			if ([[NSFileManager defaultManager] fileExistsAtPath: self.inputFakenectDataPath]) {
				setenv("FAKENECT_PATH", [self.inputFakenectDataPath UTF8String], 1);
				_useFakenect = YES;
			}
		} else {
			_useFakenect = NO;
		}
		
		int nr_devices = fakenect_num_devices ([self context]);
		NSLog(@"Number of devices found: %d\n", nr_devices);
		
		if (nr_devices >= 1) {
			NSUInteger idx = self.inputDeviceIdx;
			
			if (idx >= nr_devices)
				idx = 0;
			
			if (fakenect_open_device([self context], &_f_dev, idx) >= 0) {
				fakenect_set_user(_f_dev, self);
				
				_freenect_angle = self.inputAngle;
				_freenect_led = (freenect_led_options)self.inputLED;
				
				_die = false;
				int res = pthread_create(&_freenect_thread, NULL, freenect_threadfunc, self);
				if (res) {
					fakenect_close_device(_f_dev);
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
	
	if (_depthClampMax != _depthClampMin)
		self.outputRelativeDepthMin = _depthMin / (_depthClampMax - _depthClampMin);
	self.outputDepthMax = _depthMax;
	self.outputDepthMin = _depthMin;
	self.outputDepthAvg = _depthAvg;
		
	_depthClampMin = self.inputDepthClampMin;
	_depthClampMax = self.inputDepthClampMax;
	
	_useDepthTransform = self.inputUseDepthTransform;
	
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
	
	fakenect_shutdown(_fake_ctx);
	_fake_ctx = 0;

	free(_depth_mid);
	free(_depth_front);
	free(_rgb_back);
	free(_rgb_mid);
	free(_rgb_front);
}

@end
