//
//  MPGeoLocation.m
//  Boomerang
//
//  Created by Albert Hong on 11/12/12.
//  Copyright (c) 2012-2013 SOASTA. All rights reserved.
//

#import "MPGeoLocation.h"

@implementation MPGeoLocation

static MPGeoLocation *geoLocationSingleton = NULL;

+(MPGeoLocation *) sharedInstance
{
  @synchronized(self)
  {
    if (geoLocationSingleton == NULL)
    {
      geoLocationSingleton = [[MPGeoLocation alloc] init];
      [geoLocationSingleton setupLocationManager];
    }
  }
  
  return geoLocationSingleton;
}

-(float) getLatitude
{
  if (m_locationManager == nil)
  {
    return 0;
  }
  
  // Get the most recent location information from Location Manager
  m_location = m_locationManager.location;
  
  if (m_location != nil)
  {
    return m_location.coordinate.latitude;
  }
  
  return 0;
}

-(float) getLongitude
{
  if (m_locationManager == nil)
  {
    return 0;
  }
  
  // Get the most recent location information from Location Manager
  m_location = m_locationManager.location;
  
  if (m_location != nil)
  {
    return m_location.coordinate.longitude;
  }
  
  return 0;
}

-(void) setupLocationManager
{
  // Create the location manager if this object does not already have one.
  if (nil == m_locationManager && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
  {
    m_locationManager = [[CLLocationManager alloc] init];
  }
}

@end
