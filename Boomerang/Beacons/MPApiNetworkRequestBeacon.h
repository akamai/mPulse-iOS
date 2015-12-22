//
//  MPApiNetworkRequestBeacon.h
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBeacon.h"

@interface MPApiNetworkRequestBeacon : MPBeacon

//
// Methods
//

/**
 * Initializes a network request with the specified URL
 * @param url URL
 */
+(id) initWithURL:(NSURL *)url;

/**
 * Ends a successful network request
 * @param bytes Bytes recieved
 */
-(void) endRequestWithBytes:(NSUInteger)bytes;

/**
 * Ends an unsuccessful network request with an error
 * @param error Error code
 * @param errorMessage Error message
 */
-(void) setNetworkError:(NSInteger)error errorMessage:(NSString *)errorMessage;

//
// Properties
//

/**
 * Error message
 */
@property NSString *errorMessage;

/**
 * Session token when this request was started on
 */
@property int sessionToken;

//
// Properties on the Protobuf beacon
//
/**
 * Network request duration
 */
@property int duration;

/**
 * URL
 */
@property NSString *url;

/**
 * Network error code
 */
@property short networkErrorCode;

//
// These breakdowns are not yet filled in, but we would like to include
// them at some point
//
/**
 * DNS time (milliseonds)
 */
@property int dns;

/**
 * TCP time (milliseonds)
 */
@property int tcp;

/**
 * SSL time (milliseonds)
 */
@property int ssl;

/**
 * Time to first byte (milliseonds)
 */
@property int ttfb;

@end
