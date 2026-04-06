//
//  GainMap.ci.metal
//  toGainMapHDR
//
//  Created by Luyao Peng on 11/27/24.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" float4 GainMapFilter(coreimage::sample_t hdr, coreimage::sample_t sdr,float hdrmax, coreimage::destination dest)
{
    float gamma_ratio;
    float ratio;
    float hdr_lux;
    float sdr_lux;
    
    hdr_lux = hdr.r * 0.2126 +  hdr.g * 0.7152 + hdr.b * 0.0722;
    sdr_lux = sdr.r * 0.2126 +  sdr.g * 0.7152 + sdr.b * 0.0722;
    
    if (sdr_lux <= 0.0) {
        ratio = 1.0;
    } else {
        ratio = hdr_lux/sdr_lux;
    }
    ratio = (ratio - 1.0)/(hdrmax - 1.0);
    
    if (ratio > 1.0) {
        ratio = 1.0;
    }
    
    if (ratio < 0.018) {
        gamma_ratio = 4.5 * ratio;
    } else {
        gamma_ratio = 1.099*pow(ratio,0.45)-0.099;
    }

    return float4(gamma_ratio, gamma_ratio, gamma_ratio, 1.0);
}



