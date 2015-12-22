//
//  MPTouchHandlerThread.m
//  Boomerang
//
//  Created by Giri Senji on 4/23/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPTouchHandlerThread.h"
#import "MPulse.h"
#import "MPConfig.h"
#import "TTElement.h"

// Disabled for TTD removal
//#import "TTElement+TTAccessors.h"
//#import "TTLocateElement.h"
//#import "TTNativeButtonElement.h"
//#import "TTAutomationHud.h"

#import "MPApiCustomMetricBeacon.h"
#import "MPApiCustomTimerBeacon.h"
#import "MPTouchMetricValue.h"
#import "NSString+MPExtensions.h"
#import "NSObject+TTExtensions.h"
#import "NSString+TTExtensions.h"
#import "TTLocatorCollection.h"

typedef enum MPAppActionOutput
{
  IS_ELEMENT_PRESENT,
  IS_ELEMENT_NOT_PRESENT,
  ELEMENT_VALUE,
  ELEMENT_PROPERTY_VALUE,
  IS_ELEMENT_VISIBLE,
  IS_ELEMENT_NOT_VISIBLE,
  ELEMENT_TEXT,
  ELEMENT_COUNT
} MPAppActionOutput;

@interface MPTouchHandlerThread()
{
  
@private
  NSMutableDictionary* touchPageGroupControls;
  NSMutableDictionary* touchMetricControls;
  NSMutableDictionary* touchTimers;
  dispatch_queue_t dispatchQueue;
  TTLocatorCollection* locatorCollection;
  NSString* viewHierarchyPointerList;
}

-(UIControlEvents) uiControlEventFromString:(NSString *)string;
-(MPAppActionOutput) appActionOutputFromString:(NSString*)string;
-(NSString*) getLabel:(TTElement *) elem;

@end

@implementation MPTouchHandlerThread

static MPTouchHandlerThread *sharedObject = NULL; // Singleton

int const SCAN_INTERVAL = 0.5L; // In seconds

/**
 * Singleton access
 */
+(MPTouchHandlerThread*) sharedInstance
{
  static dispatch_once_t _singletonPredicate;
  dispatch_once(&_singletonPredicate, ^{
    sharedObject = [[super allocWithZone:nil] init];
    
    // MPConfig will notify us when configuration has been refreshed. We can start the session at that point.
    [[NSNotificationCenter defaultCenter] addObserver:sharedObject selector:@selector(receiveBoomerangConfigRefreshedNotification:) name:BOOMERANG_CONFIG_REFRESHED object:nil];
  });
  
  return sharedObject;
}

-(id) init
{
  // Create the Grand Central Dispatch queue that will be used for all beacon processing.
  dispatchQueue = dispatch_queue_create("com.soasta.mpulse.boomerang.MPTouchHandler", NULL);
  
  touchPageGroupControls = [NSMutableDictionary new];
  touchMetricControls = [NSMutableDictionary new];
  touchTimers = [NSMutableDictionary new];
  _touchConfig = [[MPTouchConfig alloc] init];
  locatorCollection = [[TTLocatorCollection alloc] init];
  _hasConfigChanged = NO;
  
  // Create a scheduled task to flush all records on a regular basis (the first execution will re-schedule itself when finished).
  // NOTE: We cannot obtain the beaconInterval value from a MPConfig instance because calling sharedInstance
  // method of MPConfig inside the dispatch will cause a deadlock and hang the app.
  // Thats why we start the thread with a 5 second interval which will be updated using the config
  // during next iteration.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
                 dispatchQueue, ^{ [self scan]; });
  
  return self;
}

-(void) receiveBoomerangConfigRefreshedNotification:(NSNotification *)notification
{
  _hasConfigChanged = YES;
}

- (void) start
{
  [NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];
}

- (BOOL) isEqualToCurrentPageGroup:(NSString *)pageGroup
{
  MPulse *driver = [MPulse sharedInstance];
  return pageGroup != nil && [driver getViewGroup] != nil && [pageGroup isEqualToString:[driver getViewGroup]];
}

- (BOOL) isPageGroupSet:(MPTouchPageGroup *)pageGroup
{
  return [self isEqualToCurrentPageGroup:pageGroup.pageGroupValue];
}

