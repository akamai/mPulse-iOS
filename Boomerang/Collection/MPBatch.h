//
//  MPBatch.h
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPBatch : NSObject

+(id) initWithRecords:(NSDictionary*)records;

-(NSData*) serialize;

/**
 * This method is public, and static, solely for unit-testing purposes.
 */
+ (Byte*) histogramIntArrayToBinary:(int*)values withLength:(int)histogramLength andFormat:(Byte)format outputLength:(int*)outputLength;

/**
 * This method is solely used for unit-testing purposes.
 */
+ (int*) binaryHistogramToIntArray:(Byte*)data withLength:(int)length;

@end
