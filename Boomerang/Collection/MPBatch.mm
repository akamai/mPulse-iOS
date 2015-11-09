//
//  MPBatch.m
//  Boomerang
//
//  Created by Matthew Solnit on 4/22/14.
//  Copyright (c) 2014 SOASTA. All rights reserved.
//

#import "MPBatch.h"
#import "MPBatchRecord.h"
#import "MPBucketUtility.h"
#import "MPConfig.h"
#import "MPDemographics.h"
#import "MPSession.h"
#import "NSString+MPExtensions.h"
#import "MPulse.h"
#import "ClientBeaconBatch.pb.h"

@implementation MPBatch
{
  NSDictionary* records;
}

static NSString* BEACON_TYPE = @"iOS";
static NSString* MANUFACTURER = @"Apple";

+(id) initWithRecords:(NSDictionary*)records
{
  MPBatch* batch = [[MPBatch alloc] init];
  
  if (batch != nil)
  {
    batch->records = records;
  }
  
  return batch;
}

-(NSData*) serialize
{
  client_beacon_batch::ClientBeaconBatch protobufBatch;

  // These should all come from config.
  MPConfig *config = [MPConfig sharedInstance];
  protobufBatch.set_boomerang_version([BOOMERANG_VERSION UTF8String]);
  protobufBatch.set_api_key([[config APIKey] UTF8String]);

  MPDemographics* demographics = [MPDemographics sharedInstance];
  
  // These should all come from demographics.
  protobufBatch.set_manufacturer([MANUFACTURER UTF8String]);
  protobufBatch.set_device([[demographics getDeviceModel] UTF8String]);
  protobufBatch.set_type([[demographics getDeviceType] UTF8String]);
  protobufBatch.set_os([[demographics getOSVersion] UTF8String]);
  
  // Set ISP/Carrier Name only if its available
  NSString *carrierName = [demographics getCarrierName];
  if (carrierName != nil)
  {
    protobufBatch.set_isp([carrierName UTF8String]);
  }
  
  protobufBatch.set_connection_type([[demographics getConnectionType] UTF8String]);
  protobufBatch.set_site_version([[demographics getApplicationVersion] UTF8String]);
  
  // Only set latitude and longitude if the values are available
  float latitude = [demographics getLatitude];
  float longitude = [demographics getLongitude];
  if (latitude != 0 && longitude != 0)
  {
    protobufBatch.set_latitude(latitude);
    protobufBatch.set_longitude(longitude);
  }

  client_beacon_batch::ClientBeaconBatch_SessionInfo* protobufSession = [self serializeSession];
  protobufBatch.set_allocated_session(protobufSession);

  NSEnumerator* recordEnumerator = [records keyEnumerator];
  id key;

  while ((key = [recordEnumerator nextObject]) != nil)
  {
    MPBatchRecord* record = [records objectForKey:key];

    ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord* protobufRecord = protobufBatch.add_records();

    protobufRecord->set_timestamp(record.timestamp);
    if (record.networkErrorCode != 0)
    {
      protobufRecord->set_network_error_code(record.networkErrorCode);
    }
    if (record.abTest != nil)
    {
      protobufRecord->set_ab_test([record.abTest UTF8String]);
    }
    if (record.pageGroup != nil)
    {
      protobufRecord->set_page_group([record.pageGroup UTF8String]);
    }
    if (record.url != nil)
    {
      protobufRecord->set_url([record.url UTF8String]);
    }
    if (record.customDimensions != nil)
    {
      NSArray *customDimensions = record.customDimensions;
      for (int d = 0; d < 10; d++)
      {
        NSString *dimensionValue = @"";
        if ([customDimensions objectAtIndex:d] != nil)
        {
          dimensionValue = [customDimensions objectAtIndex:d];
        }
        protobufRecord->add_custom_dimensions([dimensionValue UTF8String]);
      }
    }
    
    protobufRecord->set_beacon_type([BEACON_TYPE UTF8String]);

    if (record.networkRequestTimer != nil)
    {
      // Initialize the container for all network data.
      ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_NetworkTimers* protobufNetworkTimers = new ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_NetworkTimers();

      // Serialize the "total request duration" timer.
      ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData* protobufRequestDurationTimerData = [self serializeTimerData:record.networkRequestTimer];
      protobufNetworkTimers->set_allocated_request_duration_timer(protobufRequestDurationTimerData);

      // Serialize the DNS timer, if any.
      if (record.dnsTimer != nil)
      {
        ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData* protobufDNSTimerData = [self serializeTimerData:record.dnsTimer];
        protobufNetworkTimers->set_allocated_dns_timer(protobufDNSTimerData);
      }
      
      // Serialize the TCP timer, if any.
      if (record.tcpHandshakeTimer != nil)
      {
        ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData* protobufTCPTimerData = [self serializeTimerData:record.tcpHandshakeTimer];
        protobufNetworkTimers->set_allocated_tcp_timer(protobufTCPTimerData);
      }
      
      // Serialize the SSL timer, if any.
      if (record.sslHandshakeTimer != nil)
      {
        ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData* protobufSSLTimerData = [self serializeTimerData:record.sslHandshakeTimer];
        protobufNetworkTimers->set_allocated_ssl_timer(protobufSSLTimerData);
      }
      
      // Serialize the TTFB timer, if any.
      if (record.timeToFirstByteTimer != nil)
      {
        ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData* protobufTTFBTimerData = [self serializeTimerData:record.timeToFirstByteTimer];
        protobufNetworkTimers->set_allocated_time_to_first_byte_timer(protobufTTFBTimerData);
      }
      
      // Serialize the TTLB timer, if any.
      if (record.timeToLastByteTimer != nil)
      {
        ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData* protobufTTLBTimerData = [self serializeTimerData:record.timeToLastByteTimer];
        protobufNetworkTimers->set_allocated_time_to_last_byte_timer( protobufTTLBTimerData);
      }

      protobufRecord->set_allocated_network_timers(protobufNetworkTimers);
    }

    if ([record hasCustomTimers])
    {
      NSArray* customTimers = [record customTimerArray];

      for (int i = 0; i < [customTimers count]; i++)
      {
        MPTimerData* timerData = [customTimers objectAtIndex:i];

        ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData* protobufTimerData = protobufRecord->add_custom_timers();
        [self serializeTimerData:timerData to:protobufTimerData];
      }
    }

    if ([record hasCustomMetrics])
    {
      NSArray* customMetrics = [record customMetricArray];

      for (int i = 0; i < [customMetrics count]; i++)
      {
        NSNumber* metricValue = [customMetrics objectAtIndex:i];
        protobufRecord->add_custom_metrics(metricValue.longLongValue);
      }
    }

    protobufRecord->set_beacon_total(record.totalBeacons);
    protobufRecord->set_crashes_total(record.totalCrashes);
    protobufRecord->set_installs_total(record.totalInstalls);
  }

  // Serialize the batch object to binary (Protocol Buffers format).
  //
  // Note that the batch can contain histogram byte arrays that were
  // allocated using malloc().  We do *not* free them, because the C++
  // destructor already takes care of it.
  std::string serializedBytes = protobufBatch.SerializeAsString();

  NSMutableData* data = [NSMutableData dataWithBytes:serializedBytes.c_str() length:serializedBytes.size()];
  return data;
}

