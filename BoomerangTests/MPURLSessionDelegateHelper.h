//
//  MPURLSessionDelegateHelper.h
//  Boomerang
//
//  Created by Nicholas Jansma on 2/8/16.
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPURLSessionDelegateHelper : NSObject<NSURLSessionDataDelegate>

@property (readonly) BOOL firedDidCompleteWithError;
@property (readonly) BOOL firedDidReceiveResponse;
@property (readonly) BOOL firedDidReceiveData;

@property (readonly) int64_t totalBytesSent;
@property (readonly) int64_t totalBytesExpectedToSend;

@property (readonly) NSURLSession *session;
@property (readonly) NSURLSessionTask *task;

@property (readonly) NSURLResponse *response;
@property (readonly) NSMutableData *responseData;

@property (readonly) NSError *error;

@end
