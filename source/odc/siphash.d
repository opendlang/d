/*
 * This file contains a port of the reference SipHash C implementation to D,
 * as well as a wrapper intended to facilitate its use with druntime AAs to
 * protect against the HashDoS attack.
 *
 * The primary differences between the C and implementations D are:
 *      - This implementation supports streaming;
 *      - This implementation reduces the number of rounds between each message
 *        block injection from 2 to 1, and from 4 to 3 for the subsequent
 *        rounds. This reduces security but increases performance. This change
 *        has been implemented for AAs in other languages.
 *
 * To enable SipHash, add sipProtect to declarations, e.g.
 *
 *      int[sipProtect!string] aa;
 *
 * N.B. The unittest contains the original SipHash 2-4 test vectors.
 * 
 * The reference implementation CMI is reproduced below:
 *
 * Copyright (c) 2012-2022 Jean-Philippe Aumasson
 * <jeanphilippe.aumasson@gmail.com>
 * Copyright (c) 2012-2014 Daniel J. Bernstein <djb@cr.yp.to>
 * 
 * To the extent possible under law, the author(s) have dedicated all copyright
 * and related and neighboring rights to this software to the public domain
 * worldwide. This software is distributed without any warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication along
 * with
 * this software. If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 *
 * END OF ORIGINAL CMI
 * 
 * Modifications and additions are provided under the following license:
 * 
 * SPDX-License-Identifier: BSL-1.0
 * Copyright (C) 2026 Indraj Gandham <hello@indraj.net>
 *
 * END OF MODIFICATIONS CMI
 */

module odc.siphash;

import core.bitop;
import core.stdc.string;
import std.exception;

// Implementation

version(unittest) {
        enum cROUNDS = 2;
        enum dROUNDS = 4;
} else {
        enum cROUNDS = 1;
        enum dROUNDS = 3;
}

private __gshared immutable ulong rt_k0;
private __gshared immutable ulong rt_k1;

shared static this() @system
{
        ubyte [16]buf;

        static if (size_t.sizeof != 8) {
                static assert(0, "32-bit platforms are not supported");
        }

        version(linux) {
                // Linux 3.17+
                // note 1: getentropy() unavailable when using --target=compat
                // note 2: less than 256 bytes, getrandom() won't be interrupted
                import core.sys.linux.sys.syscall;
                import core.sys.linux.unistd;
                enforce(syscall(SYS_getrandom,
                                buf.ptr,
                                buf.length,
                                0) == buf.length);

        } else version(Windows) {
                // Windows Vista SP2+
                import core.sys.windows.bcrypt;
                import core.sys.windows.ntdef;

                auto status = BCryptGenRandom(null,
                                              buf.ptr,
                                              cast(uint) buf.length,
                                              BCRYPT_USE_SYSTEM_PREFERRED_RNG);

                enforce(NT_SUCCESS(status));

        } else version(OSX) {
                // macOS 10.12+ (Sierra)
                import core.sys.posix.unistd;
                enforce(getentropy(buf.ptr, buf.length) == 0);

        } else {
                static assert(0, "platform not supported");
        }

        ulong k0;
        ulong k1;
        memcpy(&k0, buf.ptr, 8);
        memcpy(&k1, buf.ptr + 8, 8);
        rt_k0 = k0;
        rt_k1 = k1;
}

pragma(inline, true)
@trusted @nogc nothrow pure
private ulong u8to64_le(const(ubyte) []p)
{
        return (cast(ulong)(p[0])) |
               (cast(ulong)(p[1]) << 8) |
               (cast(ulong)(p[2]) << 16) |
               (cast(ulong)(p[3]) << 24) |
               (cast(ulong)(p[4]) << 32) |
               (cast(ulong)(p[5]) << 40) |
               (cast(ulong)(p[6]) << 48) |
               (cast(ulong)(p[7]) << 56);
}

