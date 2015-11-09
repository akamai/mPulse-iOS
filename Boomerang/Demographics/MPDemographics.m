//
//  MPDemographics.m
//  Boomerang
//
//  Created by Mukul Sharma on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPDemographics.h"
#import "MPReachability.h"
#import "MPGeoLocation.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <sys/sysctl.h>
#import <UIKit/UIKit.h>

@implementation MPDemographics

static MPDemographics *demographicsSingleton = NULL;
static NSString* TABLET = @"Tablet";
static NSString* MOBILE = @"Mobile";

+(MPDemographics *) sharedInstance
{
  @synchronized(self)
  {
    if (demographicsSingleton == NULL)
    {
      demographicsSingleton = [[MPDemographics alloc] init];
    }
  }
  
  return demographicsSingleton;
}

/*
 * Returns Application version.
 */
- (NSString*) getApplicationVersion
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

/*
 * Returns Device model (iPad4,1) - We send the actual model number which will be translated to readable format on server side.
 */
- (NSString*) getDeviceModel
{
  return [self deviceStringParameter:@"hw.machine"];
}

/*
 * Returns Device type (Tablet/Mobile)
 */
- (NSString*) getDeviceType
{
  // Check if device is an iPad
  if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
  {
    return TABLET;
  }
  else
  {
    return MOBILE;
  }
}

-(NSString*) deviceStringParameter:(NSString*)param
{
  size_t size;
  
  // Extract ASCII char pointer.
  const char *name = [param cStringUsingEncoding:NSASCIIStringEncoding];
  
  // Set 'oldp' parameter to NULL to get the size of the data
  // returned so we can allocate appropriate amount of space
  sysctlbyname(name, NULL, &size, NULL, 0);
  
  // Allocate the space to store name
  char *buffer = malloc(size);
  
  // Fetch the parameter requested
  sysctlbyname(name, buffer, &size, NULL, 0);
  
  // Place name into a string
  NSString *value = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
  
  // Done with this
  free(buffer);
  
  return value;
}

/*
 * Returns OS Version (eg. iOS 7.0.4)
 */
- (NSString*) getOSVersion
{
  UIDevice *currentDevice = [UIDevice currentDevice];
  NSString* osVersion = [NSString stringWithFormat:@"iOS %@", [[currentDevice systemVersion] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
  return osVersion;
}

/*
 * Returns Carrier Name (eg. AT&T)
 */
- (NSString*) getCarrierName
{
  CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
  CTCarrier *carrier = [netinfo subscriberCellularProvider];
  if (carrier != nil)
  {
    return [carrier carrierName];
  }
  
  return nil;
}

/*
 * Returns Connection type (eg. WiFi, 4G, etc.)
 */
- (NSString *) getConnectionType
{
  NSString *connectionType = @"unknown";
  
  MPReachability *reachability = [MPReachability reachabilityForInternetConnection];
  [reachability startNotifier];
  
  NetworkStatus status = [reachability currentReachabilityStatus];
  switch (status)
  {
    case ReachableViaWiFi:
    {
      connectionType = @"WiFi";
      break;
    }
    case ReachableViaWWAN:
    {
      CTTelephonyNetworkInfo *networkInfo = [CTTelephonyNetworkInfo new];
      CTCarrier *carrier = networkInfo.subscriberCellularProvider;
      if (carrier != nil)
      {
#ifdef __IPHONE_7_0
        if ([networkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE])
        {
          connectionType = @"LTE";
        }
        else if ([networkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyHSUPA] ||
                 [networkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA])
        {
          connectionType = @"4G";
        }
        else if ([networkInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge])
        {
          connectionType = @"3G";
        }
        else
        {
          // default to 4G.
          // See http://www.pcmag.com/article2/0,2817,2399984,00.asp
          connectionType = @"4G";
        }
#endif
      }
      break;
    }
    default:
      MPLogDebug(@"Unexpected reachability status : %i", status);
  }
  
  [reachability stopNotifier];
  
  return connectionType;
}

/*
 * Returns Latitude.
 */
- (float) getLatitude
{
  MPGeoLocation *geoLocation = [MPGeoLocation sharedInstance];
  return [geoLocation getLatitude];
}

/*
 * Returns Longitude.
 */
- (float) getLongitude
{
  MPGeoLocation *geoLocation = [MPGeoLocation sharedInstance];
  return [geoLocation getLongitude];
}

@end
