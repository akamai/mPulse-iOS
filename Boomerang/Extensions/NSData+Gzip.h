//
//  NSData+Gzip.h
//  TouchTestDriver
//
//  Copyright (c) 2012 SOASTA, Inc. All rights reserved.
//  Based on code from http://www.cocoadev.com/index.pl?NSDataCategory
//

#import <Foundation/Foundation.h>

@interface NSData (Gzip)

- (NSData *) gzipInflate;
- (NSData *) gzipDeflate;

@end
