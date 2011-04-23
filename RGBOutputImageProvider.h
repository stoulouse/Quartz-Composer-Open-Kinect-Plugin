//
//  RGBOutputImageProvider.h
//  ImageWithKinect
//
//  Created by Samuel Toulouse on 26/11/10.
//  Copyright 2010 Pirate & Co. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@class ImageWithKinectPlugIn;
@interface RGBOutputImageProvider : NSObject <QCPlugInOutputImageProvider>
{
	ImageWithKinectPlugIn*	_plugin;
	CGColorSpaceRef	_colorSpace;
}

@property(retain) ImageWithKinectPlugIn*	_plugin;

- (id) initWithPlugin:(ImageWithKinectPlugIn*)plugin;

@end


