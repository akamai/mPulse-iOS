//
//  MPURLConnectionNonConformingDelegateHelper.h
//  Boomerang
//
//  Created by Nicholas Jansma on 5/4/16.
//  Copyright © 2016 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPURLConnectionNonConformingDelegateHelper : NSObject

@property (readonly) BOOL finished;
@property (readonly) NSURLResponse *response;
@property (readonly) NSError *error;
@property (readonly) NSMutableData *responseData;
@property (readonly) NSURLConnection *connection;

@end
