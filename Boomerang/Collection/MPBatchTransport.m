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

#define kMaxHttpRetries 5
#define kHttpTimeout 10

#define kHttpOK 200
#define kHttpNoContent 204

#define kRetryInterval 1

@implementation MPBatchTransport

-(void) sendBatch:(NSDictionary*) batchedRecords
{
  // Serialize to Google Protocol Buffer format.
  MPLogDebug(@"Serializing %lu record(s)...", (unsigned long)[batchedRecords count]);
  MPBatch* batch = [MPBatch initWithRecords:batchedRecords];
  NSData* serializedBatch = [batch serialize];
  MPLogDebug(@"Serialized %lu record(s) to %lu byte(s).", (unsigned long)[batchedRecords count], (unsigned long)[serializedBatch length]);
  
  // POST the binary content to the server.
  NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[MPConfig sharedInstance].beaconURL];
  [request setHTTPMethod:@"POST"];
  [request setValue:@"application/x-octet-stream" forHTTPHeaderField:@"Content-Type"];
  [request setHTTPBody:serializedBatch];
  if ([self sendWithRetries:request])
  {
    MPLogInfo(@"Successfully sent %lu record(s) to the server.", (unsigned long)[batchedRecords count]);
  }
  else
  {
    // TODO: handle failures... save the failed batch for how long before we give up on it?  Write to disk?
  }
}

-(BOOL) sendWithRetries:(NSURLRequest*)request
{
  NSData *responseData;
  NSUInteger attempts = 0;

  MPURLConnection* connection = [[MPURLConnection alloc] init];

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
