//
//  MPRemoveUnicodeTest.m
//  Boomerang
//
//  Created by Mukul Sharma on 7/8/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+MPExtensions.h"

@interface MPRemoveUnicodeCharsTest : XCTestCase

@end

@implementation MPRemoveUnicodeCharsTest

-(void) testRemoving_LEFT_TO_RIGHT_EMBEDDING_UnicodeChar
{
  // Create a mutable string with capacity of 20. We will not insert substrings larger than 20 code points.
  NSMutableString *testStringWithUnicode = [NSMutableString stringWithCapacity:20];
  [testStringWithUnicode appendString:@"Test"];
  
  // Append the Unicode char which will be removed as part of testing
  [testStringWithUnicode appendString:@"\u202A"];
  
  [testStringWithUnicode appendString:@"String"];

  NSString *testStringWithOutUnicode = @"TestString";
  
  XCTAssertTrue([[testStringWithUnicode mp_removeUnicode] isEqualToString:testStringWithOutUnicode], @"Unicode character was not removed.");
}

-(void) testRemoving_POP_DIRECTIONAL_FORMATTING_UnicodeChar
{
  // Create a mutable string with capacity of 20. We will not insert substrings larger than 20 code points.
  NSMutableString *testStringWithUnicode = [NSMutableString stringWithCapacity:20];
  [testStringWithUnicode appendString:@"Test"];
  
  // Append the Unicode char which will be removed as part of testing
  [testStringWithUnicode appendString:@"\u202C"];
  
  [testStringWithUnicode appendString:@"String"];
  
  NSString *testStringWithOutUnicode = @"TestString";
  
  XCTAssertTrue([[testStringWithUnicode mp_removeUnicode] isEqualToString:testStringWithOutUnicode], @"Unicode character was not removed.");
}

-(void) testRemoving_LINE_FEED_UnicodeChar
{
  // Create a mutable string with capacity of 20. We will not insert substrings larger than 20 code points.
  NSMutableString *testStringWithUnicode = [NSMutableString stringWithCapacity:20];
  [testStringWithUnicode appendString:@"Test"];
  
  // Append the Unicode char which will be removed as part of testing
  [testStringWithUnicode appendString:@"\x0a"];
  
  [testStringWithUnicode appendString:@"String"];
  
  NSString *testStringWithOutUnicode = @"Test\\nString";

  XCTAssertTrue([[testStringWithUnicode mp_removeUnicode] isEqualToString:testStringWithOutUnicode], @"Unicode character was not removed.");
}

@end
