//
// Copyright 2015 The REST Switch Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its 
// Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, 
// without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR 
// PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any 
// risks associated with Your exercise of permissions under this License.
//
// Author: John Clark (johnc@restswitch.com)
//

#ifndef __auth_h__
#define __auth_h__

long get_now_ms(void);
int auth_b64url_encode(const void* p_inbuf, const int p_inbuflen, void* p_outbuf, const int p_outbuflen);
int auth_hmac_sha256_encode(const void* p_inkey, const int p_inkeylen, const void* p_inbuf, const int p_inbuflen, void* p_outbuf, const int p_outbuflen);
//int auth_make_hash(const char* p_devid, const char* p_method, const char* p_path, 
//                   const char* p_msg, const long p_timems, const char* p_pwdHash, 
//                   void* p_outbuf, const int p_outbuflen);
int auth_validate_hash(const char* p_val, const int p_vallen, const char* p_pwdHash, const int p_pwdHashLen, const char* p_hashToValidate, const int p_hashToValidateLen);

#endif // __auth_h__

