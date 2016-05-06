//
//  MPConfig.m
//  Boomerang
//
//  Created by Mukul Sharma on 4/23/14.
//  Copyright (c) 2014-2015 SOASTA. All rights reserved.
//

#import "MPConfig.h"
#import "MPulse.h"
#import "MPulsePrivate.h"
#import "MPURLConnection.h"
#import "MPSession.h"
#import "NSObject+TT_SBJSON.h"
#import "JSON.h"
#import "MPLog.h"

@implementation MPConfig
{
  BOOL _beaconsEnabled; // Default value is NO
  NSString* _currentSignature;
}

static MPConfig *configInstance = NULL; // Singleton
static int configRefreshInterval = 300; // In seconds
static int CONFIG_NOT_READY_INTERVAL = 60; // In seconds
static int DEFAULT_BEACON_INTERVAL = 60; // In seconds

NSString* const BOOMERANG_CONFIG_REFRESHED = @"BoomerangConfigRefreshed";
NSString* const CONFIG_GET_REQUEST_COMPLETE = @"ConfigGetRequestComplete";
NSString* const BOOMERANG_PLIST = @"Boomerang.plist";
NSString* const SESSION_ID_KEY = @"SESSION_ID";

// Singleton access
+(MPConfig *) sharedInstance
{
  static dispatch_once_t _singletonPredicate;
  dispatch_once(&_singletonPredicate, ^{
    
    configInstance = [[super allocWithZone:nil] init];
  });
  
  return configInstance;
}

-(id) init
{
  _userEnabledBeacons = YES; // Default value is YES
  _beaconInterval = DEFAULT_BEACON_INTERVAL; // Default beacon send interval is 60 seconds.
  
  if (_mPulseServerURL == nil || _APIKey == nil || [_APIKey length] == 0)
  {
    _beaconsEnabled = NO;
  }
  else
  {
    [self buildConfigRequestURL];

    _isHUDEnabled = NO; //Disabled by default.
    _HUDColor = @"#5e00ff"; // Default to Purple Color.
    _HUDDisplayDuration = 3; // Default to 3 seconds.
    _generateNetworkErrors = NO; //Disabled by default.

    // Fetch and parse config.js and schedule the next refresh
    [self refresh];
  }
  
  return self;
}

-(void) refresh
{
  if (_refreshDisabled)
  {
    // If refresh has been disabled by a Unit Test, simply return.
    return;
  }
  
  [self initWithURL];
  
  // Run again after n seconds
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, configRefreshInterval * NSEC_PER_SEC),
                 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL), ^{
                   [self refresh];
                 });
}

