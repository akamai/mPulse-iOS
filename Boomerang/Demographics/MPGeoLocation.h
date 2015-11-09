//
//  MPGeoLocation.h
//  Boomerang
//
//  Created by Albert Hong on 11/12/12.
//  Copyright (c) 2012 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MPGeoLocation : NSObject
{
  CLLocationManager *m_locationManager;
  CLLocation *m_location;
}

+(MPGeoLocation *) sharedInstance;
-(float) getLatitude;
-(float) getLongitude;

@end
