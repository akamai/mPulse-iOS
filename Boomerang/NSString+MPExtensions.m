//
//  NSString+MPExtensions.m
//  BoomerangDriver
//
//  Created by Matthew Solnit on 3/4/12.
//  Copyright (c) 2014 SOASTA, Inc. All rights reserved.
//

#import "NSString+MPExtensions.h"

@implementation NSString (TTExtensions)

- (NSNumber *) mp_numberValue:(NSString *)dataType
{
  NSString *content = [NSString stringWithString:self];
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  
  // Bug 80814: Strip out non-numeric characters ([^0-9\.\-]) from custom metrics in mobile apps
  NSString *value = [self replace:@"[^0-9\.\-]" fromContent:content];
  NSNumber *valueNumber = [numberFormatter numberFromString:value];
  
  // If dataType is "Currency"
  if (dataType != nil && [@"Currency" isEqualToString:dataType])
  {
    if (valueNumber)
    {
      // If value contains a decimal point
      if ([value rangeOfString:@"."].location != NSNotFound)
      {
        NSArray *strArraySplitAtDot = [value componentsSeparatedByString:@"."];
        if ([strArraySplitAtDot count] == 2)
        {
          NSString *decimalFraction = [strArraySplitAtDot objectAtIndex:1];
          int multiplicationFactor = pow(10, [decimalFraction length]);
          int numberBeforeDecimal = valueNumber.integerValue * multiplicationFactor;
          int numberAfterDecimal = [decimalFraction integerValue];
          
          valueNumber = [NSNumber numberWithInteger:(numberBeforeDecimal + numberAfterDecimal)];
        }
      }
      else
      {
        valueNumber = [NSNumber numberWithInt:[valueNumber integerValue] * 100];
      }
    }
  }
  
  return valueNumber;
}

// Taken from http://stackoverflow.com/a/5507550/6198
- (NSString *) mp_stringByDecodingURLFormat
{
  NSString *result = [(NSString *)self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
  result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  return result;
}

+ (NSString*) mp_stringWithByteArray:(Byte*)bytes andLength:(int)length
{
  NSMutableString* s = [[NSMutableString alloc] init];
  
  [s appendString:@"["];
  
  for (int i = 0; i < length; i++)
  {
    if (i > 0)
      [s appendString:@", "];
    
    [s appendFormat:@"%d", bytes[i]];
  }
  
  [s appendString:@"]"];
  
  return s;
}

+ (NSString*) mp_stringWithIntArray:(int*)ints andLength:(int)length
{
  NSMutableString* s = [[NSMutableString alloc] init];
  
  [s appendString:@"["];
  
  for (int i = 0; i < length; i++)
  {
    if (i > 0)
      [s appendString:@", "];
    
    [s appendFormat:@"%d", ints[i]];
  }
  
  [s appendString:@"]"];
  
  return s;
}

// Perform a replace for matching regex in the content and return the result if found.
// Bug 80814: Strip out non-numeric characters ([^0-9\.\-]) from custom metrics in mobile apps
-(NSString*) replace:(NSString*) regexString fromContent:(NSString*) content
{
  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:&error];
  
  NSString *modifiedString = [regex stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, [content length]) withTemplate:@""];
  
  if (modifiedString)
  {
    return modifiedString;
  }
  return nil;
}

@end