struct sipHash {
private:
        ulong v0;
        ulong v1;
        ulong v2;
        ulong v3;
        ulong tail;
        size_t length;
}

@trusted @nogc nothrow pure
void load(ref sipHash state)
{
        ulong k0;
        ulong k1;

        assert(!__ctfe, "CTFE is not supported");

        version(unittest) {
                k0 = 0x0706050403020100;
                k1 = 0x0f0e0d0c0b0a0908;
        } else {
                k0 = rt_k0;
                k1 = rt_k1;
        }

        state.v0 = 0x736f6d6570736575;
        state.v1 = 0x646f72616e646f6d;
        state.v2 = 0x6c7967656e657261;
        state.v3 = 0x7465646279746573;
        state.v3 ^= k1;
        state.v2 ^= k0;
        state.v1 ^= k1;
        state.v0 ^= k0;
        state.tail = 0;
        state.length = 0;
}

pragma(inline, true)
@trusted @nogc nothrow pure
private void round(ref sipHash state)
{
        state.v0 += state.v1;
        state.v1 = rol!13(state.v1);
        state.v1 ^= state.v0;
        state.v0 = rol!32(state.v0);
        state.v2 += state.v3;
        state.v3 = rol!16(state.v3);
        state.v3 ^= state.v2;
        state.v0 += state.v3;
        state.v3 = rol!21(state.v3);
        state.v3 ^= state.v0;
        state.v2 += state.v1;
        state.v1 = rol!17(state.v1);
        state.v1 ^= state.v2;
        state.v2 = rol!32(state.v2);
}

pragma(inline, true)
@trusted @nogc nothrow pure
private void compress(ref sipHash state, ulong m)
{
        state.v3 ^= m;
        foreach (_; 0 .. cROUNDS) round(state);
        state.v0 ^= m;
}

@trusted @nogc nothrow pure
void put(ref sipHash state, const(ubyte) []data)
{
        ulong used = state.length & 7;
        state.length += data.length;
        if (used != 0) {
                ulong n;
                if (data.length < (8 - used)) {
                        n = data.length;
                } else {
                        n = 8 - used;
                }
                foreach (i, e; data[0 .. n]) {
                        state.tail |= cast(ulong)(e) << (8 * (used + i));
                }
                if ((used + n) < 8) return;
                compress(state, state.tail);
                state.tail = 0;
                data = data[n .. $];
        }

        while (data.length >= 8) {
                compress(state, u8to64_le(data));
                data = data[8 .. $];
        }

        foreach (i, e; data) {
                state.tail |= cast(ulong)(e) << (8 * i);
        }
}

@trusted @nogc nothrow pure
ulong finalise(ref sipHash state)
{
        compress(state, (cast(ulong)(state.length) << 56) | state.tail);
        state.v2 ^= 0xff;
        foreach (_; 0 .. dROUNDS) round(state);
        return state.v0 ^ state.v1 ^ state.v2 ^ state.v3;
}

// Wrapper

private template hashByteWise(K)
{
        static if (__traits(isIntegral, K)) {
                enum hashByteWise = true;
        } else static if (is(K == E[], E)) {
                enum hashByteWise = __traits(isIntegral, E);
        } else {
                enum hashByteWise = false;
        }
}

struct sipProtect(K)
if (hashByteWise!K) {

        K val;

        size_t toHash() const @trusted @nogc nothrow pure
        {
                sipHash state;
                load(state);
                static if (__traits(isIntegral, K)) {
                        put(state, (cast(const(ubyte)*) &val)[0 .. K.sizeof]);
                } else {
                        put(state, cast(const(ubyte)[]) val);
                }
                return cast(size_t) finalise(state);
        }
}

// Test vectors

