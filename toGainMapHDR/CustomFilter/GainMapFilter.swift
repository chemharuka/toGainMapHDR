//
//  GainMapFilter.swift
//  toGainMapHDR
//
//  Created by Luyao Peng on 11/27/24.
//

import CoreImage

class GainMapFilter: CIFilter {
    var HDRImage: CIImage?
    var SDRImage: CIImage?
    var hdrmax: Float?
    static var kernel: CIKernel = { () -> CIColorKernel in
        guard let url = Bundle.main.url(
              forResource: "GainMapKernel.ci",
              withExtension: "metallib"),
              let data = try? Data(contentsOf: url) else {
              fatalError("Unable to load metallib")
            }
        
        guard let kernel = try? CIColorKernel(
              functionName: "GainMapFilter",
              fromMetalLibraryData: data) else {
              fatalError("Unable to create color kernel")
            }
        return kernel
    }()
    override var outputImage: CIImage? {
        guard let HDRImage = HDRImage else { return nil }
        guard let SDRImage = SDRImage else { return nil }
        guard let hdrmax = hdrmax else { return nil }
        return GainMapFilter.kernel.apply(extent: HDRImage.extent,
                                          roiCallback: { _, rect in return rect},
                                          arguments: [HDRImage,SDRImage,hdrmax])
      }
}
