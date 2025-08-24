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
    float empirical_value;
    
    hdr_ave = (hdr.r+hdr.g+hdr.b)/3.0;
    sdr_ave = (sdr.r+sdr.g+sdr.b)/3.0;
    if (sdr_ave <= 0.0) {
        ratio = 1.0;
    } else {
        ratio = hdr_ave/sdr_ave;
    }
    empirical_value = 0.000168697 * hdrmax * hdrmax + 0.0019267 * hdrmax + 0.70251 - 0.24649/hdrmax ;
    
    gamma_ratio = pow((sqrt(ratio)-1.0)/(sqrt(hdrmax)-1.0),empirical_value);
    
    return float4(gamma_ratio, gamma_ratio, gamma_ratio, 1.0);
}



