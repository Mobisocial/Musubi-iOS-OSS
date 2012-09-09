/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */



#import "GpsScanner.h"
#import "GridHandler.h"
#import "NSData+Base64.h"
#import "NSData+Crypto.h"
#import "NearbyFeed.h"

@implementation GpsScanner
- (void)scanForNearbyWithPassword:(NSString*)password onSuccess:(void(^)(NSArray*))success onFail:(void(^)(NSError*))fail
{
    if(!password)
        password = @"";
    [self lookupAndCall:^(CLLocation *location) {
        
        double lat = location.coordinate.latitude;
        double lng = location.coordinate.longitude;
        
        NSLog(@"%f, %f", lat, lng);
        
        NSArray* coords = [GridHandler hexTilesForSizeInFeet:5280 / 2 atLatitude:lat andLongitude:lng];
        NSLog(@"coords, %@", coords);
        
        NSMutableArray* enc_coords = [NSMutableArray array];
        for(NSNumber* coord in coords) {
            NSData* partial_coord = [[@"sadsalt193s" stringByAppendingString:password] dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableData* raw_coord = [NSMutableData data];
            long long local_coord = CFSwapInt64HostToBig(coord.longLongValue);
            [raw_coord appendBytes:&local_coord length:8];
            [raw_coord appendData:partial_coord];
            [enc_coords addObject:[[[raw_coord sha256Digest] encodeBase64] stringByAppendingString:@"\n"]];
        }
        NSLog(@"buckets, %@", enc_coords);
        
        NSError* error = nil;
        NSData* enc_ser_descriptor = [NSJSONSerialization dataWithJSONObject:enc_coords options:0 error:&error];
        if(!enc_ser_descriptor) {
            NSLog(@"FAiled to encode encrypted nearby feed descriptor %@", error);
            fail(error);
            return;
        }
        
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://bumblebee.musubi.us:6253/nearbyapi/0/findgroup"]];
        request.HTTPMethod = @"POST";
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = enc_ser_descriptor;
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *resp, NSData *data, NSError *error) 
         {
             NSHTTPURLResponse* response = (NSHTTPURLResponse*)resp;
             if(error) {
                 fail(error);
                 return;
             }
             if(response.statusCode < 200 || response.statusCode >= 300) {
                 error = [NSError errorWithDomain:@"Failed to publish gps, bad status code" code:-1 userInfo:nil];
                 fail(error);
                 return;
             }
             NSArray* groupsJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
             if(!groupsJSON) {
                 fail(error);
                 return;
             }
             NSMutableSet* dupes = [NSMutableSet set];
             NSLog(@"found %d groups", groupsJSON.count);
             NSMutableArray* nearby = [NSMutableArray array];
             for(NSString* s_enc_data in groupsJSON) {
                 NSData* enc_data = [s_enc_data decodeBase64];
                 NSData* key = [[[@"happysalt621" stringByAppendingString:password] dataUsingEncoding:NSUTF8StringEncoding] sha256Digest];
                 NSData* iv = [enc_data subdataWithRange:NSMakeRange(0, 16)];
                 enc_data = [enc_data subdataWithRange:NSMakeRange(16, enc_data.length - 16)];
                 
                 NSData* data = [enc_data decryptWithAES128CBCPKCS7WithKey:key andIV:iv];
                 if(!data) {
                     NSLog(@"Failed to decode group descriptor");
                     continue;
                 }
                 NSDictionary* group = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                 if(!group) {
                     NSLog(@"Failed to parse group descriptor %@", error);
                     continue;
                 }
                 
                 NearbyFeed* feed = [[NearbyFeed alloc] initWithJSON:group];
                 if(!feed.groupName || !feed.groupCapability || !feed.sharerName || !feed.sharerHash) {
                     NSLog(@"Group descriptor missing fields %@", feed);
                     continue;
                 }
                 NSMutableData* dupe_key = [NSMutableData dataWithData:feed.sharerHash];
                 [dupe_key appendData:feed.groupCapability];
                 if([dupes containsObject:dupe_key]) 
                     continue;
                 [dupes addObject:dupe_key];
                 [nearby addObject:feed];
             }
            success(nearby);
         }];
        
    } orFail:^(NSError *error) {
        fail(error);
    }];
}

@end
