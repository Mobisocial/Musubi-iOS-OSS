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


#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


@interface NSData (Crypto)

- (NSData *) runAlgorithm:(CCAlgorithm)algo andOptions:(CCOptions)options inMode:(CCOperation) mode withKey:(NSData*)key andIV:(NSData*)iv;
- (NSData *) encryptWithAES128ECBPKCS7WithKey:(NSData*)key;
- (NSData *) encryptWithAES128CBCPKCS7WithKey:(NSData*)key andIV:(NSData*)iv;
- (NSData *) encryptWithAES128CBCZeroPaddedWithKey:(NSData*)key andIV:(NSData*)iv;
- (NSData *) decryptWithAES128ECBPKCS7WithKey:(NSData*)key;
- (NSData *) decryptWithAES128CBCPKCS7WithKey:(NSData*)key andIV:(NSData*)iv;
- (NSData *) decryptWithAES128CBCZeroPaddedWithKey:(NSData *)key andIV:(NSData *)iv;
//- (NSData *) encryptWithRSAECBPKCS1WithKey:(SecKeyRef)key;
+ (NSData *) generateSecureRandomKeyOf: (int) bits;
//- (NSData *) signatureForKey:(SecKeyRef) key;
//- (BOOL) verifySignature: (NSData*) sig withKey: (SecKeyRef) key ;
- (NSData*) sha1Digest;
- (NSData*) sha1HashWithLength: (int) length;
- (NSData*) sha256Digest;
- (NSData*) sha256HashWithLength: (int) length;
- (NSString*) hex;

@end
