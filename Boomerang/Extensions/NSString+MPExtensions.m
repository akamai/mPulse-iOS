//
//  NSString+MPExtensions.m
//
//  Created by Matthew Solnit on 3/4/12.
//  Copyright (c) 2012 SOASTA, Inc. All rights reserved.
//

#import "NSString+MPExtensions.h"
#import "JSON.h"
#import "MPLog.h"

@implementation NSString (MPExtensions)

- (NSString *) mp_removeUnicode
{
  NSMutableString* builder = [NSMutableString stringWithCapacity:self.length];
  
  // We will iterate through all code points in the String
  NSRange fullRange = NSMakeRange(0, [self length]);
  [self enumerateSubstringsInRange:fullRange
                        options:NSStringEnumerationByComposedCharacterSequences
                     usingBlock:^(NSString *codePoint, NSRange substringRange,
                                  NSRange enclosingRange, BOOL *stop)
  {
    // If the current code point is a Unicode character, replace it with the correct value.
    [builder appendString:[self mp_getReplacementForUnicodeChar:codePoint]];
  }];
  
  // Case 84549: In the case of unicode 1a, this is a control character (end of file) which isn't caught by
  // which is caught by mp_getReplacementForUnicodeChar.
  return [[NSString stringWithString:builder] stringByReplacingOccurrencesOfString:@"\\u001a" withString:@""];
}

- (NSString*) mp_getReplacementForUnicodeChar:(NSString*) codePoint
{
  if ([codePoint isEqualToString:@"\xe2\x80\xaa"]) //LEFT-TO-RIGHT-EMBEDDING
  {
    return @"";
  }
  if ([codePoint isEqualToString:@"\xe2\x80\xac"]) //POP DIRECTIONAL FORMATTING
  {
    return @"";
  }
  if ([codePoint isEqualToString:@"\x0a"]) //LINE FEED
  {
    return @"\\n";
  }
  return codePoint; // If the codepoint is not a known Unicode char, return as is.
}
@end
