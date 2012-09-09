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
#import "IdentityProvider.h"

#define kEncryptionMasterKey @"IaDYdb1KUmMXryyF0cM3SYa2lFcDsQ+c0H04ZaxSyiix6/T//+KT6AA="
#define kEncryptionPublicParameters @"FQdHvz/VMGL6KLP2b4GXiujvVGQjO204iqUt2MirtxlTQ2IND7gAFQAZQYaG3nTV5JFoXi1RmvACy3PEZRv3v6hcTwJogfd8dK9CAajIOKuAAQNj2qFFLhWSwDEXf05eTlcGqyysAEZ6OGNqRPVVwc1Mwxmq8togOVYACLA5aAHF8oNIH29Xy+XY5WzZEW0BG0mTX7IqSliIZXoQrK/I/swEAjwBFZMP7ma7v7f+JxpeiXJ4z7oK8BIBEvbPC00grFRFquyGd93c5STDI1oRXhPMmZwFRt7y+wn0Z353pST1ZhkNyyy/7OQ4Eug46S31MZcXkL68I5JAe1aZcaW3KX35PRBcL546liQDVoPfruuzvV2NI1roROPabi0CFCBVQw8vcFBlegN9L/WQ9kAnhNODBke3XZRi7Eohs0FxVDlAEtXu5j8WSvPEcx5mb2rh9FQcteRLqqeaeBL9v+OdxUOdMZVK1XksGj+kNiWfEUqgUpK8WnFMEh5Idna98AeFQtoOUYrdNYmoAa9BxjTfTtb/VtcANCO9/ZkUtUARTP5Zpb2nHaUis9Q+"

#define kSignatureMasterKey @"DkYMfelGGsxk8harZ0Ga/rIMeC4="
#define kSignaturePublicParameters "Dd9pJec6fLTT2kpDu4xZaTYQDxQRdG0Yh3gC7WX4Vt3gb4BPMz42cgEQNOT5i0ihwacJxQ+6Clg5TTbKUBZrv9zwj1lRe9f8AQ23YMC3RpXpAA=="

@class IBEncryptionScheme,IBSignatureScheme;

@interface UnverifiedIdentityProvider : NSObject<IdentityProvider>
@property (nonatomic, strong) IBEncryptionScheme* encryptionScheme;
@property (nonatomic, strong) IBSignatureScheme* signatureScheme;


@end
