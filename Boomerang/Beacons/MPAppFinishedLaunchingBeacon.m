//
//  MPAppFinishedLaunchingBeacon.m
//  Boomerang
//
//  Created by Tana Jackson on 4/15/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPAppFinishedLaunchingBeacon.h"
#import "MPBeaconCollector.h"
#import "MPUtilities.h"
#import "MPBeacon.h"

@implementation MPAppFinishedLaunchingBeacon

-(id) init
{
  self = [super init];
  if (self)
  {
    // We overwrite the PageGroup value for AppIsInactiveBeacon as it is a standalone beacon
    // and cannot belong to any page group in the app.
    self.pageGroup = @"";
    
    // Find out if we've already sent YES for first install of the app.
    NSString* boomerangDataFilePath = [MPUtilities getBoomerangDataFile];
    if (boomerangDataFilePath)
    {
      NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:boomerangDataFilePath];
      BOOL firstInstallBeaconSent = [[plistData valueForKey:BOOMERANG_INSTALL_BEACON_SENT] boolValue];
      if (!firstInstallBeaconSent)
      {
        // This is the first time the app has been launched since installation.
        MPLogDebug(@"Detected first launch of this app.");
        self.isFirstInstall = YES;
       
        // Save the file
        [plistData setValue:@"YES" forKey:BOOMERANG_INSTALL_BEACON_SENT];
        [plistData writeToFile:boomerangDataFilePath atomically:YES];
      }
    }
  }
  
  return self;
}

+(void) sendBeacon
{
  MPAppFinishedLaunchingBeacon *beacon = [[MPAppFinishedLaunchingBeacon alloc] init];
  [[MPBeaconCollector sharedInstance] addBeacon:beacon];
}

@end
