#ifndef LIBFAKENECT_H
#define LIBFAKENECT_H

#include <stdint.h>
#include <libfreenect.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 *  libfakenect.h
 *  ImageWithKinect
 *
 *  Created by Samuel Toulouse on 23/04/11.
 *  Copyright 2011 Pirate & Co. All rights reserved.
 *
 */

/**
 * Initialize a freenect context and do any setup required for
 * platform specific USB libraries.
 *
 * @param ctx Address of pointer to freenect context struct to allocate and initialize
 * @param usb_ctx USB context to initialize. Can be NULL if not using multiple contexts.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_init(freenect_context **ctx, freenect_usb_context *usb_ctx);

/**
 * Closes the device if it is open, and frees the context
 *
 * @param ctx freenect context to close/free
 *
 * @return 0 on success
 */
FREENECTAPI int fakenect_shutdown(freenect_context *ctx);

/**
 * Set the log level for the specified freenect context
 *
 * @param ctx context to set log level for
 * @param level log level to use (see freenect_loglevel enum)
 */
FREENECTAPI void fakenect_set_log_level(freenect_context *ctx, freenect_loglevel level);

/**
 * Callback for log messages (i.e. for rerouting to a file instead of
 * stdout)
 *
 * @param ctx context to set log callback for
 * @param cb callback function pointer
 */
FREENECTAPI void fakenect_set_log_callback(freenect_context *ctx, freenect_log_cb cb);

/**
 * Calls the platform specific usb event processor
 *
 * @param ctx context to process events for
 *
 * @return 0 on success, other values on error, platform/library dependant
 */
FREENECTAPI int fakenect_process_events(freenect_context *ctx);

/**
 * Return the number of kinect devices currently connected to the
 * system
 *
 * @param ctx Context to access device count through
 *
 * @return Number of devices connected, < 0 on error
 */
FREENECTAPI int fakenect_num_devices(freenect_context *ctx);

/**
 * Opens a kinect device via a context. Index specifies the index of
 * the device on the current state of the bus. Bus resets may cause
 * indexes to shift.
 *
 * @param ctx Context to open device through
 * @param dev Device structure to assign opened device to
 * @param index Index of the device on the bus
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_open_device(freenect_context *ctx, freenect_device **dev, int index);

/**
 * Closes a device that is currently open
 *
 * @param dev Device to close
 *
 * @return 0 on success
 */
FREENECTAPI int fakenect_close_device(freenect_device *dev);

/**
 * Set the device user data, for passing generic information into
 * callbacks
 *
 * @param dev Device to attach user data to
 * @param user User data to attach
 */
FREENECTAPI void fakenect_set_user(freenect_device *dev, void *user);

/**
 * Retrieve the pointer to user data from the device struct
 *
 * @param dev Device from which to get user data
 *
 * @return Pointer to user data
 */
FREENECTAPI void *fakenect_get_user(freenect_device *dev);

/**
 * Set callback for depth information received event
 *
 * @param dev Device to set callback for
 * @param cb Function pointer for processing depth information
 */
FREENECTAPI void fakenect_set_depth_callback(freenect_device *dev, freenect_depth_cb cb);

/**
 * Set callback for video information received event
 *
 * @param dev Device to set callback for
 * @param cb Function pointer for processing video information
 */
FREENECTAPI void fakenect_set_video_callback(freenect_device *dev, freenect_video_cb cb);

/**
 * Set the format for depth information
 *
 * @param dev Device to set depth information format for
 * @param fmt Format of depth information. See freenect_depth_format enum.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_set_depth_format(freenect_device *dev, freenect_depth_format fmt);

/**
 * Set the format for video information
 *
 * @param dev Device to set video information format for
 * @param fmt Format of video information. See freenect_video_format enum.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_set_video_format(freenect_device *dev, freenect_video_format fmt);

/**
 * Set the buffer to store depth information to. Size of buffer is
 * dependant on depth format. See FREENECT_DEPTH_*_SIZE defines for
 * more information.
 *
 * @param dev Device to set depth buffer for.
 * @param buf Buffer to store depth information to.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_set_depth_buffer(freenect_device *dev, void *buf);

/**
 * Set the buffer to store depth information to. Size of buffer is
 * dependant on video format. See FREENECT_VIDEO_*_SIZE defines for
 * more information.
 *
 * @param dev Device to set video buffer for.
 * @param buf Buffer to store video information to.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_set_video_buffer(freenect_device *dev, void *buf);

/**
 * Start the depth information stream for a device.
 *
 * @param dev Device to start depth information stream for.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_start_depth(freenect_device *dev);

/**
 * Start the video information stream for a device.
 *
 * @param dev Device to start video information stream for.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_start_video(freenect_device *dev);

/**
 * Stop the depth information stream for a device
 *
 * @param dev Device to stop depth information stream on.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_stop_depth(freenect_device *dev);

/**
 * Stop the video information stream for a device
 *
 * @param dev Device to stop video information stream on.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_stop_video(freenect_device *dev);

/**
 * Updates the accelerometer state using a blocking control message
 * call.
 *
 * @param dev Device to get accelerometer data from
 *
 * @return 0 on success, < 0 on error. Accelerometer data stored to
 * device struct.
 */
FREENECTAPI int fakenect_update_tilt_state(freenect_device *dev);

/**
 * Retrieve the tilt state from a device
 *
 * @param dev Device to retrieve tilt state from
 *
 * @return The tilt state struct of the device
 */
FREENECTAPI freenect_raw_tilt_state* fakenect_get_tilt_state(freenect_device *dev);

/**
 * Return the tilt state, in degrees with respect to the horizon
 *
 * @param state The tilt state struct from a device
 *
 * @return Current degree of tilt of the device
 */
FREENECTAPI double fakenect_get_tilt_degs(freenect_raw_tilt_state *state);

/**
 * Set the tilt state of the device, in degrees with respect to the
 * horizon. Uses blocking control message call to update
 * device. Function return does not reflect state of device, device
 * may still be moving to new position after the function returns. Use
 * freenect_get_tilt_status() to find current movement state.
 *
 * @param dev Device to set tilt state
 * @param angle Angle the device should tilt to
 *
 * @return 0 on success, < 0 on error.
 */
FREENECTAPI int fakenect_set_tilt_degs(freenect_device *dev, double angle);

/**
 * Return the movement state of the tilt motor (moving, stopped, etc...)
 *
 * @param state Raw state struct to get the tilt status code from
 *
 * @return Status code of the tilt device. See
 * freenect_tilt_status_code enum for more info.
 */
FREENECTAPI freenect_tilt_status_code fakenect_get_tilt_status(freenect_raw_tilt_state *state);

/**
 * Set the state of the LED. Uses blocking control message call to
 * update device.
 *
 * @param dev Device to set the LED state
 * @param option LED state to set on device. See freenect_led_options enum.
 *
 * @return 0 on success, < 0 on error
 */
FREENECTAPI int fakenect_set_led(freenect_device *dev, freenect_led_options option);

/**
 * Get the axis-based gravity adjusted accelerometer state, as laid
 * out via the accelerometer data sheet, which is available at
 *
 * http://www.kionix.com/Product%20Sheets/KXSD9%20Product%20Brief.pdf
 *
 * @param state State to extract accelerometer data from
 * @param x Stores X-axis accelerometer state
 * @param y Stores Y-axis accelerometer state
 * @param z Stores Z-axis accelerometer state
 */
FREENECTAPI void fakenect_get_mks_accel(freenect_raw_tilt_state *state, double* x, double* y, double* z);

#ifdef __cplusplus
}
#endif

#endif //

