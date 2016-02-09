//
//  MPURLConnectionDelegateHelper.h
//  Boomerang
//
//  Created by Shilpi Nayak on 7/8/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPURLConnectionDelegateHelper : NSObject<NSURLConnectionDataDelegate>

@property (readonly) BOOL finished;
@property (readonly) NSURLResponse *response;
@property (readonly) NSError *error;
@property (readonly) NSMutableData *responseData;
@property (readonly) NSURLConnection *connection;

@end
