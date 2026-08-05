//
//  toGainMapHDR
//  This code will convert HDR photo to gain map HDR photo.
//
//  Created by Luyao Peng on 2024/9/27. Distributed under MIT license.
//

import CoreImage
import Foundation
import CoreImage.CIFilterBuiltins
import ImageIO
import UniformTypeIdentifiers

// MARK: - Image Utilities

func lanczosResizeImage(_ image: CIImage) -> CIImage {
    let lanczosScaleFilter = CIFilter.lanczosScaleTransform()
    lanczosScaleFilter.inputImage = image
    lanczosScaleFilter.scale = 0.5
    lanczosScaleFilter.aspectRatio = 1
    return lanczosScaleFilter.outputImage!
}

func maxLuminance(_ image: CIImage, using context: CIContext) -> Float? {
    let extent = image.extent
    let filter = CIFilter.areaMaximum()
    filter.inputImage = image
    filter.extent = extent
    
    guard let outputImage = filter.outputImage else { return nil }
    
    var bitmap = [Float](repeating: 0, count: 4)
    context.render(outputImage,
                   toBitmap: &bitmap,
                   rowBytes: MemoryLayout<Float>.size * 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBAf,
                   colorSpace: nil)
    
    let r = bitmap[0]
    let g = bitmap[1]
    let b = bitmap[2]
    return max(r, g, b)
}

func makeEvenSized(_ image: CIImage, isCropped: inout Bool) -> CIImage {
    let extent = image.extent
    var newWidth = Int(extent.width)
    var newHeight = Int(extent.height)
    
    if newWidth == 1 || newHeight == 1 {
        print("Error: Unable to process image with one pixel height/width.")
        exit(1)
    }
    
    if newWidth % 2 != 0 { newWidth -= 1 }
    if newHeight % 2 != 0 { newHeight -= 1 }
    
    if newWidth == Int(extent.width) && newHeight == Int(extent.height) {
        return image
    }
    
    let newRect = CGRect(x: extent.origin.x, y: extent.origin.y,
                         width: CGFloat(newWidth), height: CGFloat(newHeight))
    if !isCropped {
        print("Warning: Subsampling gain map requires even width/height, cropped 1 pixel.")
        isCropped = true
    }
    return image.cropped(to: newRect)
}

// MARK: - Custom Filters (provided externally)

private func getGainMap(hdr_input: CIImage, sdr_input: CIImage, hdr_max: Float) -> CIImage {
    let filter = GainMapFilter()
    filter.HDRImage = hdr_input
    filter.SDRImage = sdr_input
    filter.hdrmax = hdr_max
    return filter.outputImage!
}

private func getRGBGainMap(hdr_input: CIImage, sdr_input: CIImage, hdr_max: Float) -> CIImage {
    let filter = RGBGainMapFilter()
    filter.HDRImage = hdr_input
    filter.SDRImage = sdr_input
    filter.hdrmax = hdr_max
    return filter.outputImage!
}

// MARK: - Configuration

struct Configuration {
    var sourceURL: URL
    var destinationFolder: URL
    var baseImageURL: URL?
    
    var imageQuality: Double = 0.85
    var toneMappingRatio: Float = 3.0
    var maxHeadroom: Float = 6.0
    
    var useToneMappingRatio: Bool = false
    var useBaseImage: Bool = false
    
    var exportSDR: Bool = false
    var exportPQ: Bool = false
    var exportHLG: Bool = false
    var exportAppleGainMap: Bool = false
    var exportMonochrome: Bool = false
    var subsampleGainMap: Bool = false
    
    var eightBit: Bool = false
    var tenBit: Bool = false
    
    var additionalText: String?
    
    var sdrColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
    var hdrColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.displayP3_PQ)!
    var hlgColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.displayP3_HLG)!
}

// MARK: - Argument Parsing

let helpInfo = """
Usage: toGainMapHDR <source file> <destination folder> <options>
       default: output HDR-heic with ISO gain map in RGB
       options:
         -q <value>: image quality (default: 0.85)
         -r <value>: SDR tone mapping ratio (≥ 1.0, default: 3.0)
             ratio = 1.0: keep full highlight details
             ratio >> 100: lose all highlight details
         -R <value>: max headroom for tone mapping (default: 6.0)
         -b <file_path>: specify base image
         -t <text>: add extra text after the output file name
         -c <color space>: specify output color space (srgb, p3, rec2020)
         -d <color depth>: specify output color depth (default: 8)
         -g: output Apple gain map HDR
         -m: output HDR-heic with ISO gain map in monochrome
         -H: subsampling gain map to half size
         -s: output tone mapped SDR image
         -p: output 10 bit PQ HDR heic image
         -h: output HLG HDR heic image (default in 10bit)
         -help: print help information
"""

