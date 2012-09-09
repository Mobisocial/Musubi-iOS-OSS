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


#import "bson.h"
#import "Musubi.h"
#import "BSONEncoder.h"
#import "Recipient.h"
#import "Message.h"
#import "Sender.h"
#import "Secret.h"
#import "PreparedObj.h"
#import "MFeed.h"

static void err_handler(const char *errmsg) {
    @throw [NSException exceptionWithName:kMusubiExceptionMessageCorrupted reason:@"Message could not be decoded" userInfo:nil];
}

@implementation BSONEncoder


+ (NSData *)encodeMessage:(Message *)m {
    bson b;
    bson_init(&b);
    
    bson_append_int(&b, "v", m.v);
    
    bson_append_start_object(&b, "s");
    bson_append_binary(&b, "i", 128, [[m.s i] bytes], [[m.s i] length]);
    bson_append_binary(&b, "d", 128, [[m.s d] bytes], [[m.s d] length]);
    bson_append_finish_object(&b);
    
    bson_append_binary(&b, "i", 128, [m.i bytes], [m.i length]);
    bson_append_bool(&b, "l", m.l);
    bson_append_binary(&b, "a", 128, [m.a bytes], [m.a length]);

    bson_append_start_array(&b, "r");
    int i = 0;
    for (Recipient* r in m.r) {
        bson_append_start_object(&b, [[NSString stringWithFormat:@"%ud", i++] UTF8String]);
        bson_append_binary(&b, "i", 128, [r.i bytes], [r.i length]);
        bson_append_binary(&b, "k", 128, [r.k bytes], [r.k length]);
        bson_append_binary(&b, "s", 128, [r.s bytes], [r.s length]);
        bson_append_binary(&b, "d", 128, [r.d bytes], [r.d length]);
        bson_append_finish_object(&b);
    }
    bson_append_finish_array(&b);
    
    bson_append_binary(&b, "d", 128, [m.d bytes], [m.d length]);
    
    bson_finish(&b);
    
    NSData* raw = [NSData dataWithBytes:b.data length:b.dataSize];
    
    bson_destroy(&b);
    
    return raw;
}