-(::client_beacon_batch::ClientBeaconBatch_SessionInfo*) serializeSession
{
  MPSession* session = [MPSession sharedInstance];
  
  if (session.ID == nil || !session.started)
  {
    MPLogDebug(@"No session (ID: %@, started: %d)", session.ID, session.started);
    return NULL;
  }
  else
  {
    MPLogDebug(@"Serializing session (ID: %@, started: %d)", session.ID, session.started);

    ::client_beacon_batch::ClientBeaconBatch_SessionInfo* protobufSession = new ::client_beacon_batch::ClientBeaconBatch_SessionInfo();

    protobufSession->set_id([session.ID UTF8String]);
    protobufSession->set_start_time([session.startTime timeIntervalSince1970] * 1000);
    protobufSession->set_end_time([session.lastBeaconTime timeIntervalSince1970] * 1000);
    protobufSession->set_network_request_count_total(session.totalNetworkRequestCount);
    protobufSession->set_network_request_duration_total(session.totalNetworkRequestDuration);
  
    return protobufSession;
  }
}

-(::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData*) serializeTimerData:(MPTimerData*)localTimerData
{
  ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData* protobufTimerData = new ::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData();

  [self serializeTimerData:localTimerData to:protobufTimerData];

  return protobufTimerData;
}

