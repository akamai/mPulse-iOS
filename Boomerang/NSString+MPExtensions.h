//
//  NSString+TTExtensions.h
//  BoomerangDriver
//
//  Created by Matthew Solnit on 3/4/12.
//  Copyright (c) 2014 SOASTA, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MPExtensions)

- (NSNumber *) mp_numberValue:(NSString *)dataType;
- (NSString *) mp_stringByDecodingURLFormat;

+ (NSString*) mp_stringWithByteArray:(Byte*)bytes andLength:(int)length;
+ (NSString*) mp_stringWithIntArray:(int*)ints andLength:(int)length;

@end
