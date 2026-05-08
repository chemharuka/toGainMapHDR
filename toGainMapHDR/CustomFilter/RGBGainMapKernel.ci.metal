//
//  RGBGainMap.ci.metal
//  toGainMapHDR
//
//  Created by Luyao Peng on 11/27/24.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;


inline float process_channel(float hdr_value, float sdr_value, float hdrmax)
{
    float kcons = 0.000010f;
    sdr_value = min(sdr_value, 1.0f);
    float ratio = log2((hdr_value + kcons) / (sdr_value + kcons));
    ratio = ratio / log2(hdrmax);
    ratio = min(ratio, 1.0f);
    return ratio;
}

extern "C" float4 RGBGainMapFilter(coreimage::sample_t hdr, coreimage::sample_t sdr,float hdrmax, coreimage::destination dest)
{
    float r_ratio = process_channel(hdr.r, sdr.r, hdrmax);
    float g_ratio = process_channel(hdr.g, sdr.g, hdrmax);
    float b_ratio = process_channel(hdr.b, sdr.b, hdrmax);
    return float4(r_ratio, g_ratio, b_ratio, 1.0f);
}



