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
    
    if (sdr.r > 1.0) {
        sdr.r = 1.0;
    }
    if (sdr.g > 1.0) {
        sdr.g = 1.0;
    }
    if (sdr.b > 1.0) {
        sdr.b = 1.0;
    }

    r_ratio = log2((hdr.r + 0.000010)/(sdr.r + 0.000010));
    g_ratio = log2((hdr.g + 0.000010)/(sdr.g + 0.000010));
    b_ratio = log2((hdr.b + 0.000010)/(sdr.b + 0.000010));
    
    r_ratio = r_ratio/log2(hdrmax);
    g_ratio = g_ratio/log2(hdrmax);
    b_ratio = b_ratio/log2(hdrmax);
    
    if (r_ratio > 1.0) {
        r_ratio = 1.0;
    }
    if (g_ratio > 1.0) {
        g_ratio = 1.0;
    }
    if (b_ratio > 1.0) {
        b_ratio = 1.0;
    }
    

    return float4(r_ratio, g_ratio, b_ratio, 1.0);
}