func parseArguments(_ args: [String]) -> Configuration {
    guard args.count > 2 else {
        print(helpInfo)
        exit(1)
    }
    
    let sourceURL = URL(fileURLWithPath: args[1])
    let destinationFolder = URL(fileURLWithPath: args[2])
    let options = Array(args.dropFirst(3))
    
    var config = Configuration(sourceURL: sourceURL,
                               destinationFolder: destinationFolder)
    
    var index = 0
    while index < options.count {
        let option = options[index]
        switch option {
        case "-q":
            guard index + 1 < options.count else {
                print("Error: The -q option requires a valid numeric value.")
                exit(1)
            }
            if let value = Double(options[index + 1]) {
                config.imageQuality = value > 1 ? value / 100 : value
                index += 1
            } else {
                print("Error: The -q option requires a valid numeric value.")
                exit(1)
            }
        case "-r":
            guard index + 1 < options.count else {
                print("Error: The -r option requires a valid numeric value.")
                exit(1)
            }
            if let value = Float(options[index + 1]) {
                config.useToneMappingRatio = true
                config.toneMappingRatio = value
                index += 1
            } else {
                print("Error: The -r option requires a valid numeric value.")
                exit(1)
            }
        case "-R":
            guard index + 1 < options.count else {
                print("Error: The -R option requires a valid numeric value.")
                exit(1)
            }
            if let value = Float(options[index + 1]) {
                config.maxHeadroom = value
                index += 1
            } else {
                print("Error: The -R option requires a valid numeric value.")
                exit(1)
            }
        case "-b":
            guard index + 1 < options.count else {
                print("Error: The -b option requires an argument.")
                exit(1)
            }
            config.baseImageURL = URL(fileURLWithPath: options[index + 1])
            config.useBaseImage = true
            index += 1
        case "-s":
            config.exportSDR = true
        case "-p":
            config.exportPQ = true
        case "-h":
            config.exportHLG = true
        case "-m":
            config.exportMonochrome = true
        case "-H":
            config.subsampleGainMap = true
        case "-g":
            config.exportAppleGainMap = true
        case "-d":
            guard index + 1 < options.count else {
                print("Error: The -d option requires an argument.")
                exit(1)
            }
            let bitDepth = options[index + 1]
            if bitDepth == "8" {
                config.eightBit = true
                index += 1
            } else if bitDepth == "10" {
                config.tenBit = true
                index += 1
            } else {
                print("Error: Color depth must be either 8 or 10.")
                exit(1)
            }
        case "-t":
            guard index + 1 < options.count else {
                print("Error: The -n option requires an argument.")
                exit(1)
            }
            config.additionalText = options[index + 1]
            index += 1
        case "-c":
            guard index + 1 < options.count else {
                print("Error: The -c option requires color space argument.")
                exit(1)
            }
            let colorSpaceArg = options[index + 1].lowercased()
            switch colorSpaceArg {
            case "srgb","709","rec709","rec.709","bt709","bt.709","itu709":
                config.sdrColorSpace = CGColorSpace(name: CGColorSpace.itur_709)!
                config.hdrColorSpace = CGColorSpace(name: CGColorSpace.itur_709_PQ)!
                config.hlgColorSpace = CGColorSpace(name: CGColorSpace.itur_709_HLG)!
            case "p3","dcip3","dci-p3","dci.p3","displayp3":
                config.sdrColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
                config.hdrColorSpace = CGColorSpace(name: CGColorSpace.displayP3_PQ)!
                config.hlgColorSpace = CGColorSpace(name: CGColorSpace.displayP3_HLG)!
            case "rec2020","2020","rec.2020","bt2020","itu2020","2100","rec2100","rec.2100":
                config.sdrColorSpace = CGColorSpace(name: CGColorSpace.itur_2020_sRGBGamma)!
                config.hdrColorSpace = CGColorSpace(name: CGColorSpace.itur_2100_PQ)!
                config.hlgColorSpace = CGColorSpace(name: CGColorSpace.itur_2100_HLG)!
            default:
                print("Error: The -c option requires color space argument. (srgb, p3, rec2020)")
                exit(1)
            }
            index += 1
        case "-help":
            print(helpInfo)
            exit(1)
        default:
            print("Warning: Unknown option: \(option)")
        }
        index += 1
    }
    
    return config
}