+ (Message *)decodeMessage:(NSData *)data {
    set_bson_err_handler(err_handler);
    
    if (data == nil || data.length == 0)
        @throw [NSException exceptionWithName:@"DecodeError" reason:@"No data in message" userInfo:nil];
    
    bson b, s, r;
    bson_iterator iter, iter2, iter3;
    bson_init_finished_data(&b, (char*)[data bytes]);
    
    
    Message* m = [[Message alloc] init];
    
    
    bson_find(&iter, &b, "v");
    [m setV: bson_iterator_int(&iter)];
    
    bson_find(&iter, &b, "s");
    
    // Read sender
    bson_iterator_subobject(&iter, &s);
    
    Sender* sender = [[Sender alloc] init];
    [m setS: sender];
    bson_find(&iter2, &s, "i");
    [sender setI:[NSData dataWithBytes:bson_iterator_bin_data(&iter2) length:bson_iterator_bin_len(&iter2)]];
    bson_find(&iter2, &s, "d");
    [sender setD:[NSData dataWithBytes:bson_iterator_bin_data(&iter2) length:bson_iterator_bin_len(&iter2)]];
    
    bson_find(&iter, &b, "i");
    [m setI:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    bson_find(&iter, &b, "l");
    [m setL: bson_iterator_bool(&iter)];
    bson_find(&iter, &b, "a");
    [m setA:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    
    bson_find(&iter, &b, "r");
    bson_iterator_subiterator(&iter, &iter2);
    
    NSMutableArray* rcpts = [NSMutableArray array];
    [m setR: rcpts];
    
    while (true) {
        bson_iterator_next(&iter2);
        if (!bson_iterator_more(&iter2))
            break;
        
        bson_iterator_subobject(&iter2, &r);
        
        Recipient* recipient = [[Recipient alloc] init];
        [rcpts addObject: recipient];
        
        bson_find(&iter3, &r, "i");
        [recipient setI:[NSData dataWithBytes:bson_iterator_bin_data(&iter3) length:bson_iterator_bin_len(&iter3)]];
        bson_find(&iter3, &r, "k");
        [recipient setK:[NSData dataWithBytes:bson_iterator_bin_data(&iter3) length:bson_iterator_bin_len(&iter3)]];
        bson_find(&iter3, &r, "s");
        [recipient setS:[NSData dataWithBytes:bson_iterator_bin_data(&iter3) length:bson_iterator_bin_len(&iter3)]];
        bson_find(&iter3, &r, "d");
        [recipient setD:[NSData dataWithBytes:bson_iterator_bin_data(&iter3) length:bson_iterator_bin_len(&iter3)]];
    }
    
    
    bson_find(&iter, &b, "d");
    [m setD:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    
    return m;
}

+ (NSData *)encodeSecret:(Secret *)s {
    bson b;
    bson_init(&b);
    
    bson_append_binary(&b, "h", 128, [s.h bytes], [s.h length]);
    bson_append_long(&b, "q", s.q);
    bson_append_binary(&b, "k", 128, [s.k bytes], [s.k length]);

    bson_finish(&b);
    
    NSData* raw = [NSData dataWithBytes:b.data length:b.dataSize];
    
    bson_destroy(&b);
    
    return raw;
}

+ (Secret *)decodeSecret:(NSData *)data {
    bson b;
    bson_iterator iter;
    bson_init_finished_data(&b, (char*)[data bytes]);

    Secret* s = [[Secret alloc] init];

    bson_find(&iter, &b, "h");
    [s setH:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    
    bson_find(&iter, &b, "q");
    [s setQ: bson_iterator_long(&iter)];
    
    bson_find(&iter, &b, "k");
    [s setK:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    
    return s;
}

+ (NSData *)encodeObj:(PreparedObj *)o {
    bson b;
    bson_init(&b);
    
    if (o.feedType)
        bson_append_string(&b, "feedType", [[BSONEncoder feedTypeToString:o.feedType] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (o.feedCapability)
        bson_append_binary(&b, "feedCapability", 128, [o.feedCapability bytes], [o.feedCapability length]);
    if (o.appId)
        bson_append_string(&b, "appId", [o.appId cStringUsingEncoding:NSUTF8StringEncoding]);
    bson_append_long(&b, "timestamp", o.timestamp);
    if (o.type)
        bson_append_string(&b, "type", [o.type cStringUsingEncoding:NSUTF8StringEncoding]);
    if (o.jsonSrc)
        bson_append_string(&b, "jsonSrc", [o.jsonSrc cStringUsingEncoding:NSUTF8StringEncoding]);
    if (o.raw)
        bson_append_binary(&b, "raw", 128, [o.raw bytes], [o.raw length]);
    if (o.intKey)
        bson_append_int(&b, "intKey", [o.intKey intValue]);
    if (o.stringKey)
        bson_append_string(&b, "stringKey", [o.stringKey cStringUsingEncoding:NSUTF8StringEncoding]);
    
    bson_finish(&b);
    
    NSData* raw = [NSData dataWithBytes:b.data length:b.dataSize];
    
    bson_destroy(&b);
    
    return raw;
}

+ (PreparedObj *)decodeObj:(NSData *)data {
    bson b;
    bson_iterator iter;
    bson_init_finished_data(&b, (char*)[data bytes]);
    
    PreparedObj* o = [[PreparedObj alloc] init];
    int type;
    
    type = bson_find(&iter, &b, "feedType");
    if (type == BSON_STRING)
        [o setFeedType: [BSONEncoder feedTypeFromString:[NSString stringWithCString: bson_iterator_string(&iter) encoding:NSUTF8StringEncoding]]];

    type = bson_find(&iter, &b, "feedCapability");
    if (type == BSON_BINDATA)
        [o setFeedCapability:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];

    type = bson_find(&iter, &b, "appId");
    if (type == BSON_STRING)
        [o setAppId:[NSString stringWithCString:bson_iterator_string(&iter) encoding:NSUTF8StringEncoding]];

    type = bson_find(&iter, &b, "timestamp");
    if (type == BSON_LONG)
        [o setTimestamp: bson_iterator_long(&iter)];
    
    type = bson_find(&iter, &b, "type");
    if (type == BSON_STRING)
        [o setType:[NSString stringWithCString:bson_iterator_string(&iter) encoding:NSUTF8StringEncoding]];
    
    type = bson_find(&iter, &b, "jsonSrc");
    if (type == BSON_STRING)
        [o setJsonSrc:[NSString stringWithCString:bson_iterator_string(&iter) encoding:NSUTF8StringEncoding]];
    
    type = bson_find(&iter, &b, "raw");
    if (type == BSON_BINDATA)
        [o setRaw:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    type = bson_find(&iter, &b, "intKey");
    if (type == BSON_INT) {
        [o setIntKey: [NSNumber numberWithInt:bson_iterator_int(&iter)]];
    }
    type = bson_find(&iter, &b, "stringKey");
    if (type == BSON_STRING) {
        [o setStringKey:[NSString stringWithCString:bson_iterator_string(&iter) encoding:NSUTF8StringEncoding]];
    }
    return o;
}

+ (NSString*) feedTypeToString: (int) type {
    switch (type) {
        case kFeedTypeFixed:
            return @"FIXED";
        case kFeedTypeExpanding:
            return @"EXPANDING";
        case kFeedTypeAsymmetric:
            return @"ASYMMETRIC";
        case kFeedTypeOneTimeUse:
            return @"ONE_TIME_USE";
        default:
            return @"UNKNOWN";
    }    
}

+ (int) feedTypeFromString: (NSString*) type {
    if ([type isEqualToString:@"FIXED"])
        return kFeedTypeFixed;
    if ([type isEqualToString:@"EXPANDING"])
        return kFeedTypeExpanding;
    if ([type isEqualToString:@"ASYMMETRIC"])
        return kFeedTypeAsymmetric;
    if ([type isEqualToString:@"ONE_TIME_USE"])
        return kFeedTypeOneTimeUse;
    
    return kFeedTypeUnknown;
}

@end
