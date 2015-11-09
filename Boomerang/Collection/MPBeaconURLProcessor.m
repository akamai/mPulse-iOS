//
//  MPBeaconURLProcessor.m
//  Boomerang
//
//  Created by Matthew Solnit on 5/14/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPBeaconURLProcessor.h"
#import "NSString+MPExtensions.h"

#define MAX_QS_COMPONENTS 30

@implementation MPBeaconURLProcessor

+(NSString*) extractURL:(MPBeacon*) beacon urlPatterns:(NSArray*)urlPatterns
{
  if (beacon.url == nil || beacon.url.length == 0)
  {
    return nil;
  }
  else
  {
    // Parse the string URL into an object.
    NSURL* url = [NSURL URLWithString:beacon.url];
    
    // Extract the portion of the path that we're going to keep (if any).
    NSString* path = [MPBeaconURLProcessor extractURLPath:url urlPatterns:urlPatterns];
    
    // Construct a new URL string with the adjusted path.
    return [NSString stringWithFormat:@"%@://%@%@", url.scheme, url.host, path];
  }
}

+(NSString*) extractURLPath:(NSURL*)url urlPatterns:(NSArray*)urlPatterns
{
  // Does this URL include a path?
  if (url.path.length == 0)
  {
    // This URL doesn't have a path.
    
    // Case 83380: When the URL doesn't have a child, for example: http://www.soasta.com,
    // our widgets don't show the data correctly.
    // Thus, we return "/" to make the path look like this - http://www.soasta.com/
    // URL in the format displayed will then show up correctly in the widget.
    return @"/";
  }
  else
  {
    // This URL has a path.
    
    // Does the configuration have any predefined URL patterns?
    if (urlPatterns == nil || urlPatterns.count == 0)
    {
      // There are no URL patterns defined.
      
      // We ignore the entire path.
      // path cannot be empty - return "/" if no path exists
      return @"/";
    }
    else
    {
      // There is at least one URL pattern defined.
      // Look for a match and use the resulting path.
      
      NSMutableArray* inQSComponents = [NSMutableArray array];
      
      // Store query string param=val in a list so we can remove them once used
      if (url.query != nil && url.query.length > 0)
        [inQSComponents addObjectsFromArray:[url.query componentsSeparatedByString:@"&"]];
      
      for (NSString* pattern in urlPatterns)
      {
        NSURL* patternURL = nil;
        
        @try
        {
          patternURL = [NSURL URLWithString:pattern];
        }
        @catch (NSException *exception)
        {
          // invalid URL, so skip
          MPLogDebug(@"URL pattern is invalid: %@ (%@)", pattern, exception);
          continue;
        }
        
        NSMutableString* tokenizedPath = [MPBeaconURLProcessor extractURLPath:url fromPattern:patternURL];
        
        if (tokenizedPath != nil)
        {
          // This pattern matched all our requirements, so we can stop checking patterns at this point.
          // we still need to tokenize the query string if required, so we'll go through that.
          // if there are any errors in query string tokenization, we will ignore the entire query
          // string.
          
          NSArray* pQSComponents = [patternURL.query componentsSeparatedByString:@"&"];
          
          // We only go through this section if there are any query string components to match against
          // and the number of query string parameters in the input URL is within allowed limits
          if (pQSComponents.count > 0 && inQSComponents.count <= MAX_QS_COMPONENTS)
          {
            // These two loops will be O(n^2), we could reduce to O(n) by creating a Map, but it becomes complicated
            // if we have the same key with multiple values (valid scenario)
            // Instead a better option is to error out if the number of query string parameters is too high, so that's
            // what we do.
            
            BOOL first = YES;
            
            for (NSString* pQSComponent in pQSComponents)
            {
              if (![pQSComponent hasSuffix:@"=*"])
              {
                // looks like an invalid pattern
                MPLogDebug(@"Invalid query string component: %@", pQSComponent);
                continue;
              }
              
              NSString* key = [pQSComponent substringWithRange:NSMakeRange(0, pQSComponent.length - 2)];
              
              for (NSString* inQSComponent in inQSComponents)
              {
                NSArray* kv = [inQSComponent componentsSeparatedByString:@"="];
                if (![MPBeaconURLProcessor urlComponentEquals:key b:[kv objectAtIndex:0]])
                {
                  continue;
                }
                
                [tokenizedPath appendString:(first ? @"?" : @"&")];
                [tokenizedPath appendString:key];
                [tokenizedPath appendString:@"="];
                
                if (kv.count > 1)
                  [tokenizedPath appendString:[kv objectAtIndex:1]];
                
                first = NO;
              }
            }
          }
          else if (pQSComponents.count > 0 && inQSComponents.count > MAX_QS_COMPONENTS)
          {
            MPLogDebug(@"Query string has too many components: %@", url);
          }
          
          return tokenizedPath;
        }
      }
      
      // If we reach this point, then no patterns matched.
      // We ignore the entire path.
      // path cannot be empty - return "/" if no path exists
      return @"/";
    }
  }
}

+(NSMutableString*) extractURLPath:(NSURL*)url fromPattern:(NSURL*)patternURL
{
  NSMutableString* tokenizedPathBuilder = [NSMutableString string];
  
  if (![patternURL.host isEqualToString:url.host])
  {
    // host doesn't match, so skip
    return nil;
  }
  
  // First we check the path components
  if (patternURL.path.length > 0)
  {
    NSArray* patternPathComponents = [MPBeaconURLProcessor tokenizeURLPath:patternURL];
    NSArray* urlPathComponents = [MPBeaconURLProcessor tokenizeURLPath:url];

    if (urlPathComponents.count != patternPathComponents.count)
    {
      // number of path components doesn't match, so skip
      return nil;
    }

    for (int i = 0; i < patternPathComponents.count; i++)
    {
      NSString* patternPathComponent = [patternPathComponents objectAtIndex:i];
      NSString* urlPathComponent = [urlPathComponents objectAtIndex:i];

      if ([patternPathComponent isEqualToString:@"*"])
      {
        [tokenizedPathBuilder appendString:@"/*"];
      }
      else if ([MPBeaconURLProcessor urlComponentEquals:patternPathComponent b:urlPathComponent])
      {
        [tokenizedPathBuilder appendString:@"/"];
        [tokenizedPathBuilder appendString:patternPathComponent];
      }
      else
      {
        // path structure doesn't match, so skip the entire pattern
        return nil;
      }
    }
  }
  
  // If we get to the end of the path checks for a single pattern, it means that this
  // pattern matched all our requirements.
  return tokenizedPathBuilder;
}

+(NSArray*) tokenizeURLPath:(NSURL*)url
{
  // Use CFURLCopyPath() instead of -[NSURL path], because
  // the former preserves trailing spaces (which we need).
  NSString* path = (__bridge_transfer NSString*)CFURLCopyPath((__bridge CFURLRef)url);

  // Trim off the opening slash.
  path = [path substringFromIndex:1];

  // Break up the remainder.
  return [path componentsSeparatedByString:@"/"];
}

+(BOOL) urlComponentEquals:(NSString*)a b:(NSString*)b
{
  // If the encoded forms are equal, just return true
  if ([a isEqualToString:b])
    return YES;
  
  // If encoded forms are not equal, there's a chance that they were encoded slightly differently,
  // eg: + v/s %20 or encoded in one but not in the other, so we need to decode them and compare.
  
  return [[a mp_stringByDecodingURLFormat] isEqualToString:[b mp_stringByDecodingURLFormat]];
}

@end
