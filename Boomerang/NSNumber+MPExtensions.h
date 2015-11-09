//
//  NSNumber+MPExtensions.h
//  Boomerang
//
//  Created by Matthew Solnit on 4/30/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (MPExtensions)

-(NSNumber*) mp_increment;
-(NSNumber*) mp_incrementBy:(int)value;

@end