- (void) scan
{
  return;
  
  /*
   * Disabled for TTD removal
   
  if ([[MPConfig sharedInstance] beaconsEnabled])
  {
    @autoreleasepool
    {
      if (_hasConfigChanged)
      {
        [_touchConfig deepCopy:[[MPConfig sharedInstance] touchConfig]];
        MPLogDebug(@"MPTouchHandlerThread: Config has changed: %@", _touchConfig);
        
        // Config (and locators) have changed, thus build a new instance of TTLocatorCollection object.
        // Get all locators from the TouchConfig and find matching elements
        [self findAllMatchingElements];
        
        _hasConfigChanged = NO;
      }
      
      if ([[locatorCollection getAllLocators] count] == 0)
      {
        // If there are no locators, we have nothing to do just keep scanning
        // run again after scan interval
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, SCAN_INTERVAL * NSEC_PER_SEC),
                       dispatchQueue, ^{ [self scan]; });
      }
      
      if (viewHierarchyPointerList == nil)
      {
        // View hierarchy list is currently nil, which means we have not scanned the hierarchy so far.
        // Find matching elements and build the view hierarchy pointer list.
        [self findAllMatchingElements];
      }
      else
      {
        // Build the View Hierarchy pointer list, to check if view hierarchy has changed since last iteration.
        [locatorCollection setBuildViewHierarchyOnly:YES];
        [locatorCollection clearViewHierarchyPointerList];
        
        // Time to search for all matching elements.
        NSError *error = nil;
        locatorCollection = [[[TTLocateElement alloc] init] findElements:locatorCollection error:&error withVisibility:YES andOffsetParam:nil includeTransform:NO];

        // TODO:
        if (![viewHierarchyPointerList isEqualToString:[locatorCollection getViewHierarchyPointerList]])
        {
          // View Hierarchy has changed, must scan for matching elements again.
          // This process will update existing ViewHierarchyPointerList object as well.
          [self findAllMatchingElements];
        }
      }

      //Scan for PageGroups first.
      [self processPageGroups];
      
      for (MPTouchMetric *metric in [_touchConfig metrics])
      {
        // For an action metric to be fired, action element must be present.
        if (metric.action.name != nil && metric.action.locator != nil && metric.action.element != nil)
        {
          //TODO: Optimize: Filter out metrics that belongs to a different PageGroup (from Current PageGroup)
          [self processActionMetric:metric];
        }
        if (metric.condition.accessor != nil && metric.condition.locator != nil)
        {
          //TODO: Optimize: Filter out metrics that belongs to a different PageGroup (from Current PageGroup)
          [self processConditionMetric:metric];
        }
      }
      
      // Process all timers
      for (MPTouchTimer *timer in [_touchConfig timers])
      {
        [self processTouchTimers:timer];
      }
    }
  }
  
  // Run again after n seconds
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, SCAN_INTERVAL * NSEC_PER_SEC),
                 dispatchQueue, ^{ [self scan]; });

  */
}

/*
 * Scans the view hierarchy and finds all matching elements. Also builds the pointer list of current view hierarchy and updates
 * the "viewHierarchyPointerList" variable with the latest data.
 */