// MARK: - Validation

func validateConfiguration(_ config: inout Configuration) {
    let activeOutputs = [config.exportPQ, config.exportHLG, config.exportSDR,
                         config.exportAppleGainMap, config.exportMonochrome].filter { $0 }
    if activeOutputs.count >= 2 {
        print("Error: Only one export format can be used.")
        exit(1)
    }
    if config.toneMappingRatio < 1.0 {
        print("Error: The -r option requires a valid numeric value.")
        exit(1)
    }
    if config.imageQuality < 0 || config.imageQuality > 1 {
        print("Error: The -q option requires a valid numeric value.")
        exit(1)
    }
    if config.maxHeadroom < 1.0 {
        print("Error: The -R option requires a valid numeric value.")
        exit(1)
    }
    if config.useBaseImage && config.exportMonochrome {
        print("Warning: Base image specified, will use RGB gain map.")
        config.exportMonochrome = false
    }
    if config.useBaseImage && config.exportAppleGainMap {
        print("Warning: Base image specified, will use RGB gain map.")
        config.exportAppleGainMap = false
    }
    if config.exportHLG && config.eightBit { print("Warning: Suggested to use 10-bit with HLG.") }
    if config.exportPQ && config.eightBit { print("Warning: Color depth will be 10 when exporting PQ HDR.") }
    if config.useToneMappingRatio && config.useBaseImage { print("Warning: Base image specified, tone mapping ratio will not be applied.") }
    if config.useToneMappingRatio && config.exportHLG { print("Warning: Tone mapping ratio will not be applied when exporting HLG HDR image.") }
    if config.useToneMappingRatio && config.exportPQ { print("Warning: Tone mapping ratio will not be applied when exporting PQ HDR image.") }
}

// MARK: - Image Preparation & SDR Generation

/// Returns (picHeadroom, headroomRatio) and may modify hdrImage and config.
func prepareHDRImage(config: inout Configuration, hdrImage: inout CIImage) -> (picHeadroom: Float, headroomRatio: Float) {
    var isCropped = false
    if config.subsampleGainMap {
        hdrImage = makeEvenSized(hdrImage, isCropped: &isCropped)
    }
    
    let ctx = CIContext()
    var headroomRatio: Float = config.maxHeadroom
    var picHeadroom: Float = 1.0
    
    // Heuristics disabled when a base image is used and no subsampling is required
    if !(config.useBaseImage && !config.subsampleGainMap) {
        let transform = CGAffineTransform(scaleX: 1.0 / CGFloat(config.toneMappingRatio),
                                          y: 1.0 / CGFloat(config.toneMappingRatio))
        guard let picHeadroomVal = maxLuminance(hdrImage, using: ctx),
              let picHeadroom2Val = maxLuminance(hdrImage.transformed(by: transform), using: ctx) else {
            // fallback
            return (1.0, config.maxHeadroom)
        }
        picHeadroom = picHeadroomVal
        let picHeadroom2 = max(picHeadroom2Val, 1.0)
        
        if picHeadroom < 1.05 {
            print("Warning: Picture headroom < 1.05, this is an SDR image, outputing SDR image.")
            config.exportSDR = true
            config.useBaseImage = false
            headroomRatio = 1.0
        } else {
            if picHeadroom2 > headroomRatio {
                print("Warning: Picture headroom > max headroom (set with -R parameter), highlight clipped.")
            } else {
                headroomRatio = picHeadroom2
            }
            if config.maxHeadroom > picHeadroom {
                config.maxHeadroom = picHeadroom
            }
        }
    }
    return (picHeadroom, headroomRatio)
}

