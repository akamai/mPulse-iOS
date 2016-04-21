//
//  MPAFNetworkingTests.m
//  Boomerang
//
//  Created by Mukul Sharma on 12/8/14.
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MPulse.h"
#import "MPSession.h"
#import "MPConfig.h"
#import "MPBeaconCollector.h"
#import "MPInterceptURLConnectionDelegate.h"
#import "MPInterceptURLSessionDelegate.h"
#import "AFJSONRequestOperation.h"
#import "AFImageRequestOperation.h"
#import "AFXMLRequestOperation.h"
#import "AFPropertyListRequestOperation.h"
#import "SDWebImageDownloader.h"
#import "MPBeaconTestBase.h"

@interface MPPodFrameworksNetworkingTests : MPBeaconTestBase
{
}

@end

@implementation MPPodFrameworksNetworkingTests

//
// Constants
//

//
// URLs
//
// A good URL
NSString *const SUCCESS_URL = @"http://boomerang-test.soasta.com:3000/delay?response=abcdefghijklmnopqrstuvwxyz1234567890&delay=3000";

// An Image download URL
NSString *IMAGE_DOWNLOAD_URL = @"http://boomerang-test.soasta.com:3000/assets/img.jpg";

//
// Timeouts
//

// Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
static int const BEACON_ADD_WAIT = 5;

// NSURL Success Code
static short const NSURLSUCCESS = 0;

#pragma mark -
#pragma mark Response XCTests

-(void) setUp
{
  [super setUp];

  // Intialization of BoomerangURLSessionDelegate
  [MPInterceptURLSessionDelegate sharedInstance];

  // Intialization of BoomerangURLConnectionDelegate
  [MPInterceptURLConnectionDelegate sharedInstance];
}

/*
 * Checks if the records collected by MPBeaconCollector.have the desired number of beacons, network request duration,
 * url and network error code
 * called after each NSURLConnection methods
 */
-(void) responseBeaconTest:(NSString *)urlString
               minDuration:(long)minDuration
          networkErrorCode:(short)networkErrorCode
{
  // Sleep - wait for beacon to be added
  [NSThread sleepForTimeInterval:BEACON_ADD_WAIT];

  NSArray *beacons = [[MPBeaconCollector sharedInstance] getBeacons];
  XCTAssertEqual([beacons count], 1, "Dictionary size incorrect");

  MPApiNetworkRequestBeacon *beacon = (MPApiNetworkRequestBeacon *)[beacons objectAtIndex:0];

  XCTAssertTrue([beacon duration] >= minDuration, "network request duration error");
  XCTAssertEqualObjects([beacon url], urlString, @" Wrong URL string.");
  XCTAssertTrue([beacon networkErrorCode] == networkErrorCode, "Wrong network error code");
}

-(void) testAFJSONRequestOperationInterception
{
  // This URL does not return JSON data, but it doesn't matter.
  // We are simply testing our ability to intercept requests performed using AFJSONRequestOperation class.
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:SUCCESS_URL]];

  AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                              {
                                                MPLogInfo(@"Request successful.");
                                              }
                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                              {
                                                MPLogInfo(@"Request failed.");
                                              }];

  [operation start];

  [operation waitUntilFinished];

  // Test for success
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testAFImageRequestOperation
{
  // This URL does not return an Image, but it doesn't matter.
  // We are simply testing our ability to intercept requests performed using AFImageRequestOperation class.
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:SUCCESS_URL]];

  AFImageRequestOperation *operation = [AFImageRequestOperation imageRequestOperationWithRequest:request
                                                                                         success:^(UIImage *image)
                                                                                          {
                                                                                            MPLogInfo(@"Request successful.");
                                                                                          }];

  [operation start];

  [operation waitUntilFinished];

  // Test for success
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testAFPropertyListRequestOperation
{
  // This URL does not return a Property List, but it doesn't matter.
  // We are simply testing our ability to intercept requests performed using AFImageRequestOperation class.
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:SUCCESS_URL]];

  AFPropertyListRequestOperation *operation = [AFPropertyListRequestOperation propertyListRequestOperationWithRequest:request
                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, id propertyList)
                                                      {
                                                        MPLogInfo(@"Request successful.");
                                                      }
                                               failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id propertyList)
                                                      {
                                                        MPLogInfo(@"Request failed.");
                                                      }];

  [operation start];

  [operation waitUntilFinished];

  // Test for success
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

-(void) testAFXMLRequestOperation
{
  // This URL does not return XML data, but it doesn't matter.
  // We are simply testing our ability to intercept requests performed using AFXMLRequestOperation class.
  NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:SUCCESS_URL]];

  AFXMLRequestOperation *operation = [AFXMLRequestOperation XMLParserRequestOperationWithRequest:request
                                      success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser)
                                               {
                                                 MPLogInfo(@"Request successful.");
                                               }
                                      failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser)
                                               {
                                                 MPLogInfo(@"Request failed.");
                                               }];

  [operation start];

  [operation waitUntilFinished];

  // Test for success
  [self responseBeaconTest:SUCCESS_URL minDuration:3000 networkErrorCode:NSURLSUCCESS];
}

// Downloads a sample image using SDWebImageDownloader and verifies that we add a beacon for the request.
-(void) testSDWebImageDownloaderInterception
{
  __block BOOL downloadComplete = NO;
  [SDWebImageDownloader.sharedDownloader downloadImageWithURL:[NSURL URLWithString:IMAGE_DOWNLOAD_URL]
                                                      options:0
                                                     progress:nil
                                                    completed:^(UIImage *image,
                                                                NSData * data,
                                                                NSError * error,
                                                                BOOL finished)
   {
     // only the image is not null and we're finished
     if (image && finished)
     {
       // Image download complete
       downloadComplete = YES;
     }
   }];

  int secondsSlept = 0;

  while (!downloadComplete)
  {
    // Timeout if we've waited for 30 seconds.
    if (secondsSlept >= 30)
    {
      break;
    }

    sleep(2); // Sleep until download is complete
    secondsSlept += 2;
  }

  // Test for success
  [self responseBeaconTest:IMAGE_DOWNLOAD_URL
               minDuration:0
          networkErrorCode:NSURLSUCCESS];
}

@end
