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


//
//   hmac sha256 of password hash against device+method+path+msg+time
//
//     hmac key:
//       (in) pwdHash hmac key: [Butter&Pecan]
//       (in) pwdHash hmac val: [rex.smith@bogus.bog]
//       (out) pwdHash: [cFnrQMZ5emnCqLRZy4RVc4MrhCEyNJ9VTupN6JbUS50]
//
//     hmac value: (method + url + msg + b32UntilUtc)
//       (in) method: [PUT]
//       (in) url: [/pub/ah3auvuvu]
//       (in) msg: [["pulseRelay",1,250]]
//       (in) until: [ajxczj7er]  ->  0x14d4774f4af  (Tue 05/12/2015 05:29:16 AM EDT)
//       (out) aggregate: [PUT/pub/ah3auvuvu["pulseRelay",1,250]ajxczj7er]
//
//     hmac result hash (b64url, no pad):
//       generated hash: [n0LATpo6mAyEC5Q7RogY0SsdtXanKPjL9IWBH6HsA8U]
//


#include <stdio.h>     // printf
#include <string.h>    // strlen
#include <strings.h>   // bzero
#include <sys/time.h>  // time
#include <stdint.h>
#include <openssl/hmac.h>

#include "b32coder.h"



////////////////////////////////////////////////////////////////
long get_now_ms(void)
{
    // get the time right now
    struct timeval tvnow;
    gettimeofday(&tvnow, NULL);
    long nowms = (tvnow.tv_sec*1000LL + tvnow.tv_usec/1000); // milliseconds
    return(nowms);
}



////////////////////////////////////////////////////////////////
// CN4ymTHilWg3dqqaQ1Kb0LJ1KG3zFgMAxJuk6EGDMBM (43 chars w/o pad)
int auth_b64url_encode(const void* p_inbuf, const int p_inbuflen, void* p_outbuf, const int p_outbuflen)
{
    static const char* encoding_table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"; // rfc4648 base64url

    bzero(p_outbuf, p_outbuflen);
    const unsigned char* inbuf = (unsigned char*)p_inbuf;
    char* outbuf = (char*)p_outbuf;

    const int otot = (((p_inbuflen + 2) / 3) * 4);

    // report bytes needed for p_outbuf
    if(NULL == p_outbuf)
    {
        return(otot);
    }

    if(p_outbuflen < otot)
    {
        return(-1);  // insufficient buffer
    }

    for(int i=0, j=0; i < p_inbuflen; )
    {
        uint32_t octet_a = ((i < p_inbuflen) ? inbuf[i++] : 0);
        uint32_t octet_b = ((i < p_inbuflen) ? inbuf[i++] : 0);
        uint32_t octet_c = ((i < p_inbuflen) ? inbuf[i++] : 0);

        uint32_t triple = ((octet_a << 0x10) | (octet_b << 0x08) | octet_c);

        outbuf[j++] = encoding_table[(triple >> 3 * 6) & 0x3f];
        outbuf[j++] = encoding_table[(triple >> 2 * 6) & 0x3f];
        outbuf[j++] = encoding_table[(triple >> 1 * 6) & 0x3f];
        outbuf[j++] = encoding_table[(triple >> 0 * 6) & 0x3f];
    }

    // need to pad?
    const int mod = (p_inbuflen % 3);
    if(mod > 0)
    {
        outbuf[otot - 1] = '\0'; // pad with null rather than =
        if(1 == mod) outbuf[otot - 2] = '\0'; // second pad needed on mod1
    }

    return(otot);  // success
}


////////////////////////////////////////////////////////////////
// output is base64
int auth_hmac_sha256_encode(const void* p_inkey, const int p_inkeylen, const void* p_inbuf, const int p_inbuflen, void* p_outbuf, const int p_outbuflen)
{
    bzero(p_outbuf, p_outbuflen);

    // disable osx 'deprecated' warning
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"

    const unsigned int HMAC_SHA256_DIGEST_LENGTH = EVP_MD_size(EVP_sha256());
    const int otot = (((HMAC_SHA256_DIGEST_LENGTH + 2) / 3) * 4);

    // report bytes needed for p_outbuf
    if(NULL == p_outbuf)
    {
        return(otot);
    }

    if(p_outbuflen < otot)
    {
        return(-1);  // insufficient buffer
    }

    unsigned char digest[HMAC_SHA256_DIGEST_LENGTH];
    unsigned int digestlen = 0;
    HMAC(EVP_sha256(), p_inkey, p_inkeylen, p_inbuf, p_inbuflen, digest, &digestlen);
    if(HMAC_SHA256_DIGEST_LENGTH != digestlen)
    {
        return(-2);  // hash error
    }
    #pragma GCC diagnostic pop
    // disable osx 'deprecated' warning

    int rc = auth_b64url_encode(digest, digestlen, p_outbuf, p_outbuflen);
    if(rc < 0)
    {
        return(-3);  // b64url encode failure
    }

    return(otot);  // success
}


