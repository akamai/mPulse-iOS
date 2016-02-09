//
//  MPURLSessionDelegateHelper.m
//  Boomerang
//
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import "MPURLSessionDelegateHelper.h"

@implementation MPURLSessionDelegateHelper

//
// This class implements a few delegate methods for NSURLSession:
//
// NSURLSessionTaskDelegate
// https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionTaskDelegate_protocol/index.html
// Implemented:
//   * URLSession:task:didCompleteWithError:
// Not Implemented:
//   * URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:
//   * URLSession:task:didReceiveChallenge:completionHandler:
//   * URLSession:task:needNewBodyStream:
//   * URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:
//
// NSURLSessionDataDelegate (inherits from NSURLSessionTaskDelegate)
// https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionDataDelegate_protocol/index.html
// Implemented:
//   * URLSession:dataTask:didReceiveResponse:completionHandler:
//   * URLSession:dataTask:didReceiveData:
// Not Implemented:
//   * URLSession:dataTask:didBecomeDownloadTask:
//   * URLSession:dataTask:didBecomeStreamTask:
//   * URLSession:dataTask:willCacheResponse:completionHandler:
//

-(void) URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
  _task = task;
  _error = error;

  _firedDidCompleteWithError = true;
}

-(void) URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
  _task = dataTask;
  
  _response = response;

  _firedDidReceiveResponse = true;

  // let it continue
  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
  _task = dataTask;
  
  _firedDidReceiveData = true;
}
@end
