//
//  MPAppLaunchBeacon.m
//  Boomerang
//
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import "MPAppLaunchBeacon.h"
#import "MPBeaconCollector.h"
#import "MPUtilities.h"
#import "MPBeacon.h"
#import "ClientBeaconBatch.pb.h"

@implementation MPAppLaunchBeacon

/**
 * Initialize the launch beacon
 */
-(id) init
{
  self = [super init];

  if (self)
  {
    // Clear Page Dimensions as an install isn't associated with a page
    [self clearPageDimensions];
    
    // Find out if we've already sent YES for first install of the app
    NSString *boomerangDataFilePath = [MPUtilities getBoomerangDataFile];

    if (boomerangDataFilePath)
    {
      NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:boomerangDataFilePath];
      BOOL firstInstallBeaconSent = [[plistData valueForKey:BOOMERANG_INSTALL_BEACON_SENT] boolValue];
      
      if (!firstInstallBeaconSent)
      {
        _isFirstInstall = true;
       
        // Save the file
        [plistData setValue:@"YES" forKey:BOOMERANG_INSTALL_BEACON_SENT];
        [plistData writeToFile:boomerangDataFilePath atomically:YES];
      }
    }
  }
  
  return self;
}

/**
 * Gets the beacon type
 */
-(MPBeaconTypeEnum) getBeaconType
{
  return APP_LAUNCH;
}

/**
 * Sends the beacon
 */
+(void) sendBeacon
{
  MPAppLaunchBeacon *beacon = [[MPAppLaunchBeacon alloc] init];

  [[MPBeaconCollector sharedInstance] addBeacon:beacon];
}

/**
 * Serializes the beacon for the Protobuf record
 */
-(void) serialize:(void*)recordPtr
{
  //
  //  message AppLaunchData {
  //    optional bool is_first_install = 1;
  //  }
  //

  [super serialize:recordPtr];
  
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord* record
    = (::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord*)recordPtr;
  
  //
  // App Launch data
  //
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_AppLaunchData* data
    = record->mutable_app_launch_data();
  
  data->set_is_first_install(_isFirstInstall);
}

@end
