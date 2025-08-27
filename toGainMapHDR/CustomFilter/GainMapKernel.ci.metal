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
    float hdr_ave;
    float sdr_ave;
    float m;
    
    m = (hdr.r > hdr.g) ? hdr.r : hdr.g;
    hdr_ave = (m > hdr.b)? m : hdr.b;
    
    m = (sdr.r > sdr.g) ? sdr.r : sdr.g;
    sdr_ave = (m > sdr.b)? m : sdr.b;
    
    if (sdr_ave <= 0.0) {
        ratio = 1.0;
    } else {
        ratio = hdr_ave/sdr_ave;
    }
    gamma_ratio = sqrt((ratio - 1.0)/(hdrmax - 1.0));

    return float4(gamma_ratio, gamma_ratio, gamma_ratio, 1.0);
}