func generateSDRImage(hdrImage: CIImage, config: Configuration, headroomRatio: Float) -> CIImage? {
    if config.useBaseImage {
        if let baseURL = config.baseImageURL,
           let baseImage = CIImage(contentsOf: baseURL) {
            var isCropped = false
            let adjustedBase = config.subsampleGainMap ? makeEvenSized(baseImage, isCropped: &isCropped) : baseImage
            if isCropped { print("Warning: Subsampling gain map requires even width/height, cropped 1 pixel.") }
            if adjustedBase.extent != hdrImage.extent {
                print("Warning: Size of base image is different, will generate base image by tone mapping.")
                return hdrImage.applyingFilter("CIToneMapHeadroom",
                                               parameters: ["inputSourceHeadroom": headroomRatio,
                                                            "inputTargetHeadroom": 1.0])
            }
            return adjustedBase
        } else {
            print("Warning: Could not load base image, will generate base image by tone mapping.")
            // Falls through to tone mapping below
        }
    }
    return hdrImage.applyingFilter("CIToneMapHeadroom",
                                   parameters: ["inputSourceHeadroom": headroomRatio,
                                                "inputTargetHeadroom": 1.0])
}

// MARK: - Export Functions

func exportHLG(_ image: CIImage, config: Configuration, destination: URL) {
    let exportOptions = NSDictionary(dictionary: [kCGImageDestinationLossyCompressionQuality: config.imageQuality])
    if config.eightBit {
        try! CIContext().writeHEIFRepresentation(of: image,
                                                to: destination,
                                                format: .RGBA8,
                                                colorSpace: config.hlgColorSpace,
                                                options: exportOptions as! [CIImageRepresentationOption : Any])
    } else {
        try! CIContext().writeHEIF10Representation(of: image,
                                                  to: destination,
                                                  colorSpace: config.hlgColorSpace,
                                                  options: exportOptions as! [CIImageRepresentationOption : Any])
    }
}

func exportPQ(_ image: CIImage, config: Configuration, destination: URL) {
    let exportOptions = NSDictionary(dictionary: [kCGImageDestinationLossyCompressionQuality: config.imageQuality])
    try! CIContext().writeHEIF10Representation(of: image,
                                              to: destination,
                                              colorSpace: config.hdrColorSpace,
                                              options: exportOptions as! [CIImageRepresentationOption : Any])
}

func exportSDR(_ sdrImage: CIImage, config: Configuration, destination: URL) {
    let exportOptions = NSDictionary(dictionary: [kCGImageDestinationLossyCompressionQuality: config.imageQuality])
    if config.tenBit {
        try! CIContext().writeHEIF10Representation(of: sdrImage,
                                                  to: destination,
                                                  colorSpace: config.sdrColorSpace,
                                                  options: exportOptions as! [CIImageRepresentationOption : Any])
    } else {
        try! CIContext().writeHEIFRepresentation(of: sdrImage,
                                                to: destination,
                                                format: .RGBA8,
                                                colorSpace: config.sdrColorSpace,
                                                options: exportOptions as! [CIImageRepresentationOption : Any])
    }
}

func exportISOYUVGainMap(sdrImage: CIImage, hdrImage: CIImage, config: Configuration, destination: URL) {
    let exportOptions = NSDictionary(dictionary: [
        kCGImageDestinationLossyCompressionQuality: config.imageQuality,
        CIImageRepresentationOption.hdrImage: hdrImage,
        CIImageRepresentationOption.hdrGainMapAsRGB: !config.exportMonochrome
    ])
    if config.tenBit {
        try! CIContext().writeHEIF10Representation(of: sdrImage,
                                                   to: destination,
                                                   colorSpace: config.sdrColorSpace,
                                                   options: exportOptions as! [CIImageRepresentationOption : Any])
    } else {
        try! CIContext().writeHEIFRepresentation(of: sdrImage,
                                                 to: destination,
                                                 format: .RGBA8,
                                                 colorSpace: config.sdrColorSpace,
                                                 options: exportOptions as! [CIImageRepresentationOption : Any])
    }
}

