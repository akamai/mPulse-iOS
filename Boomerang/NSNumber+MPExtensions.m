//
//  NSNumber+MPExtensions.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/30/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@implementation NSNumber (MPExtensions)

-(NSNumber*) mp_increment
{
  return [self mp_incrementBy:1];
}

-(NSNumber*) mp_incrementBy:(int)value
{
  // NSNumber is immutable.
  // Rather than changing the value, we need to return a new one.
  return @(self.intValue + value);
}

@end
