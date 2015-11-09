//
//  MPNumberDictionary.h
//  Boomerang
//
//  Created by Matthew Solnit on 5/12/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPNumberDictionary : NSObject

@property (readonly) NSUInteger count;

-(void) incrementBucket:(NSInteger)index value:(int)value;

-(NSArray*) asNSArray;

-(int*) asCArray:(int)length;

@end
