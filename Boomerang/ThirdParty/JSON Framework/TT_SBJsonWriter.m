/*
 Copyright (C) 2009 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <CoreImage/CIVector.h>
#import "TT_SBJsonWriter.h"
#import <CoreGraphics/CGGeometry.h>
#import <CoreImage/CIVector.h>

@interface TT_SBJsonWriter ()

- (BOOL)appendValue:(id)fragment into:(NSMutableString*)json;
- (BOOL)appendArray:(NSArray*)fragment into:(NSMutableString*)json;
- (BOOL)appendDictionary:(NSDictionary*)fragment into:(NSMutableString*)json;
- (BOOL)appendString:(NSString*)fragment into:(NSMutableString*)json;
- (BOOL)appendPoint:(CGPoint)p into:(NSMutableString*)json;

- (NSString*)indent;

@end

@implementation TT_SBJsonWriter

@synthesize sortKeys;
@synthesize humanReadable;

/**
 @deprecated This exists in order to provide fragment support in older APIs in one more version.
 It should be removed in the next major version.
 */
- (NSString*)stringWithFragment:(id)value {
    [self clearErrorTrace];
    depth = 0;
    NSMutableString *json = [NSMutableString stringWithCapacity:128];
    
    if ([self appendValue:value into:json])
        return json;
    
    return nil;
}


- (NSString*)stringWithObject:(id)value {
    
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        return [self stringWithFragment:value];
    }

    [self clearErrorTrace];
    [self addErrorWithCode:EFRAGMENT description:@"Not valid type for JSON"];
    return nil;
}


- (NSString*)indent {
    return [@"\n" stringByPaddingToLength:1 + 2 * depth withString:@" " startingAtIndex:0];
}

- (BOOL)appendValue:(id)fragment into:(NSMutableString*)json {
    if ([fragment isKindOfClass:[NSDictionary class]]) {
        if (![self appendDictionary:fragment into:json])
            return NO;
        
    } else if ([fragment isKindOfClass:[NSArray class]]) {
        if (![self appendArray:fragment into:json])
            return NO;
        
    } else if ([fragment isKindOfClass:[NSString class]]) {
        if (![self appendString:fragment into:json])
            return NO;
        
    } else if ([fragment isKindOfClass:[NSNumber class]]) {
        if ('c' == *[fragment objCType])
            [json appendString:[fragment boolValue] ? @"true" : @"false"];
        else
            [json appendString:[fragment stringValue]];
        
    } else if ([fragment isKindOfClass:[NSNull class]]) {
        [json appendString:@"null"];
    } else if ([fragment respondsToSelector:@selector(proxyForJson)]) {
        [self appendValue:[fragment proxyForJson] into:json];
        
    } else if ([fragment isKindOfClass:[NSValue class]]) {
      NSValue *value = fragment;
      CGPoint p = [value CGPointValue];
      if (![self appendPoint:p into:json])
        return NO;
      
    } else {
        [self addErrorWithCode:EUNSUPPORTED description:[NSString stringWithFormat:@"JSON serialisation not supported for %@", [fragment class]]];
        return NO;
    }
    return YES;
}

- (BOOL)appendPoint:(CGPoint)p into:(NSMutableString*)json {
  
  [json appendFormat:@"[%f,%f]", p.x, p.y];
  
  return YES;
}

- (BOOL)appendArray:(NSArray*)fragment into:(NSMutableString*)json {
    if (maxDepth && ++depth > maxDepth) {
        [self addErrorWithCode:EDEPTH description: @"Nested too deep"];
        return NO;
    }
    [json appendString:@"["];
    
    BOOL addComma = NO;    
    for (id value in fragment) {
        if (addComma)
            [json appendString:@","];
        else
            addComma = YES;
        
        if ([self humanReadable])
            [json appendString:[self indent]];
        
        if (![self appendValue:value into:json]) {
            return NO;
        }
    }
    
    depth--;
    if ([self humanReadable] && [fragment count])
        [json appendString:[self indent]];
    [json appendString:@"]"];
    return YES;
}

