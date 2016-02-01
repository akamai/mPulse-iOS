//
//  MPBatchTransport.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPBatchTransport.h"
#import "MPBatch.h"
#import "MPConfig.h"
#import "MPURLConnection.h"
#import "NSData+Gzip.h"

#define kMaxHttpRetries 5
#define kHttpTimeout 10

#define kHttpOK 200
#define kHttpNoContent 204

#define kRetryInterval 1

@implementation MPBatchTransport

/**
 * Sends a batch of beacons
 * @param batchedRecords Beacons
 */
-(void) sendBatch:(NSArray *)beacons
{
  // Serialize to Google Protocol Buffer format.
  MPLogDebug(@"Serializing %lu beacons(s)...", (unsigned long)[beacons count]);
  MPBatch *batch = [MPBatch initWithBeacons:beacons];
  
  if (!batch)
  {
    MPLogError(@"Batch could not be created");
    return;
  }

  NSData *serializedBatch = [batch serialize];
  
  if (!serializedBatch)
  {
    MPLogError(@"Batch could not be serialized");
    return;
  }
  
  // gzip data
  NSData *serializedBatchGzip = [serializedBatch gzipDeflate];
  
  if (!serializedBatchGzip)
  {
    MPLogError(@"Batch could not be gzipped");
    return;
  }
  
  MPLogDebug(@"Serialized %lu beacons(s) to %lu byte(s) (%lu byte(s) gzipped).",
             (unsigned long)[beacons count],
             (unsigned long)[serializedBatch length],
             (unsigned long)[serializedBatchGzip length]);
  
  // POST the binary content to the server.
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[MPConfig sharedInstance].beaconURL];
  [request setHTTPMethod:@"POST"];
  
  // HTTP header fields
  [request setValue:@"application/x-octet-stream" forHTTPHeaderField:@"Content-Type"];
  [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
  
  [request setHTTPBody:serializedBatchGzip];

  if ([self sendWithRetries:request])
  {
    MPLogInfo(@"Successfully sent %lu beacon(s) to the server.", (unsigned long)[beacons count]);
  }
  else
  {
    // TODO: handle failures... save the failed batch for how long before we give up on it?  Write to disk?
  }
}

/**
 * Sends the request, with retries
 */
-(BOOL) sendWithRetries:(NSURLRequest *)request
{
  NSData *responseData;
  NSUInteger attempts = 0;

  MPURLConnection *connection = [[MPURLConnection alloc] init];

  while (attempts++ < kMaxHttpRetries)
  {
    NSHTTPURLResponse *httpResponse;
    NSError *error = nil;
    
    // If this is a re-try attempt, then delay first.
    if (attempts > 1)
    {
      [NSThread sleepForTimeInterval:kRetryInterval];
    }
    
    // Send the HTTP request.
    responseData = [connection sendSynchronousRequest:request response:&httpResponse error:&error timeout:kHttpTimeout];
    
    // Did the request succeed?
    if (error != nil)
    {
      // The request failed.
      
      // Log it and then let the loop continue.
      NSLog(@"HTTP request failed; re-trying. %@", error);
    }
    else
    {
      NSInteger statusCode = [httpResponse statusCode];
      
      if (statusCode == kHttpOK || statusCode == kHttpNoContent)
      {
        // Success!
        return YES;
      }
      else
      {
        // Unexpected status code.
        
        // Log it and let the loop continue.
        NSLog(@"Unexpected status code %ld; re-trying.", (long)[httpResponse statusCode]);
      }
    }
  }

  // If we reach this point, then we ran out of re-tries.
  return NO;
}

@end
