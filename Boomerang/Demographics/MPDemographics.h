//
//  MPDemographics.h
//  Boomerang
//
//  Created by Mukul Sharma on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPDemographics : NSObject

/*
 * Returns MPDemographic Singleton instance.
 */
+(MPDemographics *) sharedInstance;

/*
 * Returns Application version.
 */
- (NSString*) getApplicationVersion;

/*
 * Returns Device model (iPad4,1) - We send the actual model number which will be translated to readable format on server side.
 */
- (NSString*) getDeviceModel;

/*
 * Returns Device type (Tablet/Mobile)
 */
- (NSString*) getDeviceType;

/*
 * Returns OS Version (eg. 7.0.4)
 */
- (NSString*) getOSVersion;

/*
 * Returns Carrier Name (eg. AT&T)
 */
- (NSString*) getCarrierName;

/*
 * Returns Connection type (eg. WiFi, 4G, etc.)
 */
- (NSString *) getConnectionType;

/*
 * Returns Latitude.
 */
- (float) getLatitude;

/*
 * Returns Longitude.
 */
- (float) getLongitude;

@end
