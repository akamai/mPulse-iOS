//
//  MPNetworkErrorGenerator.m
//  Boomerang
//
//  Created by Shilpi Nayak on 7/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPNetworkErrorBeaconGenerator.h"
#import "MPConfig.h"

@implementation MPNetworkErrorBeaconGenerator

// Singleton MPGenerateNetworkError object
static MPNetworkErrorBeaconGenerator *sharedObject = nil;

static int ERROR_REPLAY_INTERVAL = 30; // In seconds

// URLs that generate different network error
NSString * const MPPAGENOTFOUND_URL = @"http://67.111.67.24:8080/concertoXYZ";
NSString * const MPCONNECTION_REFUSED_URL = @"http://67.111.67.24:1200/concerto";
NSString * const MPUNKNOWN_HOST_URL = @"http://bearsbearsbears123.com";
NSString * const MPCONNECTION_TIMEOUT_URL = @"http://1.2.3.4:8080/concerto";

NSArray *urlList;

// Start the Network Error Beacon Generator
+ (void) startGenerator
{
  static dispatch_once_t _singletonPredicate;
  dispatch_once(&_singletonPredicate, ^{
    sharedObject = [[super alloc] init];
    
    urlList  = @[MPPAGENOTFOUND_URL,
                 MPUNKNOWN_HOST_URL,
                 MPCONNECTION_TIMEOUT_URL,
                 MPCONNECTION_REFUSED_URL];

    // Dispatch a task to generate Network Errors
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^{[self generateNetworkErrorBeacons];});
  });
}

/**
 * Sends network error to the server by randomizing error count
 * This runs at every 30 seconds interval
 */
+ (void) generateNetworkErrorBeacons
{
  // Because this Generator thread is started by a Notification receiver, we cannot
  // read MPConfig ivars at the time of kickoff.
  // Thus, we must check for the generateNetworkErrors flag inside the dispatch_async
  // we spawn for this Generator.
  // If not true, we must return and kill the thread.
  if (![[MPConfig sharedInstance] generateNetworkErrors])
  {
    return;
  }
  
  // Get random index in urlList
  NSInteger requestURL1 = arc4random_uniform(urlList.count);
  NSInteger requestURL2 = arc4random_uniform(urlList.count);
  
  // Send synchronous request using the urls at the index
  [self sendSynchRequest:[urlList objectAtIndex:requestURL1]];
  [self sendSynchRequest:[urlList objectAtIndex:requestURL2]];

  // Run again after 30 seconds
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, ERROR_REPLAY_INTERVAL * NSEC_PER_SEC),
                 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^{
                   [self generateNetworkErrorBeacons];
                 });
}

// Send synchronous request
+ (void) sendSynchRequest: (NSString*) urlString
{
  NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];

  NSURLResponse *response = nil;
  NSError *error = nil;
  [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

  // Wait for beacon to be added after connection - ensures MPBeaconCollector has records.
  [NSThread sleepForTimeInterval:5];
}

@end