unittest
{
        static immutable ubyte[8][64] vectors_sip64 = [
                [0x31, 0x0e, 0x0e, 0xdd, 0x47, 0xdb, 0x6f, 0x72],
                [0xfd, 0x67, 0xdc, 0x93, 0xc5, 0x39, 0xf8, 0x74],
                [0x5a, 0x4f, 0xa9, 0xd9, 0x09, 0x80, 0x6c, 0x0d],
                [0x2d, 0x7e, 0xfb, 0xd7, 0x96, 0x66, 0x67, 0x85],
                [0xb7, 0x87, 0x71, 0x27, 0xe0, 0x94, 0x27, 0xcf],
                [0x8d, 0xa6, 0x99, 0xcd, 0x64, 0x55, 0x76, 0x18],
                [0xce, 0xe3, 0xfe, 0x58, 0x6e, 0x46, 0xc9, 0xcb],
                [0x37, 0xd1, 0x01, 0x8b, 0xf5, 0x00, 0x02, 0xab],
                [0x62, 0x24, 0x93, 0x9a, 0x79, 0xf5, 0xf5, 0x93],
                [0xb0, 0xe4, 0xa9, 0x0b, 0xdf, 0x82, 0x00, 0x9e],
                [0xf3, 0xb9, 0xdd, 0x94, 0xc5, 0xbb, 0x5d, 0x7a],
                [0xa7, 0xad, 0x6b, 0x22, 0x46, 0x2f, 0xb3, 0xf4],
                [0xfb, 0xe5, 0x0e, 0x86, 0xbc, 0x8f, 0x1e, 0x75],
                [0x90, 0x3d, 0x84, 0xc0, 0x27, 0x56, 0xea, 0x14],
                [0xee, 0xf2, 0x7a, 0x8e, 0x90, 0xca, 0x23, 0xf7],
                [0xe5, 0x45, 0xbe, 0x49, 0x61, 0xca, 0x29, 0xa1],
                [0xdb, 0x9b, 0xc2, 0x57, 0x7f, 0xcc, 0x2a, 0x3f],
                [0x94, 0x47, 0xbe, 0x2c, 0xf5, 0xe9, 0x9a, 0x69],
                [0x9c, 0xd3, 0x8d, 0x96, 0xf0, 0xb3, 0xc1, 0x4b],
                [0xbd, 0x61, 0x79, 0xa7, 0x1d, 0xc9, 0x6d, 0xbb],
                [0x98, 0xee, 0xa2, 0x1a, 0xf2, 0x5c, 0xd6, 0xbe],
                [0xc7, 0x67, 0x3b, 0x2e, 0xb0, 0xcb, 0xf2, 0xd0],
                [0x88, 0x3e, 0xa3, 0xe3, 0x95, 0x67, 0x53, 0x93],
                [0xc8, 0xce, 0x5c, 0xcd, 0x8c, 0x03, 0x0c, 0xa8],
                [0x94, 0xaf, 0x49, 0xf6, 0xc6, 0x50, 0xad, 0xb8],
                [0xea, 0xb8, 0x85, 0x8a, 0xde, 0x92, 0xe1, 0xbc],
                [0xf3, 0x15, 0xbb, 0x5b, 0xb8, 0x35, 0xd8, 0x17],
                [0xad, 0xcf, 0x6b, 0x07, 0x63, 0x61, 0x2e, 0x2f],
                [0xa5, 0xc9, 0x1d, 0xa7, 0xac, 0xaa, 0x4d, 0xde],
                [0x71, 0x65, 0x95, 0x87, 0x66, 0x50, 0xa2, 0xa6],
                [0x28, 0xef, 0x49, 0x5c, 0x53, 0xa3, 0x87, 0xad],
                [0x42, 0xc3, 0x41, 0xd8, 0xfa, 0x92, 0xd8, 0x32],
                [0xce, 0x7c, 0xf2, 0x72, 0x2f, 0x51, 0x27, 0x71],
                [0xe3, 0x78, 0x59, 0xf9, 0x46, 0x23, 0xf3, 0xa7],
                [0x38, 0x12, 0x05, 0xbb, 0x1a, 0xb0, 0xe0, 0x12],
                [0xae, 0x97, 0xa1, 0x0f, 0xd4, 0x34, 0xe0, 0x15],
                [0xb4, 0xa3, 0x15, 0x08, 0xbe, 0xff, 0x4d, 0x31],
                [0x81, 0x39, 0x62, 0x29, 0xf0, 0x90, 0x79, 0x02],
                [0x4d, 0x0c, 0xf4, 0x9e, 0xe5, 0xd4, 0xdc, 0xca],
                [0x5c, 0x73, 0x33, 0x6a, 0x76, 0xd8, 0xbf, 0x9a],
                [0xd0, 0xa7, 0x04, 0x53, 0x6b, 0xa9, 0x3e, 0x0e],
                [0x92, 0x59, 0x58, 0xfc, 0xd6, 0x42, 0x0c, 0xad],
                [0xa9, 0x15, 0xc2, 0x9b, 0xc8, 0x06, 0x73, 0x18],
                [0x95, 0x2b, 0x79, 0xf3, 0xbc, 0x0a, 0xa6, 0xd4],
                [0xf2, 0x1d, 0xf2, 0xe4, 0x1d, 0x45, 0x35, 0xf9],
                [0x87, 0x57, 0x75, 0x19, 0x04, 0x8f, 0x53, 0xa9],
                [0x10, 0xa5, 0x6c, 0xf5, 0xdf, 0xcd, 0x9a, 0xdb],
                [0xeb, 0x75, 0x09, 0x5c, 0xcd, 0x98, 0x6c, 0xd0],
                [0x51, 0xa9, 0xcb, 0x9e, 0xcb, 0xa3, 0x12, 0xe6],
                [0x96, 0xaf, 0xad, 0xfc, 0x2c, 0xe6, 0x66, 0xc7],
                [0x72, 0xfe, 0x52, 0x97, 0x5a, 0x43, 0x64, 0xee],
                [0x5a, 0x16, 0x45, 0xb2, 0x76, 0xd5, 0x92, 0xa1],
                [0xb2, 0x74, 0xcb, 0x8e, 0xbf, 0x87, 0x87, 0x0a],
                [0x6f, 0x9b, 0xb4, 0x20, 0x3d, 0xe7, 0xb3, 0x81],
                [0xea, 0xec, 0xb2, 0xa3, 0x0b, 0x22, 0xa8, 0x7f],
                [0x99, 0x24, 0xa4, 0x3c, 0xc1, 0x31, 0x57, 0x24],
                [0xbd, 0x83, 0x8d, 0x3a, 0xaf, 0xbf, 0x8d, 0xb7],
                [0x0b, 0x1a, 0x2a, 0x32, 0x65, 0xd5, 0x1a, 0xea],
                [0x13, 0x50, 0x79, 0xa3, 0x23, 0x1c, 0xe6, 0x60],
                [0x93, 0x2b, 0x28, 0x46, 0xe4, 0xd7, 0x06, 0x66],
                [0xe1, 0x91, 0x5f, 0x5c, 0xb1, 0xec, 0xa4, 0x6c],
                [0xf3, 0x25, 0x96, 0x5c, 0xa1, 0x6d, 0x62, 0x9f],
                [0x57, 0x5f, 0xf2, 0x8e, 0x60, 0x38, 0x1b, 0xe5],
                [0x72, 0x45, 0x06, 0xeb, 0x4c, 0x32, 0x8a, 0x95],
        ];
 
        ubyte[64] message;
        foreach (i, ref e; message) {
                e = cast(ubyte) i;
        }
 
        foreach (i, expected; vectors_sip64) {
                sipHash state;
                load(state);
                put(state, message[0 .. i]);
                ulong h = finalise(state);
 
                ubyte[8] result;
                foreach (j, ref e; result) {
                        e = cast(ubyte)(h >> (8 * j));
                }
                assert(result == expected);
        }
}
