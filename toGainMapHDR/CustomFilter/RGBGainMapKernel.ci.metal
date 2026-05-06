//
//  RGBGainMap.ci.metal
//  toGainMapHDR
//
//  Created by Luyao Peng on 11/27/24.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" float4 RGBGainMapFilter(coreimage::sample_t hdr, coreimage::sample_t sdr,float hdrmax, coreimage::destination dest)
{
    float r_ratio;
    float g_ratio;
    float b_ratio;
    
    sdr.r = sdr.r > 1.0f ? 1.0f : sdr.r;
    sdr.g = sdr.g > 1.0f ? 1.0f : sdr.g;
    sdr.b = sdr.b > 1.0f ? 1.0f : sdr.b;

    r_ratio = log2((hdr.r + 0.000010)/(sdr.r + 0.000010));
    g_ratio = log2((hdr.g + 0.000010)/(sdr.g + 0.000010));
    b_ratio = log2((hdr.b + 0.000010)/(sdr.b + 0.000010));
    
    r_ratio = r_ratio/log2(hdrmax);
    g_ratio = g_ratio/log2(hdrmax);
    b_ratio = b_ratio/log2(hdrmax);
    
    r_ratio = r_ratio > 1.0f ? 1.0f : r_ratio;
    g_ratio = g_ratio > 1.0f ? 1.0f : g_ratio;
    b_ratio = b_ratio > 1.0f ? 1.0f : b_ratio;


    return float4(r_ratio, g_ratio, b_ratio, 1.0);
}



