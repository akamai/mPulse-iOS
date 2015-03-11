//
//  MPulsePrivate.h
//  MPulse
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#define touchTestIDCall mPulseId
#define touchTestIDString @"mPulseId"

@interface MPulse()

-(NSString*) APIKey;
-(void) setAPIKey:(NSString *)apiKey;

-(NSURL*) serverURL;
-(void) setServerURL:(NSURL *)serverURL;

-(BOOL) generateNetworkErrors;
-(void) setGenerateNetworkErrors:(BOOL)generateNetworkErrors;

-(BOOL) isHUDEnabled;
-(void) setIsHUDEnabled:(BOOL)isHUDEnabled;

-(NSString*) HUDColor;
-(void) setHUDColor:(NSString *)HUDColor;

-(NSTimeInterval) HUDDisplayDuration;
-(void) setHUDDisplayDuration:(NSTimeInterval)HUDDisplayDuration;

-(NSArray *)customDimensions;

@end
/**
 * The MPulse category provides the ability to
 * set "mPulse ID's" on arbitrary UI views.
 *
 * This category provides optional functionality that can be used to
 * enhance the testing process when using mPulse.  Specifically,
 * you can assign arbitrary ID's to UI views by setting the mPulseId
 * property.  Once an "mPulse ID" has been assigned, it will be
 * automatically detected during the recording process, and used as
 * the locator for any actions on that element.
 *
 * This is especially useful for cases where the normal locator would
 * be ambiguous.
 */
@interface UIView (MPulse)

/**
 * The current mPulse ID of this UIView.
 */
@property(retain) NSString *mPulseId;


@end