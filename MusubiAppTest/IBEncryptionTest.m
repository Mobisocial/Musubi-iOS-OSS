//
//  IBEncryptionTest.m
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IBEncryptionTest.h"
#import "NSData+Crypto.h"

#include <stdio.h>
#include <openssl/sha.h>
#include <string.h>
#include "ibesig.h"
#include "pbc.h"

@implementation IBEncryptionTest


- (void)testIBESig
{
    printf("generating parameters\n");
    char* mk_data = NULL;
    int mk_length = 0;
    ibesig_public_parameters* pp = ibesig_global_public_parameters(&mk_data, &mk_length);
    
    printf("serializing and deserializing\n");
    char* pp_data = NULL;
    int pp_length = 0;
    ibesig_serialize_parameters(&pp_data, &pp_length, pp);
    ibesig_clear_public_parameters(pp);
    pp = ibesig_unserialize_parameters(pp_data, pp_length);
    
    element_t mk;
    element_init_Zr(mk, pp->pairing);
    element_from_bytes(mk, (unsigned char*)mk_data);
    element_printf("master key = %B\n", mk);
    element_clear(mk);
    
    char* uid_data = "tpurtell@stanford.edu";
    int uid_length = strlen(uid_data);
    
    printf("computing personal key\n");
    char* uk_data = NULL;
    int uk_length = 0;
    ibesig_keygen(&uk_data, &uk_length, pp, mk_data, mk_length, uid_data, uid_length);
    
    //deserialize the user secret
    element_t g_huid;
    element_init_G1(g_huid, pp->pairing);
    element_from_bytes_compressed(g_huid, (unsigned char*)uk_data);
    element_printf("uk = %B\n", g_huid);
    element_clear(g_huid);
    
    char* message_hash_data = "01234567890123456789012345678901";
    int message_hash_length = SHA256_DIGEST_LENGTH;
    
    printf("computing a signature\n");
    char* sig_data = NULL;
    int sig_length = 0;
    ibesig_sign(&sig_data, &sig_length, pp, uk_data, uk_length, uid_data, uid_length, message_hash_data, message_hash_length);
    
    element_t u;
    element_init_G1(u, pp->pairing);
    element_from_bytes_compressed(u, (unsigned char*)sig_data);
    element_t v;
    element_init_Zr(v, pp->pairing);
    element_from_bytes(v, (unsigned char*)sig_data + element_length_in_bytes_compressed(u));
    element_printf("sig u = %B\n", u);
    element_printf("sig v = %B\n", v);
    element_clear(u);
    element_clear(v);
    
    printf("verifying a signature\n");
    int result = ibesig_verify(pp, sig_data, sig_length, uid_data, uid_length, message_hash_data, message_hash_length);
    printf("result = %d\n", result);
    
    printf("verifying a bad signature\n");
    sig_data[sizeof(void*)]++;
    result = ibesig_verify(pp, sig_data, sig_length, uid_data, uid_length, message_hash_data, message_hash_length);
    printf("result = %d\n", result);
    
    ibesig_clear_public_parameters(pp);
    free(mk_data);
    free(uk_data);
    free(sig_data);
}

- (void)testEncryption
{
    //    STFail(@"Unit tests are not implemented yet in MusubiAppTest");
    
    IBEncryptionScheme* scheme = [[IBEncryptionScheme alloc] init];
    IBEncryptionMasterKey* mk = [scheme masterKey];
    
    IBEncryptionScheme* userScheme = [[IBEncryptionScheme alloc] initWithParameters: [scheme parameters]];
    IBEncryptionScheme* loadedScheme = [[IBEncryptionScheme alloc] initWithParameters: [scheme parameters] andMasterKey:mk];
    
    NSData* hashedKey = [@"wbult@stanford.edu" dataUsingEncoding:NSUTF8StringEncoding];
    IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail hashedKey:hashedKey temporalFrame:1];
    
    IBEncryptionUserKey* userKey = [loadedScheme userKeyWithIdentity:ident];
    IBEncryptionConversationKey* convKey = [userScheme randomConversationKeyWithIdentity:ident];
    
    NSData* key = [userScheme decryptConversationKey:convKey withUserKey:userKey];
    STAssertTrue([key isEqualToData:[convKey raw]], @"encrypt => decrypt (right identity) : failed to match conversation key");
    
    NSData* otherHashedKey = [@"stfan@stanford.edu" dataUsingEncoding:NSUTF8StringEncoding];
    IBEncryptionIdentity* otherIdent = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail hashedKey:otherHashedKey temporalFrame:1];
    IBEncryptionUserKey* otherUserKey = [loadedScheme userKeyWithIdentity:otherIdent];
    
    key = [userScheme decryptConversationKey:convKey withUserKey:otherUserKey];
    STAssertFalse([key isEqualToData:[convKey raw]], @"encrypt => decrypt (wrong identity): failed to mismatch conversation key");
}

- (void)testSignature
{
    IBSignatureScheme* scheme = [[IBSignatureScheme alloc] init];
    IBEncryptionMasterKey* mk = [scheme masterKey];
    
    IBSignatureScheme* userScheme = [[IBSignatureScheme alloc] initWithParameters: [scheme parameters]];
    IBSignatureScheme* loadedScheme = [[IBSignatureScheme alloc] initWithParameters: [scheme parameters] andMasterKey:mk];
    
    NSData* hashedKey = [@"wbult@stanford.edu" dataUsingEncoding:NSUTF8StringEncoding];
    IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail hashedKey:hashedKey temporalFrame:1];
    
    NSData* hash = [NSData dataWithBytes:"01234567890123456789012345678901" length:SHA256_DIGEST_LENGTH];
    IBSignatureUserKey* userKey = [loadedScheme userKeyWithIdentity:ident];
    
    NSData* signature = [userScheme signHash: hash withUserKey: userKey andIdentity: ident];
    BOOL ok = [userScheme verifySignature: signature forHash: hash withIdentity: ident];
    
    STAssertTrue(ok, @"sign => verify (right identity) : failed to match");
    
    //destroy signature
    ((char*)[signature bytes])[9]++;
    ok = [userScheme verifySignature: signature forHash: hash withIdentity: ident];
    STAssertFalse(ok, @"sign => verify (wrong identity) : failed to mismatch");
}

- (void) testIdentity
{
    IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIdentityTypeEmail principal:@"wbult@stanford.edu" temporalFrame:12345];
    
    NSData* key = [ident key];
    NSLog(@"Hashed: %@", [ident hashed]);
    NSLog(@"Key: %@", key);
    
    IBEncryptionIdentity* ident2 = [[IBEncryptionIdentity alloc] initWithKey: key];
    
    STAssertTrue([ident authority] == [ident2 authority], @"Authority mismatch");
    STAssertTrue([[ident hashed] isEqualToData: [ident2 hashed]], @"Hash mismatch");
    STAssertTrue([ident temporalFrame] == [ident2 temporalFrame], @"Temporal Frame mismatch");
    STAssertTrue([[ident key] isEqualToData: [ident2 key]], @"Key mismatch");
}

- (void) testAES
{
    NSData* data = [NSData generateSecureRandomKeyOf:128];
    NSData* iv = [NSData generateSecureRandomKeyOf:128];
    NSData* key = [NSData generateSecureRandomKeyOf:128];
    
    NSData* encrypted = [data encryptWithAES128CBCZeroPaddedWithKey:key andIV:iv];
    NSData* decrypted = [encrypted decryptWithAES128CBCZeroPaddedWithKey:key andIV:iv];
    
    STAssertTrue([decrypted isEqualToData: data], @"Data mismatch");
}

@end
