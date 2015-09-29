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
// made up reference value 1362540074332 = 0x13D3DB7955C -> AGW84REK6
// ...0:0001 0011:1101 0011:1101 1011:0111 1001:0101 0101:1100        (0x13D3DB7955C: 8 bit grouping)
//         1        3d        3b        b7        95        5c
// 0:0001 0:0111 1:0100 1:1110 1:1011 0:1111 0:0101 0:1010 1:1100     (0x13D3DB7955C: 5 bit grouping) <- no direct use as it is reversed to node.js coding
//      1      7     14     1e     1b     0f     05     0a     1c
//
// input above, when revresed, is below
//
// if we 5-bit reverse the 5 bit coded 1-7-14-1e-1b-0f-05-0a-1c string we get 1c-0a-05-0f-1b-1e-14-07-01:
// 1:1100 0:1010 0:0101 0:1111 1:1011 1:1110 1:0100 0:0111 0:0001     (0x1c515fbf50e1: 5 bit grouping)
//     1c     0a     05     0f     1b     1e     14     07     01
// ...1:1100 0101:0001 0101:1111 1011:1111 0101:0000 1110:0001        (0x1c515fbf50e1: 8 bit grouping)
//        1c        51        5f        bf        50        e1
//
//
// RESULT??
// 1:1100 0:1010 0:0101 0:1111 1:1011 1:1110 1:0100 0:0111 0:0001     (0x1c515fbf50e1: 5 bit grouping)
//     1c     0a     05     0f     1b     1e     14     07     01
//      6      K      E      R      4      8      W      G      A    <---- the encoding we want
//
//
// THIS IS IT RIGHT HERE!!!  take 0x13D3DB7955C in and yeild 0x1c515fbf50e1
// encode_datetime in:           [0x13d3db7955c]       out: [0x1c515fbf50e1]
// ...1:1100 0101:0001 0101:1111 1011:1111 0101:0000 1110:0001        (0x1c515fbf50e1: 8 bit grouping is our string-reverse goal)
//        1c        51        5f        bf        50        e1
//
//
// if we target 000AGW84REK6 rather than AGW84REK6 to take up 60 bits (64/5) then we have 15 trailing bits (45 + 15 = 60)
// 1:1100 0:1010 0:0101 0:1111 1:1011 1:1110 1:0100 0:0111 0:0001 0:0000 0:0000 0:0000
//     1c     0a     05     0f     1b     1e     14     07     01      0      0      0
//
// (8 bit version of above)
// ....:1110 0010:1000 1010:1111 1101:1111 1010:1000 0111:0000 1000:0000 0000:0000   which yeilds -> muk4qrj70d000
//        0e        28        af        df        a8        70        80        00
//
//
// from DateCoder.java
//         // input (dec):  1362540074332
//         // input (date): Tue Mar 05 2013 22:21:14 GMT-0500 (EST)
//         // input (hex):  13d3db7955c
//
//         // capture up to 60 bits (00001 3d3db 7955c)
//         byte[] ba = new byte[12];
//         ba[11] = (byte)( date        & 0x1f);  // bits 0-4    --> 0x1c  "6"
//         ba[10] = (byte)((date >>  5) & 0x1f);  // bits 5-9    --> 0x0a  "K"
//         ba[ 9] = (byte)((date >> 10) & 0x1f);  // bits 10-14  --> 0x05  "E"
//         ba[ 8] = (byte)((date >> 15) & 0x1f);  // bits 15-19  --> 0x0f  "R"
//         ba[ 7] = (byte)((date >> 20) & 0x1f);  // bits 20-24  --> 0x1b  "4"
//         ba[ 6] = (byte)((date >> 25) & 0x1f);  // bits 25-29  --> 0x1e  "8"
//         ba[ 5] = (byte)((date >> 30) & 0x1f);  // bits 30-34  --> 0x14  "W"
//         ba[ 4] = (byte)((date >> 35) & 0x1f);  // bits 35-39  --> 0x07  "G"
//         ba[ 3] = (byte)((date >> 40) & 0x1f);  // bits 40-44  --> 0x01  "A"
//         ba[ 2] = (byte)((date >> 45) & 0x1f);  // bits 45-49  --> 0x00  "0"
//         ba[ 1] = (byte)((date >> 50) & 0x1f);  // bits 50-54  --> 0x00  "0"
//         ba[ 0] = (byte)((date >> 55) & 0x1f);  // bits 55-59  --> 0x00  "0"
//