-(void) serializeTimerData:(MPTimerData*)localTimerData
                        to:(::client_beacon_batch::ClientBeaconBatch_ClientBeaconBatchRecord_TimerData*)protobufTimerData
{
  protobufTimerData->set_total(localTimerData.count);
  protobufTimerData->set_min(localTimerData.min);
  protobufTimerData->set_max(localTimerData.max);
  protobufTimerData->set_sum(localTimerData.sum);
  protobufTimerData->set_sum_sq(localTimerData.sumOfSquares);
  
  // There should always be a histogram, but just in case...
  if ([localTimerData hasHistogram])
  {
    // Extract the histogram in array form.
    int* histogram = [localTimerData histogramArray];
    
    // Serialize the integer array to binary.
    int compressedLength;
    Byte* compressedHistogram = [MPBatch histogramIntArrayToBinary:histogram
                                                        withLength:NUM_BUCKETS
                                                         andFormat:(Byte)1
                                                      outputLength:&compressedLength];
    
    // MPLogDebug(@"Actual histogram: %@", [NSString mp_stringWithIntArray:histogram andLength:NUM_BUCKETS]);
    // MPLogDebug(@"Compressed histogram: %@", [NSString mp_stringWithByteArray:compressedHistogram andLength:compressedLength]);
    
    // Convert the binary to the format that Protocol Buffers expects.
    std::string s(reinterpret_cast<char const*>(compressedHistogram), compressedLength);
    protobufTimerData->set_histogram(s);
    
    // Free the binary histogram (the Protocol Buffers object is now using a copy).
    free(compressedHistogram);
  }
}

/**
 * Ported from WebApplications/Concerto/src/com/soasta/resultsservice/persistence/hibernate/RumHistogramUserType.java.
 *
 * It is the responsibility of the caller to free the byte array when finished.
 */
+ (Byte*) histogramIntArrayToBinary:(int*)values withLength:(int)histogramLength andFormat:(Byte)format outputLength:(int*)outputLength
{
  Byte *data = NULL;
  int idx = 0;
  int prevIdx = 0;
  int offset = 0;
  
  switch (format) // this format is not the same as the binary format flag of the second byte
  {
    case 1: // short, sparse
      offset = 0;
      idx++; // skip the header byte
      data = (Byte*)calloc((histogramLength * 3) + 1, sizeof(Byte)); // each entry is 3 bytes plus a header byte
      for (int i = 0; i < histogramLength ; i++)
      {
        if (values[i] == 0)
        {
          continue;
        }
        else if (values[i] > 0xFFFF)
        {
          MPLogDebug(@"Detected histogram element value overflow > 64k. Capping the value at 64k.");
          values[i] = 0xFFFF; // this will bit shift as Short.MAX_VALUE unsigned
        }
        
        data[prevIdx] = (Byte) (i - offset);    // set the delta byte to the index minus the offset of the last delta
        prevIdx = idx++;                        // update the prev index to the current index
        data[idx++] = (Byte) (values[i] >> 8);  // set the upper short value byte
        data[idx++] = (Byte) values[i];         // set the lower short value byte
        offset = i;                             // set the new offset to the current index
      }
      if (idx == 1) // all zero - no data
      {
        return NULL;
      }
      data[prevIdx] = 0; // zero out the last sparse delta byte
      data[0] |= 1 << 7; // set the sparse format bit of the first byte
      break;
      
    case 2: // int, sparse
    {
      offset = 0;
      idx++; // skip the header byte
      idx++; // skip the second header byte
      data = (Byte*)calloc((histogramLength * 5) + 2, sizeof(Byte)); // each entry is 5 bytes plus two header bytes
      for (int i = 0; i < histogramLength ; i++)
      {
        if (values[i] == 0)
        {
          continue;
        }
        // FIXME: no overflow check
        data[prevIdx] = (Byte) (i - offset);    // set the delta byte to the index minus the offset of the last delta
        prevIdx = idx++;                        // update the prev index to the current index
        data[idx++] = (Byte) (values[i] >> 24);
        data[idx++] = (Byte) (values[i] >> 16);
        data[idx++] = (Byte) (values[i] >> 8);  // set the upper short value byte
        data[idx++] = (Byte) values[i];         // set the lower short value byte
        offset = i;                             // set the new offset to the current index
      }
      if (idx == 2) // all zero - no data
      {
        return NULL;
      }
      data[prevIdx] = 0; // zero out the last sparse delta byte
      data[0] |= 1 << 7; // set the sparse format bit of the first byte
      data[1] = 1; // set the 4 byte width flag on the second marker byte
      data[1] |= 1 << 7; // set the special format flag on the second marker byte
      break;
    }
    case 0: // int32, dense
      // same algorithm as above
    {
      data = (Byte*)calloc(histogramLength * 5, sizeof(Byte));
      for (int i = 0; i < histogramLength ; i++)
      {
        if (values[i] == 0)
        {
          idx += 5;
          continue;
        }
        // this is the offset from the start bucket between this and the previous bucket index, plus one to reference the
        // upper value byte
        data[prevIdx] = (Byte) (i - offset);
        prevIdx = idx++;
        data[idx++] = (Byte) (values[i] >> 24);
        data[idx++] = (Byte) (values[i] >> 16);
        data[idx++] = (Byte) (values[i] >> 8);
        data[idx++] = (Byte) values[i];
        offset = i;
      }
      data[prevIdx] = (Byte) 0xFF; // set the last entry to indicate set w/ no next-delta
      for (int i = 0; i < histogramLength ; i++)
      {
        if (values[i] != 0)
        {
          data[0] = (Byte) i;
          break;
        }
      }
      data[0] &= (Byte) 0x7F; // set the dense format bit of the first byte
      break;
    }
  }

  Byte* compactData = (Byte*)malloc(idx);
  for (int i=0; i < idx; i++)
  {
    compactData[i] = data[i];
  }

  // Now that we've created our compacted array, free the original.
  free(data);

  // This is only in the Objective-C version (we need a way to tell the caller how large the compressed version is):
  *outputLength = idx;

  return compactData;
}