- (BOOL)appendDictionary:(NSDictionary*)fragment into:(NSMutableString*)json {
    if (maxDepth && ++depth > maxDepth) {
        [self addErrorWithCode:EDEPTH description: @"Nested too deep"];
        return NO;
    }
    [json appendString:@"{"];
    
    NSString *colon = [self humanReadable] ? @" : " : @":";
    BOOL addComma = NO;
    NSArray *keys = [fragment allKeys];
    if (self.sortKeys)
        keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    
    for (id value in keys) {
        if (addComma)
            [json appendString:@","];
        else
            addComma = YES;
        
        if ([self humanReadable])
            [json appendString:[self indent]];
        
        if (![value isKindOfClass:[NSString class]]) {
            [self addErrorWithCode:EUNSUPPORTED description: @"JSON object key must be string"];
            return NO;
        }
        
        if (![self appendString:value into:json])
            return NO;
        
        [json appendString:colon];
        if (![self appendValue:[fragment objectForKey:value] into:json]) {
            [self addErrorWithCode:EUNSUPPORTED description:[NSString stringWithFormat:@"Unsupported value for key %@ in object", value]];
            return NO;
        }
    }
    
    depth--;
    if ([self humanReadable] && [fragment count])
        [json appendString:[self indent]];
    [json appendString:@"}"];
    return YES;    
}

- (BOOL)appendString:(NSString*)fragment into:(NSMutableString*)json {
    
    static NSMutableCharacterSet *kEscapeChars;
    if( ! kEscapeChars ) {
        kEscapeChars = [NSMutableCharacterSet characterSetWithRange: NSMakeRange(0,32)];
        [kEscapeChars addCharactersInString: @"\"\\"];
    }
    
    [json appendString:@"\""];
    
    NSRange esc = [fragment rangeOfCharacterFromSet:kEscapeChars];
    if ( !esc.length ) {
        // No special chars -- can just add the raw string:
        [json appendString:fragment];
        
    }
    else
    {
        NSRange fullFragmentRange = NSMakeRange(0, [fragment length]);
        [fragment enumerateSubstringsInRange:fullFragmentRange
                                     options:NSStringEnumerationByComposedCharacterSequences
                                  usingBlock:^(NSString *substring, NSRange substringRange,
                                               NSRange enclosingRange, BOOL *stop)
         {
            if ([@"\"" isEqualToString:substring])
            {
              [json appendString:@"\\\""];
            }
            else if ([@"\\" isEqualToString:substring])
            {
              [json appendString:@"\\\\"];
            }
            else if ([@"\t" isEqualToString:substring])
            {
              [json appendString:@"\\t"];
            }
            else if ([@"\n" isEqualToString:substring])
            {
              [json appendString:@"\\n"];
            }
            else if ([@"\r" isEqualToString:substring])
            {
              [json appendString:@"\\r"];
            }
            else if ([@"\b" isEqualToString:substring])
            {
              [json appendString:@"\\b"];
            }
            else if ([@"\f" isEqualToString:substring])
            {
              [json appendString:@"\\f"];
            }
            else
            {
              NSUInteger numUni = [substring length];
              if (numUni > 1)
              {
                // Change the unicode to something the UI can handle.
                NSMutableString *hexString = [[NSMutableString alloc] init];
                for (int i = 0; i < numUni; i++)
                {
                  unichar unicode = [substring characterAtIndex:i];
                  // Because XML does not support \u unicode notations, we are
                  // using &# from http://stackoverflow.com/questions/11592013/unicode-string-in-xml
                  // so Cloud UI can parse the string we send over.
                  [hexString appendString:[NSString stringWithFormat:@"&#x%x;", unicode]];
                  //MPLogDebug(@"unicode = %d, %x", unicode, unicode);
                }
              
                //MPLogDebug(@"hexString = %@", hexString);
                [json appendString:hexString];
              }
              else
              {
                unichar unicode = [substring characterAtIndex:0];
                if (unicode < 0x20)
                {
                  [json appendString:@"\\u%04x"];
                }
              
                [json appendString:substring];
              }
            }
         }];
    }
    
    [json appendString:@"\""];
    return YES;
}


@end