#include <stdio.h>     // printf
#include <string.h>    // memcpy
#include <strings.h>   // bzero
#include <sys/time.h>  // time


////////////////////////////////////////////////////////////
//
// encode
//   returns the number of bytes stored in p_outbuf
//   returns zero on error
//   pass null for p_outbuf to return the min bytes needed for p_outbuf
//
int encode(const void* p_inbuf, const int p_inbuflen, void* p_outbuf, const int p_outbuflen)
{
    static char* enc32 = "0abcdefghjkmnpqrstuvwxyz12346789";
//    static const char* enc32 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";  // RFC-4648 charset

    bzero(p_outbuf, p_outbuflen);
    const char* inbuf = (char*)p_inbuf;
    char* outbuf = (char*)p_outbuf;

    const int bitc = (p_inbuflen * 8);
    const int whol = (bitc / 5);
    const int otot = (whol + ((bitc % 5) ? 1 : 0));
//    printf("encode - input bytes: [%d]  output bytes: [%d]\n", p_inbuflen, otot);

    // report bytes needed for p_outbuf
    if(NULL == p_outbuf)
    {
        return(otot);
    }

    if(p_outbuflen < otot)
    {
        return(-1);  // insufficient buffer
    }

    char sft = -8;
    unsigned char src = 0;
    for(int i=0, o=otot-1; o >= 0; --o)
    {
        char bits = (0x1f & ((sft < 0) ? (src >> (-sft)) : (src << sft)));
        if((sft < -3) && (i < p_inbuflen))
        {
            // wrapping cases: [4-7:0] [5-7:0-1] [6-7:0-2] [7:0-3] (and 8)
            src = inbuf[i++];
            sft += 8;
            bits |= (0x1f & ((sft < 0) ? (src >> (-sft)) : (src << sft)));
        }

        // store bits
        outbuf[o] = enc32[0x1f & bits];
        sft -= 5;
    }

    return(otot);
}


////////////////////////////////////////////////////////////
unsigned char decode_char(const char p_c)
{
    if((p_c >= 'A') && (p_c <= 'H')) return(p_c - 'A' + 1);
    if((p_c >= 'a') && (p_c <= 'h')) return(p_c - 'a' + 1);

    if((p_c == 'J') || (p_c == 'K')) return(p_c - 'J' + 9);
    if((p_c == 'j') || (p_c == 'k')) return(p_c - 'j' + 9);

    if((p_c == 'M') || (p_c == 'N')) return(p_c - 'M' + 11);
    if((p_c == 'm') || (p_c == 'n')) return(p_c - 'm' + 11);

    if((p_c >= 'P') && (p_c <= 'Z')) return(p_c - 'P' + 13);
    if((p_c >= 'p') && (p_c <= 'z')) return(p_c - 'p' + 13);

    if((p_c == '0') || (p_c == 'O') || (p_c == 'o')) return(0);
    if((p_c == '1') || (p_c == 'I') || (p_c == 'i') || (p_c == 'L') || (p_c == 'l')) return(24);
    if((p_c >= '2') && (p_c <= '4')) return(p_c - '2' + 25);
    if (p_c == '5') return(16); // 5=s
    if((p_c >= '6') && (p_c <= '9')) return(p_c - '6' + 28);

    return(0xff);
}

