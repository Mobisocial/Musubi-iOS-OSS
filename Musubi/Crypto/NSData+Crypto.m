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


#import "NSData+Crypto.h"

@implementation NSData (Crypto)

+ (NSData *) generateSecureRandomKeyOf: (int) bytes {
    uint8_t key[bytes / sizeof(uint8_t)];
    bzero(key, sizeof(key));
    
    SecRandomCopyBytes (kSecRandomDefault,
                        sizeof(key),
                        key
                        );

    return [NSData dataWithBytes:key length:sizeof(key)];
}

- (NSData *) encryptWithAES128ECBPKCS7WithKey:(NSData*)key {
    return [self runAlgorithm:kCCAlgorithmAES128 andOptions:kCCOptionECBMode|kCCOptionPKCS7Padding inMode:kCCEncrypt withKey:key andIV:nil];
}

- (NSData *) decryptWithAES128ECBPKCS7WithKey:(NSData*)key {
    return [self runAlgorithm:kCCAlgorithmAES128 andOptions:kCCOptionECBMode|kCCOptionPKCS7Padding inMode:kCCDecrypt withKey:key andIV:nil];
}

- (NSData *) encryptWithAES128CBCPKCS7WithKey:(NSData*)key andIV:(NSData*)iv {
    return [self runAlgorithm:kCCAlgorithmAES128 andOptions:kCCOptionPKCS7Padding inMode:kCCEncrypt withKey:key andIV:iv];
}

- (NSData *) decryptWithAES128CBCPKCS7WithKey:(NSData*)key andIV:(NSData*)iv {
    return [self runAlgorithm:kCCAlgorithmAES128 andOptions:kCCOptionPKCS7Padding inMode:kCCDecrypt withKey:key andIV:iv];
}

- (NSData *) encryptWithAES128CBCZeroPaddedWithKey:(NSData *)key andIV:(NSData *)iv {
    return [self runAlgorithm:kCCAlgorithmAES128 andOptions:0 inMode:kCCEncrypt withKey:key andIV:iv];    
}

- (NSData *) decryptWithAES128CBCZeroPaddedWithKey:(NSData *)key andIV:(NSData *)iv {
    return [self runAlgorithm:kCCAlgorithmAES128 andOptions:0 inMode:kCCDecrypt withKey:key andIV:iv];
}
/*

- (BOOL) verifySignature: (NSData*) sig withKey: (SecKeyRef) key {
    OSStatus status = SecKeyRawVerify(key, kSecPaddingPKCS1SHA1, [self bytes], [self length], [sig bytes], [sig length]);
    if(status == noErr) {
        return TRUE;
    } else {
        return FALSE;
    }
}


- (NSData *) signatureForKey:(SecKeyRef) key {
    size_t signatureLen = SecKeyGetBlockSize(key);
    uint8_t* signature = malloc(signatureLen);
    bzero(signature, signatureLen);
    
    OSStatus status = SecKeyRawSign(key, kSecPaddingPKCS1SHA1, [self bytes], [self length], signature, &signatureLen);
    
    if(status == noErr)
    {
        return [NSData dataWithBytesNoCopy:signature length:signatureLen];
    }
    
    free(signature);
    @throw [NSException exceptionWithName:@"Signature failed" reason:[NSString stringWithFormat:@"Signing failed. Return code: %d", status, [self length]] userInfo:nil];
}

- (NSData *)encryptWithRSAECBPKCS1WithKey:(SecKeyRef)key {
    size_t encryptedLength = SecKeyGetBlockSize(key);
    uint8_t* encrypted = malloc(encryptedLength);
        
    OSStatus status = SecKeyEncrypt(key,
                                    kSecPaddingPKCS1, 
                                    [self bytes],
                                    MIN(SecKeyGetBlockSize(key) - 12, [self length]), 
                                    encrypted, 
                                    &encryptedLength);
    if(status == noErr)
    {
        return [NSData dataWithBytesNoCopy:encrypted length:encryptedLength];
    }

    free(encrypted);
    @throw [NSException exceptionWithName:@"EncryptionFailed" reason:[NSString stringWithFormat:@"Encryption failed. Return code: %d, Input size was %d", status, [self length]] userInfo:nil];
}*/

- (NSData*) sha1Digest {
    return [self sha1HashWithLength:CC_SHA1_DIGEST_LENGTH];
}

- (NSDate*) sha1HashWithLength: (int) length{
    unsigned char* hash = malloc(length);
    
    CC_SHA1_CTX ctx;
    CC_SHA1_Init(&ctx);
    CC_SHA1_Update(&ctx, [self bytes], [self length]);
    CC_SHA1_Final(hash, &ctx);
    return [NSData dataWithBytesNoCopy:hash length:length freeWhenDone:YES];
}

- (NSData*) sha256Digest {
    return [self sha256HashWithLength:CC_SHA256_DIGEST_LENGTH];
}

- (NSData*) sha256HashWithLength: (int) length {
    unsigned char* hash = malloc(length);
    
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [self bytes], [self length]);
    CC_SHA256_Final(hash, &ctx);
    return [NSData dataWithBytesNoCopy:hash length:length freeWhenDone:YES];
}

- (NSString*) hex {
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([self length] * 2)];
	const unsigned char *dataBuffer = [self bytes];
	int i;
	for (i = 0; i < [self length]; ++i) {
		[stringBuffer appendFormat:@"%02x", (unsigned long)dataBuffer[i]];
	}
	return [stringBuffer copy];
}


- (NSData *) runAlgorithm:(CCAlgorithm)algo andOptions:(CCOptions)options inMode:(CCOperation) mode withKey:(NSData*)key andIV:(NSData*)iv {
	char keyPtr[[key length]+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
	
	// fetch key data
    memcpy(keyPtr, [key bytes], [key length]);
    
    //See the doc: For block ciphers, the output size will always be less than or 
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = [self length] + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
    
	size_t numBytesProcessed = 0;
	CCCryptorStatus status = CCCrypt(mode, algo, options,
                                          keyPtr, [key length], /* key */
                                          iv != nil ? [iv bytes] : NULL, /* initialization vector */
                                          [self bytes], [self length], /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesProcessed);
	if (status == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:numBytesProcessed freeWhenDone:YES];
	}
    
	free(buffer); //free the buffer;
	return nil;
}


@end