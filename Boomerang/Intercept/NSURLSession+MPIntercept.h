//
//  NSURLSession+MPIntercept.h
//  Boomerang
//
//  Copyright (c) 2012-2015 SOASTA. All rights reserved.
//

// See note in NSURLSession+MPIntercept.m for why all of these exist

#import <Foundation/Foundation.h>

@interface NSURLSession (MPIntercept) <NSURLSessionTaskDelegate>

- (NSURLSessionDataTask *)boomerangDataTaskWithRequest:(NSURLRequest *)request;

- (NSURLSessionDataTask *)boomerangDataTaskWithRequest:(NSURLRequest *)request
                                     completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)boomerangUploadTaskWithRequest:(NSURLRequest *)request
                                                  fromFile:(NSURL *)fileURL;

- (NSURLSessionUploadTask *)boomerangUploadTaskWithRequest:(NSURLRequest *)request
                                                  fromFile:(NSURL *)fileURL
                                         completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)boomerangUploadTaskWithRequest:(NSURLRequest *)request
                                                  fromData:(NSData *)fileURL;

- (NSURLSessionUploadTask *)boomerangUploadTaskWithRequest:(NSURLRequest *)request
                                                  fromData:(NSData *)fileURL
                                         completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

- (NSURLSessionUploadTask *)boomerangUploadTaskWithStreamedRequest:(NSURLRequest *)request;

- (NSURLSessionDownloadTask *)boomerangDownloadTaskWithRequest:(NSURLRequest *)request;

- (NSURLSessionDownloadTask *)boomerangDownloadTaskWithRequest:(NSURLRequest *)request
                                             completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;

- (NSURLSessionDownloadTask *)boomerangDownloadTaskWithResumeData:(NSData *)resumeData;

- (NSURLSessionDownloadTask *)boomerangDownloadTaskWithResumeData:(NSData *)resumeData
                                             completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler;

@end