////////////////////////////////////////////////////////////
int decode(const void* p_inbuf, const int p_inbuflen, void* p_outbuf, const int p_outbuflen)
{
    bzero(p_outbuf, p_outbuflen);
    const char* inbuf = (char*)p_inbuf;
    char* outbuf = (char*)p_outbuf;

    const int btot = (p_inbuflen * 5);
    const int otot = (btot / 8);
// we never want to round-up as partial bytes would not have been encoded
//    const int whol = (btot / 8);
//    const int otot = (whol + (((btot % 8) > 0) ? 1 : 0));
//    printf("decode - input bytes: [%d]  output bytes: [%d]\n", p_inbuflen, otot);

    // report bytes needed for p_outbuf
    if(NULL == p_outbuf)
    {
        return(otot);
    }

    if(p_outbuflen < otot)
    {
        return(-1);  // insufficient buffer
    }

    int sft = -5;
    unsigned char src = 0;
    for(int i=p_inbuflen, o=0; o < otot; ++o)
    {
        char bits = ((sft < 0) ? (src >> (-sft)) : (src << sft));
        while((sft < 3) && (i > 0))
        {
            src = decode_char(inbuf[--i]);
            sft += 5;
            bits |= ((sft < 0) ? (src >> (-sft)) : (src << sft));
        }

        // store bits
        outbuf[o] = bits;
        sft += -8;
    }

    return(otot);
}


////////////////////////////////////////////////////////////
//
//  b32 encoding  |   0    |   0    |   0    |   a    |   g    |   w    |   8    |   4    |   r    |   e    |   k    |   6    |
//  hex           |  0x00  |  0x00  |  0x00  |  0x01  |  0x07  |  0x14  |  0x1e  |  0x1b  |  0x0f  |  0x05  |  0x0a  |  0x1c  |
//  binary(5)     | 0:0000 | 0:0000 | 0:0000 | 0:0001 | 0:0111 | 1:0100 | 1:1110 | 1:1011 | 0:1111 | 0:0101 | 0:1010 | 1:1100 |
//                -------------------------------------------------------------------------------------------------------------
//  binary(8)                 | ....:0000 | 0000:0000 | 0000:0001 | 0011:1101 | 0011:1101 | 1011:0111 | 1001:0101 | 0101:1100 |
//                            |   0x00    |   0x00    |   0x01    |   0x3d    |   0x3d    |   0xb7    |   0x95    |   0x5c    |
//
//  000agw84rek6 -> 0x01 3d 3d b7 95 5c
//
int encode_datetime(const time_t p_datetime, void* p_outbuf, const int p_outbuflen)
{
    int enclen = encode(&p_datetime, sizeof(p_datetime), p_outbuf, p_outbuflen);
    if(enclen < 0)
    {
        return(enclen);  // error
    }

    // remove leading 0 padding
    // 0000agw84rek6 -> agw84rek6
    char* outbuf = (char*)p_outbuf;
    for(int i=0; i<p_outbuflen; ++i)
    {
        // find the first non-zero char
        if('0' != outbuf[i])
        {
            if(0 != i)
            {

                memcpy(outbuf, &outbuf[i], (p_outbuflen - i));
                enclen -= i;
            }
            break;
        }
    }

    return(enclen);
}


////////////////////////////////////////////////////////////
int encode_datetime_now(void* p_outbuf, const int p_outbuflen)
{
    struct timeval now;
    gettimeofday(&now, NULL);

    long val = (now.tv_sec*1000LL + now.tv_usec/1000); // milliseconds
    int enclen = encode_datetime(val, p_outbuf, p_outbuflen);
    return(enclen);
}


////////////////////////////////////////////////////////////
long decode_datetime(const char* p_encoded, const int p_encodedlen)
{
    const int enclen = ((0==p_encodedlen) ? (int)strlen(p_encoded) : p_encodedlen);
    if(enclen > 12)
    {
        return(-2); // error, too large
    }

    // pad with leading zeros to make 12 chars
    // agw84rek6 -> 000agw84rek6
    char buf[12];
    int pad = (12 - enclen);
    for(int i=0; i<pad; ++i) buf[i] = '0';
    memcpy(buf + pad, p_encoded, enclen);

    long datetime = 0;
    int rc = decode(buf, 12, &datetime, sizeof(datetime));
    if(rc < 0)
    {
        return(rc);
    }

    return(datetime);
}
