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
    float hdr_m;
    float sdr_m;
    float m;
    
    m = (hdr.r > hdr.g) ? hdr.r : hdr.g;
    hdr_m = (m > hdr.b)? m : hdr.b;
    
    m = (sdr.r > sdr.g) ? sdr.r : sdr.g;
    sdr_m = (m > sdr.b)? m : sdr.b;
    
    if (sdr_m <= 0.0) {
        ratio = 1.0;
    } else {
        ratio = hdr_m/sdr_m;
    }
    ratio = (ratio - 1.0)/(hdrmax - 1.0);
    
    if (ratio < 0.018) {
        gamma_ratio = 4.5 * ratio;
    } else {
        gamma_ratio = 1.099*pow(ratio,0.45)-0.099;
    }

    return float4(gamma_ratio, gamma_ratio, gamma_ratio, 1.0);
}