func exportAppleGainMap(hdrImage: CIImage, sdrImage: CIImage, config: Configuration, destination: URL) {
    var gainMap = getGainMap(hdr_input: hdrImage, sdr_input: sdrImage, hdr_max: config.maxHeadroom)
    if config.subsampleGainMap {
        gainMap = lanczosResizeImage(gainMap)
    }
    
    let stops = log2(config.maxHeadroom)
    var imageProperties = hdrImage.properties
    var makerApple = imageProperties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] ?? [:]
    
    switch stops {
    case let x where x >= 2.3:
        makerApple["33"] = 1.0
        makerApple["48"] = (3.0 - stops) / 70.0
    case 1.8..<2.3:
        makerApple["33"] = 1.0
        makerApple["48"] = (2.30303 - stops) / 0.303
    case 1.6..<1.8:
        makerApple["33"] = 0.0
        makerApple["48"] = (1.80 - stops) / 20.0
    default:
        makerApple["33"] = 0.0
        makerApple["48"] = (1.60101 - stops) / 0.101
    }
    
    imageProperties[kCGImagePropertyMakerAppleDictionary as String] = makerApple
    let modifiedSDR = sdrImage.settingProperties(imageProperties)
    
    let exportOptions = NSDictionary(dictionary: [
        kCGImageDestinationLossyCompressionQuality: config.imageQuality,
        CIImageRepresentationOption.hdrGainMapImage: gainMap
    ])
    
    if config.tenBit {
        try! CIContext().writeHEIF10Representation(of: modifiedSDR,
                                                   to: destination,
                                                   colorSpace: config.sdrColorSpace,
                                                   options: exportOptions as! [CIImageRepresentationOption : Any])
    } else {
        try! CIContext().writeHEIFRepresentation(of: modifiedSDR,
                                                 to: destination,
                                                 format: .RGBA8,
                                                 colorSpace: config.sdrColorSpace,
                                                 options: exportOptions as! [CIImageRepresentationOption : Any])
    }
}

func exportSubsampledGainMap(hdrImage: CIImage, sdrImage: CIImage, config: Configuration,
                             destination: URL, picHeadroom: Float) {
    let context = CIContext()
    let rgbGainMap = getRGBGainMap(hdr_input: hdrImage, sdr_input: sdrImage, hdr_max: picHeadroom)
    let resizedGainMap = lanczosResizeImage(rgbGainMap)
    
    let width = Int(resizedGainMap.extent.width)
    let height = Int(resizedGainMap.extent.height)
    
    var gainMapDataMono = Data(count: height * width)
    var gainMapDataRGB = Data(count: height * width * 4)
    
    // defaultHDRMetadata is assumed to be defined elsewhere (original code)
    let xmlStr = defaultHDRMetadata(GainMapMax: log2(picHeadroom), GainMapMin: 0.0,
                                    RGBType: config.exportMonochrome ? 2 : 1)
    let xmlData = xmlStr.data(using: .utf8)!
    let metadata = CGImageMetadataCreateFromXMPData(xmlData as CFData)
    
    let dest = CGImageDestinationCreateWithURL(destination as CFURL,
                                               UTType.heic.identifier as CFString,
                                               1, nil)!
    
    let sdrCGFormat: CIFormat = config.tenBit ? .RGB10 : .RGBA8
    guard let sdrCG = context.createCGImage(sdrImage, from: sdrImage.extent,
                                            format: sdrCGFormat,
                                            colorSpace: config.sdrColorSpace) else {
        print("Error: Could not create CGImage for SDR base.")
        exit(1)
    }
    
    var exportOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: config.imageQuality]
    let properties = hdrImage.properties
    for (key, value) in properties {
        exportOptions[key as CFString] = value
    }
    
    if config.exportMonochrome {
        gainMapDataMono.withUnsafeMutableBytes {
            context.render(resizedGainMap, toBitmap: $0.baseAddress!,
                           rowBytes: width,
                           bounds: resizedGainMap.extent,
                           format: .L8,
                           colorSpace: CGColorSpace(name: CGColorSpace.linearGray)!)
        }
        let auxDict: [CFString: Any] = [
            kCGImageAuxiliaryDataInfoData: gainMapDataMono,
            kCGImageAuxiliaryDataInfoMetadata: metadata!,
            kCGImageAuxiliaryDataInfoDataDescription: [
                "PixelFormat": 1278226488,
                "Width": "\(width)",
                "Height": "\(height)",
                "BytesPerRow": "\(width)"
            ],
            kCGImageAuxiliaryDataInfoColorSpace: config.sdrColorSpace
        ]
        CGImageDestinationAddImage(dest, sdrCG, exportOptions as CFDictionary)
        CGImageDestinationAddAuxiliaryDataInfo(dest,
                                               kCGImageAuxiliaryDataTypeISOGainMap,
                                               auxDict as CFDictionary)
    } else {
        gainMapDataRGB.withUnsafeMutableBytes {
            context.render(resizedGainMap, toBitmap: $0.baseAddress!,
                           rowBytes: width * 4,
                           bounds: resizedGainMap.extent,
                           format: .ARGB8,
                           colorSpace: CGColorSpace(name: CGColorSpace.linearITUR_2020)!)
        }
        let auxDict: [CFString: Any] = [
            kCGImageAuxiliaryDataInfoData: gainMapDataRGB,
            kCGImageAuxiliaryDataInfoMetadata: metadata!,
            kCGImageAuxiliaryDataInfoDataDescription: [
                "PixelFormat": 32,
                "Width": "\(width)",
                "Height": "\(height)",
                "BytesPerRow": "\(width * 4)"
            ],
            kCGImageAuxiliaryDataInfoColorSpace: config.sdrColorSpace
        ]
        CGImageDestinationAddImage(dest, sdrCG, exportOptions as CFDictionary)
        CGImageDestinationAddAuxiliaryDataInfo(dest,
                                               kCGImageAuxiliaryDataTypeISOGainMap,
                                               auxDict as CFDictionary)
    }
    
    guard CGImageDestinationFinalize(dest) else {
        print("Error: Could not finalize image destination.")
        exit(1)
    }
}