-(void) initWithURL
{
  if (!_userEnabledBeacons)
  {
    return; // If user has disabled beacons, we should not poll for config.
  }
  
  // Download the Config.js file from the mPulse server
  // We need to make sure that HTTP response is not cached -
  // http://stackoverflow.com/questions/405151/is-it-possible-to-prevent-an-nsurlrequest-from-caching-data-or-remove-cached-dat
  NSURLRequest *request = [NSURLRequest requestWithURL:_configURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
  MPURLConnection *urlConnection = [[MPURLConnection alloc] init];
  NSHTTPURLResponse *httpResponse;
  NSError *error = nil;
  NSData *responseData = [urlConnection sendSynchronousRequest:request response:&httpResponse error:&error timeout:30.0];
  
  // Network Request is now complete, send completion notification.
  [self sendConfigRequestCompleteNotification];
  
  if (responseData == nil)
  {
    MPLogDebug(@"Unable to get config.js from the server. Response data for config request is nil.");
    [self markBeaconsDisabled];
    return;
  }
  
  // Parse the response body to obtain JSON Data
  NSString *responseBody = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
  error = nil;
  
  MPLogDebug(@"Response: %@", responseBody);

  // Update the Config refresh interval based on max-age parameter available as part of Cache-Control Response header.
  // Example: "Cache-Control" = "private, max-age=300, stale-while-revalidate=60, stale-if-error=120";
  NSDictionary* headers = [httpResponse allHeaderFields];
  if ([headers objectForKey:@"Cache-Control"] != nil)
  {
    NSString *maxAge = [self search:@"(?:[;,]|^) *max-age=\\s*([^,]+)," inContent:[headers objectForKey:@"Cache-Control"]];
    if (maxAge != nil)
    {
      // Update the config refresh interval
      configRefreshInterval = [maxAge intValue];
    }
  }
  
  // Parse the response body
  [self initWithResponse:responseBody];
}

- (void) markBeaconsDisabled
{
  _beaconsEnabled = NO;
  configRefreshInterval = CONFIG_NOT_READY_INTERVAL;
}

- (void) markBeaconsEnabled
{
  _beaconsEnabled = YES;
}

- (void)initWithResponse:(NSString *)responseBody
{
  NSDictionary* response = nil;
  if (responseBody != nil && [responseBody length] > 0)
  {
    @try
    {
      response = [responseBody tt_JSONValue];
      if (response == nil)
      {
        MPLogError(@"Error parsing Config JSON: %@", responseBody);
        [self markBeaconsDisabled];
        return;
      }
      
      // Make sure beacon_url was sent as part of the Response JSON.
      // This validation is important since our error messages are delivered in JSON as well.
      if ([response objectForKey:@"beacon_url"] == nil)
      {
        MPLogError(@"Invalid Config JSON received: %@", responseBody);
        [self markBeaconsDisabled];
        return;
      }
    }
    @catch (NSException *exception)
    {
      MPLogError(@"Invalid Config JSON: %@", responseBody);
      [self markBeaconsDisabled];
      return;
    }
  }
  else
  {
    MPLogError(@"Empty Config JSON received: %@", responseBody);
    [self markBeaconsDisabled];
    return;
  }

  // Get h.cr
  _currentSignature = [response objectForKey:@"h.cr"];
  
  // Get h.t
  //  MPLogDebug(@"Current Timestamp: %@", [response objectForKey:@"h.t"]);
  
  // Get beacon interval
  _beaconInterval = [[response objectForKey:@"beacon_interval"] doubleValue];
  if (_beaconInterval < 1)
  {
    _beaconInterval = DEFAULT_BEACON_INTERVAL; // Default beacon send interval is 60 seconds.
  }
  
  // Get session expiration time
  // Example:     RT =     { "session_exp" = 1800; };
  _sessionExpirationTime = [[(NSDictionary*)[response objectForKey:@"RT"] objectForKey:@"session_exp"] doubleValue];
  
  // We only build beaconURL once, so that session implementation could work.
  // Updating beaconURL every time config is refreshed will break sessions.
  if (_beaconURL == nil)
  {
    // Get beacon_url, e.g., ... beacon_url: "//localhost:8080/concerto/beacon/"
    NSString* beaconURLString = [response objectForKey:@"beacon_url"];
    
    // Get protocol from configUrl
    NSRange protocolRange = [[_configURL absoluteString] rangeOfString:@"//"];  // beaconUrl starts with "//"
    NSString *protocol = [[_configURL absoluteString] substringToIndex:protocolRange.location];

    // trim trailing /
    if ([beaconURLString hasSuffix:@"/"])
    {
      beaconURLString = [beaconURLString substringToIndex:[beaconURLString length] - 1];
    }

    _beaconURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/batch", protocol, beaconURLString]];
    
    MPLogDebug(@"Beacon URL: %@", _beaconURL);
  }

  // We will initialize a temporary object first to make sure nobody tries to obtain it before its completely initialized.
  MPConfigPageParams *tempConfigObject = [[MPConfigPageParams alloc] initWithJson:[response objectForKey:@"PageParams"]];
  _pageParamsConfig = tempConfigObject;
  
  _urlPatterns = [response objectForKey:@"urlPatterns"];
  
  // At this point, we've parsed the config.js successfully, so we can start sending beacons.
  [self markBeaconsEnabled];
  
  // Get session ID and send notification that config refresh was successful.
  NSString *sessionID = [response objectForKey:@"session_id"];
  
  [self sendConfigRefreshNotification:sessionID];
  
  // Update the config.js URL only if its missing the session ID. This only needs to happen once.
  if ([[_configURL absoluteString] rangeOfString:@"&si="].location == NSNotFound)
  {
    // Update the config URL to include session ID
    [self buildConfigRequestURL];
  }
  
  id stripQueryStringBody = [response objectForKey:@"strip_query_string"];
  _stripQueryStrings = (stripQueryStringBody != nil && [stripQueryStringBody boolValue]);
}

-(BOOL) beaconsEnabled
{
  if (!_userEnabledBeacons)
  {
    return NO; // If user has turned off beacons, return NO.
  }
  else
  {
    return _beaconsEnabled; // Else, return the current status.
  }
}

// Send notification to all listerners that config has been refreshed.
-(void) sendConfigRefreshNotification:(NSString*) sessionID
{
  NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:sessionID, SESSION_ID_KEY, nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:BOOMERANG_CONFIG_REFRESHED object:nil userInfo:userInfo];
}

// Send notification to all listerners that config refresh network request is complete.
-(void) sendConfigRequestCompleteNotification
{
  [[NSNotificationCenter defaultCenter] postNotificationName:CONFIG_GET_REQUEST_COMPLETE object:nil userInfo:nil];
}

// Generate the URL to retreive config.js file from the server
-(void) buildConfigRequestURL
{
  NSMutableString *urlString = [[NSMutableString alloc] init];
  [urlString appendString:[_mPulseServerURL absoluteString]];
  
  // Unit test will possibly send a URL with delay param already appended to the mPulse Server URL
  // In that case, we must append the key param (by using & prefix).
  NSString* key = ([urlString rangeOfString:@"?delay="].location != NSNotFound)? @"&key=" : @"?key=";
  
  // API key
  [urlString appendString:key];
  [urlString appendString:_APIKey];

  // Build version
  [urlString appendString:@"&v="];
  [urlString appendString:MPULSE_BUILD_VERSION_NUMBER];

  // Let them know this is a library
  [urlString appendString:@"&l=ios"];
  
  MPSession *session = [MPSession sharedInstance];
  if ([session started])
  {
    [urlString appendString:@"&si="];
    [urlString appendString:[session ID]];
  }
  
  _configURL = [NSURL URLWithString: urlString];
  MPLogInfo(@"Config URL: %@", _configURL);
}

// Perform a search for matching regex in the content and return the result if found.
-(NSString*) search:(NSString*) regexString inContent:(NSString*) content
{
  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:&error];
  NSTextCheckingResult *match = [regex firstMatchInString:content options:0 range:NSMakeRange(0, [content length])];
  
  if (match)
  {
    NSRange range = [match rangeAtIndex:1];
    return [content substringWithRange:range];
  }
  
  return nil;
}

@end
