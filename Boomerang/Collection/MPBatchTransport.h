//
//  MPBatchTransport.h
//  Boomerang
//
//  Created by Matthew Solnit on 4/29/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPBatchTransport : NSObject

-(void) sendBatch:(NSDictionary*) batchedRecords;

@end
