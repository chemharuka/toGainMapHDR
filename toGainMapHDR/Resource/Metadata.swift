//
//  Metadata.swift
//  toGainMapHDR
//
//  Created by Luyao Peng on 13/4/2026.
//
import Foundation

func defaultHDRMetadata(GainMapMax: Float, GainMapMin: Float, RGBType: Int) -> String {
    func channelBlock(_ maxStr: String, _ minStr: String) -> String {
        return """
            <rdf:li rdf:parseType="Resource">
               <HDRToneMap:GainMapMin>\(minStr)</HDRToneMap:GainMapMin>
               <HDRToneMap:GainMapMax>\(maxStr)</HDRToneMap:GainMapMax>
               <HDRToneMap:Gamma>1.000000</HDRToneMap:Gamma>
               <HDRToneMap:BaseOffset>0.000010</HDRToneMap:BaseOffset>
               <HDRToneMap:AlternateOffset>0.000010</HDRToneMap:AlternateOffset>
            </rdf:li>
            """
    }

    func toneMapHeader(_ channels: String) -> String {
        return """
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
              <rdf:Description rdf:about=""
                    xmlns:HDRToneMap="http://ns.apple.com/HDRToneMap/1.0/">
                 <HDRToneMap:Version>1</HDRToneMap:Version>
                 <HDRToneMap:BaseHeadroom>0.000000</HDRToneMap:BaseHeadroom>
                 <HDRToneMap:AlternateHeadroom>2.300450</HDRToneMap:AlternateHeadroom>
                 <HDRToneMap:ChannelMetadata>
                    <rdf:Seq>
        \(channels)
                    </rdf:Seq>
                 </HDRToneMap:ChannelMetadata>
                 <HDRToneMap:BaseColorIsWorkingColor>True</HDRToneMap:BaseColorIsWorkingColor>
              </rdf:Description>
           </rdf:RDF>
        </x:xmpmeta>
        """
    }

    let maxStr = String(format: "%.6f", GainMapMax)
    let minStr = String(format: "%.6f", GainMapMin)

    switch RGBType {
    case 1: // RGB - 3 channels
        let channel = channelBlock(maxStr, minStr)
        return toneMapHeader(channel + channel + channel)
    case 2: // Mono - 1 channel
        return toneMapHeader(channelBlock(maxStr, minStr))
    case 3: // Apple
        let appleMax = String(format: "%.5f", GainMapMax)
        return """
        <x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XMP Core 6.0.0">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
              <rdf:Description rdf:about=""
                    xmlns:HDRGainMap="http://ns.apple.com/HDRGainMap/1.0/">
                 <HDRGainMap:HDRGainMapVersion>131072</HDRGainMap:HDRGainMapVersion>
                 <HDRGainMap:HDRGainMapHeadroom>\(appleMax)</HDRGainMap:HDRGainMapHeadroom>
              </rdf:Description>
           </rdf:RDF>
        </x:xmpmeta>
        """
    default:
        print("Warning: Unknown RGB type")
        exit(0)
    }
}