// MARK: - Main processing pipeline

func process(_ config: Configuration) {
    // Load HDR image
    guard let hdrImage = CIImage(contentsOf: config.sourceURL, options: [.expandToHDR: true]) else {
        print("Error: No input image found.")
        exit(1)
    }
    
    // Determine color spaces from the image if not already forced
    var mutableConfig = config
    let imageColorSpaceStr = String(describing: hdrImage.colorSpace)
    if imageColorSpaceStr.contains("709") || imageColorSpaceStr.contains("sRGB") {
        mutableConfig.sdrColorSpace = CGColorSpace(name: CGColorSpace.itur_709)!
        mutableConfig.hdrColorSpace = CGColorSpace(name: CGColorSpace.itur_709_PQ)!
        mutableConfig.hlgColorSpace = CGColorSpace(name: CGColorSpace.itur_709_HLG)!
    } else if imageColorSpaceStr.contains("2100") || imageColorSpaceStr.contains("2020") {
        mutableConfig.sdrColorSpace = CGColorSpace(name: CGColorSpace.itur_2020_sRGBGamma)!
        mutableConfig.hdrColorSpace = CGColorSpace(name: CGColorSpace.itur_2100_PQ)!
        mutableConfig.hlgColorSpace = CGColorSpace(name: CGColorSpace.itur_2100_HLG)!
    }
    
    // Build output filename
    let ext = ".heic"
    let baseName = config.sourceURL.deletingPathExtension().lastPathComponent
    let additional = config.additionalText ?? ""
    let filename = additional.isEmpty ? baseName + ext : baseName + additional + ext
    let destinationURL = config.destinationFolder.appendingPathComponent(filename)
    
    // HLG / PQ shortcuts
    if config.exportHLG {
        exportHLG(hdrImage, config: mutableConfig, destination: destinationURL)
        exit(0)
    }
    if config.exportPQ {
        exportPQ(hdrImage, config: mutableConfig, destination: destinationURL)
        exit(0)
    }
    
    // Prepare HDR image and compute headroom
    var hdrImageMutable = hdrImage
    let (picHeadroom, headroomRatio) = prepareHDRImage(config: &mutableConfig,
                                                       hdrImage: &hdrImageMutable)
    
    // Generate SDR base image
    guard let sdrImage = generateSDRImage(hdrImage: hdrImageMutable,
                                          config: mutableConfig,
                                          headroomRatio: headroomRatio) else {
        print("Error: Could not create SDR base image.")
        exit(1)
    }
    
    // SDR export
    if config.exportSDR {
        exportSDR(sdrImage, config: mutableConfig, destination: destinationURL)
        exit(0)
    }
    
    // Apple gain map
    if config.exportAppleGainMap {
        exportAppleGainMap(hdrImage: hdrImageMutable, sdrImage: sdrImage,
                           config: mutableConfig, destination: destinationURL)
        exit(0)
    }
    
    // Subsampled (non‑Apple) gain map
    if !config.exportAppleGainMap && config.subsampleGainMap {
        exportSubsampledGainMap(hdrImage: hdrImageMutable, sdrImage: sdrImage,
                                config: mutableConfig, destination: destinationURL,
                                picHeadroom: picHeadroom)
        exit(0)
    }
    
    // Default: YUV gain map (ISO gain map via CIImage)
    exportISOYUVGainMap(sdrImage: sdrImage, hdrImage: hdrImageMutable,
                        config: mutableConfig, destination: destinationURL)
    exit(0)
}

// MARK: - Entry point

let args = CommandLine.arguments
var config = parseArguments(args)
validateConfiguration(&config)
process(config)