////////////////////////////////////////////////////////////////
// var val = (devid + method + path + msg + b32UntilUtc);
/*
int auth_make_hash(const char* p_devid, const char* p_method, const char* p_path, 
                   const char* p_msg, const long p_timems, const char* p_pwdHash, 
                   void* p_outbuf, const int p_outbuflen)
{
    bzero(p_outbuf, p_outbuflen);

    // disable osx 'deprecated' warning
    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"

    const unsigned int HMAC_SHA256_DIGEST_LENGTH = EVP_MD_size(EVP_sha256());
    const int otot = (((HMAC_SHA256_DIGEST_LENGTH + 2) / 3) * 4);

    if(p_outbuflen < otot)
    {
        return(-1);  // insufficient buffer
    }

    char b32ms[16];
    int rc = encode_datetime(p_timems, b32ms, sizeof(b32ms));
    if(9 != rc)
    {
        return(-2);  // datetime encode failure
    }

    HMAC_CTX ctx;
    HMAC_CTX_init(&ctx);
    HMAC_Init_ex(&ctx, p_pwdHash, strlen(p_pwdHash), EVP_sha256(), NULL);

    HMAC_Update(&ctx, (const unsigned char*)p_method, strlen(p_method));
    HMAC_Update(&ctx, (const unsigned char*)p_path, strlen(p_path));
    HMAC_Update(&ctx, (const unsigned char*)"/", 1);
    HMAC_Update(&ctx, (const unsigned char*)p_devid, strlen(p_devid));
    HMAC_Update(&ctx, (const unsigned char*)p_msg, strlen(p_msg));
    HMAC_Update(&ctx, (const unsigned char*)b32ms, 9);

    unsigned char digest[HMAC_SHA256_DIGEST_LENGTH];
    unsigned int digestlen = 0;
    HMAC_Final(&ctx, digest, &digestlen);
    HMAC_CTX_cleanup(&ctx);
    #pragma GCC diagnostic pop
    // disable osx 'deprecated' warning

    if(HMAC_SHA256_DIGEST_LENGTH != digestlen)
    {
        return(-3);  // hash error
    }

    rc = auth_b64url_encode(digest, digestlen, p_outbuf, p_outbuflen);
    if(rc < 0)
    {
        return(-4);  // b64url encode failure
    }

    return(otot); // success
}
*/


////////////////////////////////////////////////////////////////
//
// p_val should be in the form of:
// PUT/pub/ah3auvuvu["pulseRelay",1,250]ajxcxtavb
//
int auth_validate_hash(const char* p_val, const int p_vallen, const char* p_pwdHash, const int p_pwdHashLen, const char* p_hashToValidate, const int p_hashToValidateLen)
{
    // get the time right now
    const long nowms = get_now_ms();

    // step 1: extract b32 until time from p_val
    // the b32 timestamp is the last 9 chars of p_val: ajxcxtavb
    if(p_vallen < 25)  // a legal p_val must be at least 25 chars - something like: PUT/ah3auvuvu[0]ajxcxtavb
    {
        printf("invalid minimum p_val length: [%d]  p_val: [%s]\n", p_vallen, p_val);
        return(-1);
    }
    const int b32UntilUtcLen = 9; // b32 times are 9 chars
    const char* b32UntilUtc = (p_val + p_vallen - b32UntilUtcLen);

    // step 2: test hash length
    // hashes are 43 chars with padding removed: 0HQT9G0jvsSLMlJ2q-LQptF69wj6E0VUL2P4giEReb0
    if(43 != p_hashToValidateLen)
    {
        printf("invalid p_hashToValidate length: [%d]  hash: [%s]\n", p_hashToValidateLen, p_hashToValidate);
        return(-2);
    }

    // step 3: decode url time & check it against "now"
    long authms = decode_datetime(b32UntilUtc, b32UntilUtcLen);
    if(authms < 0)
    {
        printf("unable to decode datetime from b32UntilUtc: [%s]\n", b32UntilUtc);
        return(-3);
    }

    if(authms < nowms)
    {
        printf("request has expired - delta: [%lds]  b32UntilUtc: [%s]\n", ((authms - nowms) / 1000), b32UntilUtc);
        return(-4);
    }
    printf("b32UntilUtc is in the future - delta: [%lds]\n", ((authms - nowms) / 1000));

    // the b32 time is valid, check the hash
    char hash[44];
    int rc = auth_hmac_sha256_encode(p_pwdHash, p_pwdHashLen, p_val, p_vallen, hash, sizeof(hash));
    if(rc < 0)
    {
        printf("failed to generate reference auth hash\n");
        return(-5);
    }

    // compare strings
    if(0 != strncmp(hash, p_hashToValidate, p_hashToValidateLen))
    {
        printf("passed hash: [%s]  gen'd hash: [%s]\n", p_hashToValidate, hash);
        return(1);  // auth validate fail
    }

    return(0);  // success
}

