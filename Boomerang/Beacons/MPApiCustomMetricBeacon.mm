//
//  MPApiCustomMetricBeacon.m
//  Boomerang
//
//  Copyright (c) 2015 SOASTA. All rights reserved.
//

#import "MPApiCustomMetricBeacon.h"
#import "MPBeaconCollector.h"
#import "MPConfig.h"
#import "ClientBeaconBatch.pb.h"

@implementation MPApiCustomMetricBeacon

/**
 * Initialize with the specific metric name and value
 * @param metricName Metric name
 * @param value Value
 */
-(id) initWithMetricName:(NSString *)metricName andValue:(NSNumber *)metricValue
{
  if (metricValue == nil)
  {
    return nil;
  }

  MPConfig *config = [MPConfig sharedInstance];

  for (MPConfigMetric *metric in [[config pageParamsConfig] metrics])
  {
    if ([metric.name isEqualToString:metricName])
    {
      return [self initWithMetricIndex:metric.index andValue:metricValue andName:metricName];
    }
  }
      
  // If we reach this point, there was no match.
  return nil;
}

/**
 * Initialize with the specific metric index and value
 * @param metricIndex Metric index
 * @param value Value
 */
-(id) initWithMetricIndex:(NSInteger)metricIndex andValue:(NSNumber *)metricValue andName:(NSString *)metricName
{
  if (metricValue == nil)
  {
    return nil;
  }

  self = [super init];

  if (self)
  {
    _metricName = metricName;
    _metricIndex = metricIndex;
    _metricValue = (int)metricValue.integerValue;

    MPLogDebug(@"Initialized metric beacon: index=%d, value=%d", (int)_metricIndex, _metricValue);

    // add the beacon to the collector
    [[MPBeaconCollector sharedInstance] addBeacon:self];
  }

  return self;
}

/**
 * Gets the beacon type
 */
-(MPBeaconTypeEnum) getBeaconType
{
  return API_CUSTOM_METRIC;
}

/**
 * Serializes the beacon for the Protobuf record
 * @param recordPtr Record
 */
-(void) serialize:(void *)recordPtr
{
  //
  //  message ApiCustomMetricData {
  //    // metric value
  //    optional int32 metric_value = 1;
  //    
  //    // custom metric index
  //    optional int32 metric_index = 2;
  //  }
  //
  
  [super serialize:recordPtr];
  
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord* record
    = (::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord*)recordPtr;
  
  //
  // Api Custom Metric data
  //
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconRecord_ApiCustomMetricData* data
    = record->mutable_api_custom_metric_data();
  
  // metric index
  data->set_metric_index((int)_metricIndex);
  
  // metric index
  data->set_metric_value(_metricValue);
}

@end