/*
 * Disabled for TTD removal
 
- (void)findAllMatchingElements
{
  // Find all matching elements here and scan methods will simply use the pre-populated element list.
  locatorCollection = [_touchConfig getAllLocators];
  
  if ([[locatorCollection getAllLocators] count] == 0)
  {
    return; // If there are no locators, there is no need to iterate the View Hierarchy.
  }
  
  // We must find all matching elements beside building the ViewHierarchy pointer list.
  [locatorCollection setBuildViewHierarchyOnly:NO];

  // Time to search for all matching elements.
  NSError *error = nil;
  locatorCollection = [[[TTLocateElement alloc] init] findElements:locatorCollection error:&error withVisibility:YES andOffsetParam:nil includeTransform:NO];
  
  // Obtain the ViewHierarchy pointer list we just built while iterating the ViewHierarchy.
  viewHierarchyPointerList = [NSString stringWithString:[locatorCollection getViewHierarchyPointerList]];
  
  // Save the matching elements in TouchConfig
  [_touchConfig updateStoredElements:locatorCollection];
}

- (void)processPageGroups
{
  for (MPTouchPageGroup *pageGroup in [_touchConfig pageGroups])
  {
    // Action
    // For an action pageGroup to get set, action element must be present.
    if (pageGroup.action.name != nil && pageGroup.action.locator != nil && pageGroup.action.element != nil)
    {
      [self processActionPageGroup:pageGroup];
    }
    
    // Condition
    if (pageGroup.condition.accessor != nil && pageGroup.condition.locator != nil)
    {
      [self processConditionPageGroup:pageGroup];
    }
    
    // PageGroup is now set, so we won't give precedence to the remaining pageGroup definitions.
    if ([self isPageGroupSet:pageGroup])
    {
      break;
    }
  }
}

- (void)processActionPageGroup:(MPTouchPageGroup *)pageGroup
{
  [self processActionPageGroupOrMetric:pageGroup];
}

- (void)processConditionPageGroup:(MPTouchPageGroup *)pageGroup
{
  NSString *conditionOutputValue = [self getOutput:pageGroup.condition.element locator:[pageGroup.condition.locator serializeShort] command:pageGroup.condition.accessor propertyName:pageGroup.condition.propertyName];
  MPLogDebug(@"processConditionPageGroup: condition: %@, outputValue: %@", pageGroup.condition, conditionOutputValue);
  BOOL conditionMatched = false;
  if (conditionOutputValue != nil)
  {
    conditionMatched = pageGroup.condition.value != nil ? [pageGroup.condition.value isEqualToString:conditionOutputValue] : [conditionOutputValue boolValue];
  }
  if (conditionMatched)
  {
    TTElement *extractElement = pageGroup.extract.element;
    
    // Did we find the "extract" element?
    if (extractElement != nil && [extractElement isVisible])
    {
      // We found it.
      MPLogDebug(@"processConditionPageGroup, extract element found: %@, %@", extractElement, [extractElement view]);
      
      // Has the PageGroup already been set?
      if ([self isPageGroupSet:pageGroup])
      {
        // PageGroup has already been set.
        // We won't send it again until the scanned condition has ended and then returned.
        MPLogDebug(@"PageGroup has already been set.");
      }
      else
      {
        // PageGroup has not been set yet.
        
        // Extract the pageGroup value.
        NSString *extractOutputValue = [self getOutput:pageGroup.extract.element locator:[pageGroup.extract.locator serializeShort] command:pageGroup.extract.accessor propertyName:pageGroup.extract.propertyName];
        MPLogDebug(@"ConditionPageGroup Matched. pageGroup: %@, outputValue: %@", pageGroup, extractOutputValue);
        
        // Display HUD
        NSString* labelText = [NSString stringWithFormat:@"\"%@\" PageGroup found with locator: %@", pageGroup.name, [pageGroup.condition.locator serializeShort]];
        [self displayHUD:labelText withDescriptionLabel:[NSString stringWithFormat:@"PageGroup set with value: %@", extractOutputValue]];
        
        // Set PageGroup!
        [MPulse sharedInstance].viewGroup = extractOutputValue;
        MPLogInfo(@"MPTouchHandlerThread, touchPageGroup: %@", [MPulse sharedInstance].viewGroup);
        
        // Remember this for the next time around.
        pageGroup.pageGroupValue = extractOutputValue;
      }
    }
    else
    {
      // We did not find the "extract" element.
      MPLogDebug(@"processConditionPageGroup, extract element not found (or is invisible).");
      
      // If we've already found a match and set the pageGroup, but the extract element has disappeared,
      // then we assume that the entire view has changed, and we can reset back to waiting for the
      // condition to occur again.
      if ([self isPageGroupSet:pageGroup])
      {
        MPLogDebug(@"Resetting \"pageGroup value\".");
        pageGroup.pageGroupValue = nil;
      }
    }
  }
}

- (void)processActionMetric:(MPTouchMetric *)metric
{
  [self processActionPageGroupOrMetric:metric];
}

- (UIControl *) getActionControl:(TTElement*) element
{
  UIView *view = [element view];
  if ([[view class] isSubclassOfClass:[UIControl class]])
  {
    // Input view is a UIControl, so just return it
    return (UIControl *)view;
  }
  
  // Check views superview until we find a view of kind UIControl and its not a known private internal class (= a class that begins with '_')
  while (view && !([view isKindOfClass:[UIControl class]] && ![NSStringFromClass([view class]) hasPrefix:@"_"]))
    view = [view superview];
  // Note:
  // If there is a custom view whose class name starts with an '_', then this approach would not detect such UIControls.
  // We are assuming that someone would not name their custom view with '_' prefix.
  // Alternative is to explicitly look and ignore all known UIKit internal classes like _UIStepperButton (which is not a smart strategy either)
  
  // Return view if its a UIControl, nil otherwise
  return [view isKindOfClass:[UIControl class]] ? (UIControl *)view : nil;
}

- (void)processActionPageGroupOrMetric:(id)object
{
  MPTouchAction *action = [object valueForKey:@"action"];
  TTElement *inputElement = action.element;
  
  if (inputElement == nil)
  {
    // If we don't have a matching element in the current view, return.
    return;
  }
  
  if ([inputElement view])
  {
    UIControl *actionControl = [self getActionControl:inputElement];
    if (actionControl == nil)
    {
      return;
    }

    // Metrics
    NSMutableDictionary* controls = touchMetricControls;
    SEL selector = @selector(metricUIEventTriggered:);
    if ([object isKindOfClass:[MPTouchPageGroup class]])
    {
      // Page Groups
      controls = touchPageGroupControls;
      selector = @selector(pageGroupUIEventTriggered:);
    }
    
    [controls setObject:object forKey:[NSValue valueWithNonretainedObject:actionControl]];
    UIControlEvents uiControlEvent = [self uiControlEventFromString:action.name];
    if (uiControlEvent)
    {
       // Remove a pre-existing target if we've added it previously.
      [actionControl removeTarget:self action:selector forControlEvents:uiControlEvent];
      
      // Add a UI Event responder
      [actionControl addTarget:self action:selector forControlEvents:uiControlEvent];
    }
    else
    {
      if ([action.name isEqualToString:@"DoubleTap"] || [action.name isEqualToString:@"doubleTap"] || [action.name isEqualToString:@"doubletap"])
      {
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:actionControl action:selector];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
        [actionControl addGestureRecognizer:doubleTapGestureRecognizer];
        [controls setObject:object forKey:[NSValue valueWithNonretainedObject:doubleTapGestureRecognizer]];
      }
      else if ([action.name isEqualToString:@"Pan"] || [action.name isEqualToString:@"pan"])
      {
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:actionControl action:selector];
        [actionControl addGestureRecognizer:panGestureRecognizer];
        [controls setObject:object forKey:[NSValue valueWithNonretainedObject:panGestureRecognizer]];
      }
      else if ([action.name isEqualToString:@"Pinch"] || [action.name isEqualToString:@"pinch"])
      {
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]initWithTarget:actionControl action:selector];
        [actionControl addGestureRecognizer:pinchGestureRecognizer];
        [controls setObject:object forKey:[NSValue valueWithNonretainedObject:pinchGestureRecognizer]];
      }
      else if ([action.name isEqualToString:@"Rotation"] || [action.name isEqualToString:@"rotation"])
      {
        UIRotationGestureRecognizer *rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc]initWithTarget:actionControl action:selector];
        [actionControl addGestureRecognizer:rotationGestureRecognizer];
        [controls setObject:object forKey:[NSValue valueWithNonretainedObject:rotationGestureRecognizer]];
      }
      else if ([action.name isEqualToString:@"Swipe"] || [action.name isEqualToString:@"swipe"])
      {
        UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:actionControl action:selector];
        [actionControl addGestureRecognizer:swipeGestureRecognizer];
        [controls setObject:object forKey:[NSValue valueWithNonretainedObject:swipeGestureRecognizer]];
      }
    }
  }
}

- (void)processConditionMetric:(MPTouchMetric *)metric
{
  NSString *conditionOutputValue = [self getOutput:metric.condition.element locator:[metric.condition.locator serializeShort] command:metric.condition.accessor propertyName:metric.condition.propertyName];
  //MPLogDebug(@"processConditionMetric: condition: %@, outputValue: %@", metric.condition, conditionOutputValue);
  BOOL conditionMatched = false;
  if (conditionOutputValue != nil)
  {
    conditionMatched = metric.condition.value != nil ? [metric.condition.value isEqualToString:conditionOutputValue] : [conditionOutputValue boolValue];
  }
  if (conditionMatched)
  {
    NSString *extractOutputValue = nil;
    TTElement *extractElement = nil;
    if (metric.extract.fixedValue != nil)
    {
      // Metric value is a fixedValue
      extractOutputValue = metric.extract.fixedValue;
    }
    else
    {
      extractElement = metric.extract.element;
    }
    
    // Did we find the "extract" element?
    if (metric.extract.fixedValue != nil || (extractElement != nil && [extractElement isVisible]))
    {
      // We found it.
      MPLogDebug(@"MPTouchHandlerThread, extract element found: %@, %@", extractElement, [extractElement view]);
      
      // Has the beacon already been sent?
      if ([metric beaconSent])
      {
        // Beacon has already been sent.
        // We won't send it again until the scanned condition has ended and then returned.
        MPLogDebug(@"Metric beacon has already been sent.");
      }
      else
      {
        // Beacon has not yet been sent.
        
        if (metric.extract.fixedValue == nil)
        {
          // Extract the metric value.
          extractOutputValue = [self getOutput:metric.extract.element locator:[metric.extract.locator serializeShort] command:metric.extract.accessor propertyName:metric.extract.propertyName];
        }
        
        MPLogInfo(@"ConditionMetric Matched. metric: %@, outputValue: %@", metric, extractOutputValue);
        
        if (metric.pageGroup == nil || [self isEqualToCurrentPageGroup:metric.pageGroup])
        {
          // Display HUD
          NSString* labelText = [NSString stringWithFormat:@"\"%@\" metric found with locator: %@", metric.name, [metric.condition.locator serializeShort]];
          [self displayHUD:labelText withDescriptionLabel:[NSString stringWithFormat:@"Beacon sent for \"%@\" with value: %@", metric.extract, extractOutputValue]];
          
          // Send it!
          [[MPApiCustomMetricBeacon alloc] initWithMetricIndex:metric.index andValue:[extractOutputValue mp_numberValue:metric.dataType]];
          
          // Remember this for the next time around.
          metric.beaconSent = YES;
        }
      }
    }
    else
    {
      // We did not find the "extract" element.
      MPLogDebug(@"MPTouchHandlerThread, extract element not found (or is invisible).");
      
      // If we've already sent the beacon for this metric, but the extract element has disappeared,
      // then we assume that the entire view has changed, and we can reset back to waiting for the
      // condition to occur again.
      if ([metric beaconSent])
      {
        MPLogDebug(@"Resetting \"beacon sent\" flag.");
        metric.beaconSent = NO;
      }
    }
  }
  else
  {
    // If we've already sent the beacon for this metric, but the metric condition no longer applies,
    // then we assume that the entire view has changed, and we can reset back to waiting for the
    // condition to occur again.
    if ([metric beaconSent])
    {
      MPLogDebug(@"Resetting \"beacon sent\" flag because condition %@ on %@ is no longer true", metric.condition.accessor, metric.condition.locator);
      metric.beaconSent = NO;
    }
  }
}

- (void)processActionTimerStart:(MPTouchTimer *)timer
{
  [self processActionTimer:timer action:timer.startAction isStart:YES];
}

- (void)processActionTimerEnd:(MPTouchTimer *)timer
{
  [self processActionTimer:timer action:timer.endAction isStart:NO];
}

- (void)processActionTimer:(MPTouchTimer *)timer action:(MPTouchAction *)action isStart:(BOOL)isStart
{
  // For an action timer to start/end, action element must be present.
  if (action.element == nil)
  {
    return;
  }
  
  // Check if we support the Action
  TTElement *actionElement = action.element;
  
  if ([actionElement view] && [[[[actionElement view] superview] class] isSubclassOfClass:[UIButton class]])
  {
    UIButton *actionElem = (UIButton *) [[actionElement view] superview];
    UIControlEvents uiControlEvent = [self uiControlEventFromString:action.name];
    
    if (uiControlEvent)
    {
      // Yes, we support the action
      if (isStart)
      {
        // Remove a pre-existing target if we've added it previously.
        [actionElem removeTarget:self action:@selector(timerStartUIControlEventTriggered:) forControlEvents:uiControlEvent];

        // Inject a responder to target element.
        [actionElem addTarget:self action:@selector(timerStartUIControlEventTriggered:) forControlEvents:uiControlEvent];
      }
      else
      {
        // Check if we've already added our responder
        // Remove a pre-existing target if we've added it previously.
        [actionElem removeTarget:self action:@selector(timerEndUIControlEventTriggered:) forControlEvents:uiControlEvent];
        
        // Inject a responder to target element.
        [actionElem addTarget:self action:@selector(timerEndUIControlEventTriggered:) forControlEvents:uiControlEvent];
      }
      
      // Store the timer with actionElement, so when user interacts with the element, our responder can obtain the beacon and end the timer.
      [touchTimers setObject:timer forKey:[NSValue valueWithNonretainedObject:actionElem]];
    }
  }
}

- (void)processConditionTimerStart:(MPApiCustomTimerBeacon *)beacon timer:(MPTouchTimer *)timer
{
  // If timer has already started, we don't start it again.
  if (![beacon hasTimerStarted])
  {
    NSString *outputValue = [self getOutput:timer.startCondition.element locator:[timer.startCondition.locator serializeShort] command:timer.startCondition.accessor propertyName:timer.startCondition.propertyName];
    
    // Timer has not yet started, thus we need to start it.
    if ([outputValue isEqualToString:@"true"] || [outputValue isEqualToString:timer.startCondition.value])
    {
      // Display HUD
      [self displayHUD:[NSString stringWithFormat:@"\"%@\" timer started.", [timer name]] withDescriptionLabel:@""];

      MPLogDebug(@"processConditionTimerStart: starting timer on beacon %p", beacon);
      //Start beacon timer
      [beacon startTimer];
    }
  }
}

- (void)processConditionalTimerEnd:(MPTouchTimer *)timer beacon:(MPApiCustomTimerBeacon *)beacon
{
  // If timer has not started or already ended, we cannot end it.
  if ([beacon hasTimerStarted] && ![beacon hasTimerEnded])
  {
    NSString *outputValue = [self getOutput:timer.endCondition.element locator:[timer.endCondition.locator serializeShort] command:timer.endCondition.accessor propertyName:timer.endCondition.propertyName];
    
    // Check if timer ending conditions have been met.
    if ([outputValue isEqualToString:@"true"] || [outputValue isEqualToString:timer.endCondition.value])
    {
      MPLogDebug(@"processConditionalTimerEnd: ending timer on beacon %p", beacon);
      //End beacon timer
      [beacon endTimer];
      
      // Display HUD
      NSString* labelText = [NSString stringWithFormat:@"\"%@\" timer stopped.", [timer name]];
      [self displayHUD:labelText withDescriptionLabel:[NSString stringWithFormat:@"Beacon sent with duration: %d", [beacon timerValue]]];
    }
  }
}

- (void)processTouchTimers:(MPTouchTimer *)timer
{
  // Do we already have a beacon for this timer in our dictionary?
  MPApiCustomTimerBeacon *beacon = [timer beacon];
  if (beacon == nil || [beacon hasTimerEnded])
  {
    // Beacon was either not found or has already ended and sent to server.
    
    // Creating a beacon we will use to start/stop timer.
    beacon = [[MPApiCustomTimerBeacon alloc] initWithIndex:timer.index];
  }
  
  // Store the beacon with timer as key because endTimer
  [timer setBeacon:beacon]; // New or original which has not ended
  
  // If the Start condition is an Action
  if ([timer isStartAction])
  {
    [self processActionTimerStart:timer];
  }
  else if ([timer isStartCondition])
  {
    // If the Start condition is a conditional
    [self processConditionTimerStart:beacon timer:timer];
  }
  
  // If the End condition is an Action
  if ([timer isEndAction])
  {
    [self processActionTimerEnd:timer];
  }
  else if ([timer isEndCondition])
  {
    // If the End condition is a conditional
    [self processConditionalTimerEnd:timer beacon:beacon];
  }
}

-(UIControlEvents) uiControlEventFromString:(NSString *)string
{
  if ([string isEqualToString:@"Tap"] || [string isEqualToString:@"tap"])
  {
    return UIControlEventTouchUpInside;
  }
  if ([string isEqualToString:@"ValueChanged"] || [string isEqualToString:@"valueChanged"] || [string isEqualToString:@"valuechanged"])
  {
    return UIControlEventValueChanged;
  }
  return nil;
}

-(MPAppActionOutput) appActionOutputFromString:(NSString*)string
{
  if ([string isEqualToString:@"output-isElementPresent"] || [string isEqualToString:@"elementPresent"])
  {
    return IS_ELEMENT_PRESENT;
  }
  if ([string isEqualToString:@"output-isElementNotPresent"] || [string isEqualToString:@"elementNotPresent"])
  {
    return IS_ELEMENT_NOT_PRESENT;
  }
  else if ([string isEqualToString:@"output-elementValue"] || [string isEqualToString:@"elementValue"])
  {
    return ELEMENT_VALUE;
  }
  else if ([string isEqualToString:@"output-elementPropertyValue"] || [string isEqualToString:@"elementPropertyValue"])
  {
    return ELEMENT_PROPERTY_VALUE;
  }
  else if ([string isEqualToString:@"output-isElementVisible"] || [string isEqualToString:@"elementVisible"])
  {
    return IS_ELEMENT_VISIBLE;
  }
  else if ([string isEqualToString:@"output-isElementNotVisible"] || [string isEqualToString:@"elementNotVisible"])
  {
    return IS_ELEMENT_NOT_VISIBLE;
  }
  else if ([string isEqualToString:@"output-elementText"] || [string isEqualToString:@"elementText"])
  {
    return ELEMENT_TEXT;
  }
  else if ([string isEqualToString:@"output-elementCount"] || [string isEqualToString:@"elementCount"])
  {
    return ELEMENT_COUNT;
  }
  return -1;
}

-(id) getOutput:(TTElement *)element locator:(NSString*)locator command:(NSString *)command propertyName:(NSString *)propertyName
{
  MPAppActionOutput actionOutput = [self appActionOutputFromString:command];

  @try {
    switch (actionOutput)
    {
      case IS_ELEMENT_PRESENT:
      {
        // Was the element found?
        return [NSString tt_stringWithBoolean:(element != nil)];
      }
      case IS_ELEMENT_NOT_PRESENT:
      {
        // Was the element found?
        return [NSString tt_stringWithBoolean:(element == nil)];
      }
      case ELEMENT_VALUE:
      {
        return [element value];
      }
      case ELEMENT_PROPERTY_VALUE:
      {
        if (!propertyName || [propertyName tt_isEmpty])
        {
          return nil;
        }
        
        NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
        [args setObject:propertyName forKey:@"propertyName"];
        
        return [self performSafeAccessor:@selector(propertyValue:) onElement:(TTNativeElement *)element withArgs:args];
      }
      case IS_ELEMENT_VISIBLE:
      {
        return [NSString tt_stringWithBoolean:[element isVisible]];
      }
      case IS_ELEMENT_NOT_VISIBLE:
      {
        return [NSString tt_stringWithBoolean:(![element isVisible])];
      }
      case ELEMENT_TEXT:
      {
        return [element text];
      }
      case ELEMENT_COUNT:
      {
        NSUInteger count = 0;
        if (![locator isEqual:@""])
          count = [[[TTLocateElement alloc] init] findElementCount:locator];
        
        return [NSString tt_stringWithUInt:count];
      }
      default:
      {
        MPLogDebug(@"Unsupported output %u", actionOutput);
        return nil;
      }
    }
  }
  @catch (NSException *exception) {
    MPLogDebug(@"Caught AutomationUnhandledExceptionError  %@ %@", exception, [exception callStackSymbols]);
  }
}

-(NSString *) performSafeAccessor:(SEL)accessorSelector onElement:(TTNativeElement *)elem withArgs:(NSMutableDictionary *)args
{
  [elem tt_safePerformSelectorOnMainThread:accessorSelector withObject:args];
  return [args objectForKey:@"return"];
}

- (NSString*) getLabel:(TTElement *) elem
{
  if ([elem isKindOfClass:[TTNativeButtonElement class]])
  {
    return [elem text];
  }
  if ([elem isKindOfClass:[UILabel class]])
  {
    return [elem attribute:@"text"];
  }
  
  return nil;
}

- (IBAction) pageGroupUIEventTriggered:(id)sender
{
  NSValue *touchPageGroupControlsKey = [NSValue valueWithNonretainedObject:sender];
  MPTouchPageGroup *pageGroup = [touchPageGroupControls objectForKey:touchPageGroupControlsKey];
  
  NSString *outputValue = [self getOutput:pageGroup.extract.element locator:[pageGroup.extract.locator serializeShort] command:pageGroup.extract.accessor propertyName:pageGroup.extract.propertyName];
  
  MPLogDebug(@"pageGroupUIEventTriggered, getOutput extract: %@, outputValue: %@", pageGroup.extract, outputValue);
  MPLogDebug(@"pageGroupUIEventTriggered, pageGroup.name: %@, pageGroup.index: %ld, outputValue: %@", pageGroup.name, (long)pageGroup.index, outputValue);
  
  if (outputValue)
  {
    // Display HUD
    NSString* labelText = [NSString stringWithFormat:@"%@ on %@",pageGroup.action.name, [pageGroup.action.locator serializeShort]];
    [self displayHUD:labelText withDescriptionLabel:[NSString stringWithFormat:@"PageGroup set with value: %@", outputValue]];
    
    [MPulse sharedInstance].viewGroup = outputValue;
    MPLogDebug(@"MPTouchHandlerThread, touchPageGroup: %@", [MPulse sharedInstance].viewGroup);
    pageGroup.pageGroupValue = outputValue;
  }
}

- (IBAction) metricUIEventTriggered:(id)sender
{
  NSValue *touchMetricControlsKey = [NSValue valueWithNonretainedObject:sender];
  MPTouchMetric *metric = [touchMetricControls objectForKey:touchMetricControlsKey];
  if (metric.pageGroup == nil || [self isEqualToCurrentPageGroup:metric.pageGroup])
  {
    NSString *outputValue = nil;
    if (metric.extract.fixedValue != nil)
    {
      outputValue = metric.extract.fixedValue;
      MPLogInfo(@"metricUIControlEventTriggered, extractFixedValue: %@, outputValue: %@", metric.extract.fixedValue, outputValue);
    }
    else if (metric.extract.accessor != nil && metric.extract.locator != nil)
    {
      outputValue = [self getOutput:metric.extract.element locator:[metric.extract.locator serializeShort] command:metric.extract.accessor propertyName:metric.extract.propertyName];
      MPLogInfo(@"metricUIControlEventTriggered, getOutput extractLocator: %@, extract: %@, outputValue: %@", [metric.extract.locator serializeShort], metric.extract.accessor, outputValue);
    }
    MPLogInfo(@"metricUIControlEventTriggered, metric.name: %@, metric.index: %ld, outputValue: %@", metric.name, (long)metric.index, outputValue);
    
    NSNumber *outputValueNumber = [outputValue mp_numberValue:metric.dataType];
    if (outputValueNumber)
    {
      // Display HUD
      NSString* labelText = [NSString stringWithFormat:@"%@ on %@",metric.action.name, [metric.action.locator serializeShort]];
      [self displayHUD:labelText withDescriptionLabel:[NSString stringWithFormat:@"Beacon sent for \"%@\" with value: %@", metric.extract, outputValue]];

      [[MPApiCustomMetricBeacon alloc] initWithMetricIndex:metric.index andValue:outputValueNumber];
    }
  }
}

- (void) displayHUD:(NSString*) labelText withDescriptionLabel:(NSString*) descriptionText
{
  // Check if HUD is enabled in MPConfig and HUD display duration is more than zero seconds.
  if (![[MPConfig sharedInstance] isHUDEnabled] || [[MPConfig sharedInstance] HUDDisplayDuration] <= 0)
  {
    MPLogDebug(@"Not Displaying HUD -> enabled: %@, color: %@, duration: %f", [[MPConfig sharedInstance] isHUDEnabled] ? @"YES":@"NO", [[MPConfig sharedInstance] HUDColor], [[MPConfig sharedInstance] HUDDisplayDuration]);
    return;
  }
  
  dispatch_queue_t dispatchQueue = dispatch_queue_create("com.soasta.mpulse.boomerang.MPTouchHandler.DisplayBoomerangHUD", NULL);
  dispatch_async(dispatchQueue, ^{
    
    MPLogDebug(@"Displaying HUD for %@ with description %@", labelText, descriptionText);

    // Set HUD Color
    [[TTAutomationHud instance] setColor:[[MPConfig sharedInstance] HUDColor]];
  
    // Display HUD
    [TTAutomationHud newAction];
    [TTAutomationHud displayBoomerangHUD:labelText withDescriptionText:descriptionText];
  
    // Display the HUD for a pre-defined many number of seconds.
    [NSThread sleepForTimeInterval:[[MPConfig sharedInstance] HUDDisplayDuration]];
    
    // Hide HUD
    [TTAutomationHud hide];
    [TTAutomationHud endAction];
  });
}

- (IBAction) timerStartUIControlEventTriggered:(id)sender
{
  NSValue *timerKey = [NSValue valueWithNonretainedObject:sender];
  MPTouchTimer *timer = [touchTimers objectForKey:timerKey];
  if (timer != nil)
  {
    if (timer.pageGroup == nil || [self isEqualToCurrentPageGroup:timer.pageGroup])
    {
      MPApiCustomTimerBeacon *beacon = [timer beacon];

      if (beacon == nil || [beacon hasTimerStarted])
      {
        return;
      }
      
      // Display HUD
      [self displayHUD:[NSString stringWithFormat:@"\"%@\" timer started.", [timer name]] withDescriptionLabel:@""];
      
      // Start the timer
      [beacon startTimer];
    }
  }
}

- (IBAction) timerEndUIControlEventTriggered:(id)sender
{
  NSValue *timerKey = [NSValue valueWithNonretainedObject:sender];
  MPTouchTimer *timer = [touchTimers objectForKey:timerKey];
  if (timer != nil)
  {
    if (timer.pageGroup == nil || [self isEqualToCurrentPageGroup:timer.pageGroup])
    {
      MPApiCustomTimerBeacon *beacon = [timer beacon];
      
      // If timer has not started, we cannot end it.
      if (beacon == nil || ![beacon hasTimerStarted] || [beacon hasTimerEnded])
      {
        return;
      }
      
      // End the timer
      [beacon endTimer];
      
      // Display HUD
      NSString* labelText = [NSString stringWithFormat:@"\"%@\" timer stopped.", [timer name]];
      [self displayHUD:labelText withDescriptionLabel:[NSString stringWithFormat:@"Beacon sent with duration: %d", [beacon timerValue]]];
    }
  }
}

*/

@end