/**
 * Ported from WebApplications/Concerto/src/com/soasta/resultsservice/persistence/hibernate/RumHistogramUserType.java.
 *
 * It is the responsibility of the caller to free the int array when finished.
 */
+ (int*) binaryHistogramToIntArray:(Byte*)data withLength:(int)length
{
  if (data == NULL)
  {
    return NULL;
  }
  else
  {
    int* values = (int*)calloc(NUM_BUCKETS, sizeof(int));
    int ptr = 0;
    int idx = 0;
    int offset = 0;
    if ((data[0] & 128) == 128) // sparse format
    {
      int format = 0;
      idx = (data[ptr++] & (Byte) 0x7F); // header byte sets the first index
      if ((data[ptr] & 128) == 128) // special format byte
      {
        format = data[ptr] & (Byte) 0x7F;
        ptr++;
      }
      offset = idx;
      switch (format)
      {
        case 0: // 2 byte fixed
          do
          {
            offset += data[ptr++] & (Byte) 0x7F; // entry index delta

            // This line of Java code causes a warning from clang: "Multiple unsequenced modifications to 'ptr'",
            // meaning that the order of evaluation is not guaranteed and can cause unpredictable results:
            //
            // values[idx++] = (data[ptr++] << 8 | data[ptr++]) & 0xFFFF;

            // Objective-C version:
            Byte data1 = data[ptr++];
            Byte data2 = data[ptr++];
            values[idx++] = (data1 << 8 | data2) & 0xFFFF;
            
            idx = offset;
          }
          while (ptr < length);
          break;
        case 1: // 4 byte fixed
          do
          {
            offset += data[ptr++] & (Byte) 0x7F; // entry index delta

            // This line of Java code causes a warning from clang: "Multiple unsequenced modifications to 'ptr'",
            // meaning that the order of evaluation is not guaranteed and can cause unpredictable results:
            //
            // values[idx++] = data[ptr++] << 24 | (data[ptr++] & 0xFF) << 16 | (data[ptr++] & 0xFF) << 8 | (data[ptr++] & 0xFF);
            
            // Objective-C version:
            Byte data1 = data[ptr++];
            Byte data2 = data[ptr++];
            Byte data3 = data[ptr++];
            Byte data4 = data[ptr++];
            values[idx++] = data1 << 24 | (data2 & 0xFF) << 16 | (data3 & 0xFF) << 8 | (data4 & 0xFF);

            idx = offset;
          }
          while (ptr < length);
          break;
          
        case 2: // 2 byte and 4 byte variable
          break;
        case 3: // 4 byte and 8 byte variable
          break;
      }
    }
    else
      // dense int32 format
    {
      do
      {
        ptr++; // skip the delta byte
        
        // This line of Java code causes a warning from clang: "Multiple unsequenced modifications to 'ptr'",
        // meaning that the order of evaluation is not guaranteed and can cause unpredictable results:
        //
        // values[idx++] = data[ptr++] << 24 | (data[ptr++] & 0xFF) << 16 | (data[ptr++] & 0xFF) << 8 | (data[ptr++] & 0xFF);

        // Objective-C version:
        Byte data1 = data[ptr++];
        Byte data2 = data[ptr++];
        Byte data3 = data[ptr++];
        Byte data4 = data[ptr++];
        values[idx++] = data1 << 24 | (data2 & 0xFF) << 16 | (data3 & 0xFF) << 8 | (data4 & 0xFF);
      }
      while (ptr < length);
    }
    return values;
  }
}

@end
