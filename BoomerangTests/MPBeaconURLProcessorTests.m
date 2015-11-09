//
//  MPBeaconURLProcessorTests.m
//  Boomerang
//
//  Created by Matthew Solnit on 5/14/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPBeaconURLProcessor.h"

@interface MPBeaconURLProcessorTests : XCTestCase

@end

@implementation MPBeaconURLProcessorTests

- (void)testURLPatterns
{
  NSArray* urlPatterns = [NSArray arrayWithObjects:
                          @"http://www.facebook.com/*/abc/def/?abc=*",
                          @"http://www.facebook.com/*/abc/*/",
                          @"http://www.soasta.com/abc/*/",
                          @"https://www.facebook.com/def/*/hello?abc=*&def=*",
                          nil];

  // Path is ignored since it does not match any patterns
  [self testURL:@"http://www.facebook.com/foo/bar/baz" withPatterns:urlPatterns andExpectedPath:@"/"];

  // Path is ignored since it does not match any patterns
  [self testURL:@"http://www.facebook.com/foo/bar/baz" withPatterns:urlPatterns andExpectedPath:@"/"];

  // foo is replaced by *, QS is ignored
  [self testURL:@"https://www.facebook.com/foo/abc/ggg/?hello=world" withPatterns:urlPatterns andExpectedPath:@"/*/abc/*/"];

  // foo is replaced by *, QS is included
  [self testURL:@"https://www.facebook.com/foo/abc/def/?abc=world" withPatterns:urlPatterns andExpectedPath:@"/*/abc/def/?abc=world"];

  // def is replaced by *
  [self testURL:@"http://www.soasta.com/abc/def/" withPatterns:urlPatterns andExpectedPath:@"/abc/*/"];

  // Only abc is passed through
  [self testURL:@"http://www.facebook.com/def/ghi/hello?a=b&c=d&abc=ghi" withPatterns:urlPatterns andExpectedPath:@"/def/*/hello?abc=ghi"];

  // Only abc is passed through, values are compared after url decoding
  [self testURL:@"http://www.facebook.com/d%65f/ghi/hello?a=b&c=d&a%62c=ghi" withPatterns:urlPatterns andExpectedPath:@"/def/*/hello?abc=ghi"];

  // Only abc and def QS params are passed through.  abc is passed multiple times in the order it appears in the URL
  [self testURL:@"http://www.facebook.com/def/ghi/hello?def=aaa&abc=lll&a=b&c=d&abc=ghi" withPatterns:urlPatterns andExpectedPath:@"/def/*/hello?abc=lll&abc=ghi&def=aaa"];

  // Query String ignored because it has more than 30 components
  [self testURL:@"http://www.facebook.com/def/ghi/hello?a=1&b=2&c=3&d=4&e=5&f=6&g=7&h=8&i=9&j=10&a=1&b=2&c=3&d=4&e=5&f=6&g=7&h=8&i=9&j=10&a=1&b=2&c=3&d=4&e=5&f=6&g=7&h=8&i=9&j=10&abc=hello&def=world" withPatterns:urlPatterns andExpectedPath:@"/def/*/hello"];
}

-(void) testURL:(NSString*)url withPatterns:(NSArray*)patterns andExpectedPath:(NSString*)expectedPath
{
  NSString* path = [MPBeaconURLProcessor extractURLPath:[NSURL URLWithString:url] urlPatterns:patterns];
  XCTAssertEqualObjects(expectedPath, path, @"Incorrect URL path.");
}

@end
