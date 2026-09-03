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
import CoreVideo
import UniformTypeIdentifiers

let ctx = CIContext()
let helpInfo = """
Usage: toGainMapHDR <source file> <destination folder> <options>
       default: output HDR-heic with ISO gain map in RGB
       options:
         -q <value>: image quality (default: 0.85)
         -r <value>: SDR tone mapping ratio (≥ 1.0, default: 3.0)
             ratio = 1.0: keep full highlight details
             ratio >> 100: lose all highlight details
         -R <value>: max headroom for tone mapping (default: 6)
         -b <file_path>: specify base image
         -t <text>: add extra text after the output file name
         -c <color space>: specify output color space (srgb, p3, rec2020)
         -d <color depth>: specify output color depth (default: 8)
         -g: output Apple gain map HDR
         -m: export ISO Gain Map HDR in monochrome
         -H: subsampling gain map to half size
         -s: export tone mapped SDR image
         -p: export 10bit PQ HDR heic image
         -h: export HLG HDR heic image (default in 10bit)
         -help: print help information
"""

let arguments = CommandLine.arguments
guard arguments.count > 2 else {
    print(helpInfo)
    exit(2)
}

let hdrURL = URL(fileURLWithPath: arguments[1])
var filename = hdrURL.deletingPathExtension().appendingPathExtension("heic").lastPathComponent

let imageOptions = arguments.dropFirst(3)
var baseImageURL : URL?

var imageQuality: Double = 0.85
var toneMappingRatio: Float = 3.0
var maxHeadroom: Float = 6.0
var toneMappingRatioBool : Bool = false
var baseImageBool : Bool = false
var sdrExport: Bool = false
var pqExport: Bool = false
var hlgExport: Bool = false
var eightBit: Bool = false
var tenBit: Bool = false
var subsamplingBool : Bool = false
var appleGainMap: Bool = false
var hdrImage: CIImage
var monochromeExport: Bool = false
var isCropped : Bool = false

let readHDRImage = CIImage(contentsOf: hdrURL, options: [.expandToHDR: true])
if readHDRImage == nil {
    print("Error: No input image found.")
    exit(22)
}

hdrImage = readHDRImage!

var sdrColorSpace = CGColorSpace.displayP3
var hdrColorSpace = CGColorSpace.displayP3_PQ
var hlgColorSpace = CGColorSpace.displayP3_HLG

let imageColorSpace = String(describing: hdrImage.colorSpace)
if imageColorSpace.contains("709") {
    sdrColorSpace = CGColorSpace.itur_709
    hdrColorSpace = CGColorSpace.itur_709_PQ
    hlgColorSpace = CGColorSpace.itur_709_HLG
}
if imageColorSpace.contains("sRGB") {
    sdrColorSpace = CGColorSpace.itur_709
    hdrColorSpace = CGColorSpace.itur_709_PQ
    hlgColorSpace = CGColorSpace.itur_709_HLG
}
if imageColorSpace.contains("2100") {
    sdrColorSpace = CGColorSpace.itur_2020_sRGBGamma
    hdrColorSpace = CGColorSpace.itur_2100_PQ
    hlgColorSpace = CGColorSpace.itur_2100_HLG
}
if imageColorSpace.contains("2020") {
    sdrColorSpace = CGColorSpace.itur_2020_sRGBGamma
    hdrColorSpace = CGColorSpace.itur_2100_PQ
    hlgColorSpace = CGColorSpace.itur_2100_HLG
}

var index: Int = 0
while index < imageOptions.count {
    let option = arguments[index+3]
    switch option {
    case "-q":
        guard index + 1 < imageOptions.count else {
            print("Error: The -q option requires a valid numeric value.")
            exit(4)
        }
        if let value = Double(arguments[index + 4]) {
            if value > 1 {
                imageQuality = value/100
            } else {
                imageQuality = value
            }
            index += 1 // Skip the next value
        } else {
            print("Error: The -q option requires a valid numeric value.")
            exit(5)
        }
    case "-r":
        guard index + 1 < imageOptions.count else {
            print("Error: The -r option requires a valid numeric value.")
            exit(6)
        }
        if let value = Float(arguments[index + 4]) {
            toneMappingRatioBool = true
            toneMappingRatio = value
            index += 1 // Skip the next value
        } else {
            print("Error: The -r option requires a valid numeric value.")
            exit(7)
        }
    case "-R":
        guard index + 1 < imageOptions.count else {
            print("Error: The -R option requires a valid numeric value.")
            exit(8)
        }
        if let value = Float(arguments[index + 4]) {
            maxHeadroom = value
            index += 1 // Skip the next value
        } else {
            print("Error: The -R option requires a valid numeric value.")
            exit(9)
        }
    case "-b":
        guard index + 1 < imageOptions.count else {
            print("Error: The -b option requires an argument.")
            exit(10)
        }
        baseImageURL = URL(fileURLWithPath: arguments[index + 4])
        baseImageBool = true
        index += 1
    case "-s":
        sdrExport = true
    case "-p":
        pqExport = true
    case "-h":
        hlgExport = true
    case "-m":
        monochromeExport = true
    case "-H":
        subsamplingBool = true
    case "-g":
        appleGainMap = true
    case "-d":
        guard index + 1 < imageOptions.count else {
            print("Error: The -d option requires an argument.")
            exit(11)
        }
        let bitDepthArgument = String(arguments[index + 4])
        if bitDepthArgument == "8" {
            eightBit = true
            index += 1
        } else if bitDepthArgument == "10" {
            tenBit = true
            index += 1
        } else {
            print("Error: Color depth must be either 8 or 10.")
            exit(12)
        }
    case "-t":
        guard index + 1 < imageOptions.count else {
            print("Error: The -t option requires an argument.")
            exit(13)
        }
        let additionalFilename = String(arguments[index + 4])
        filename = URL(string: hdrURL.deletingPathExtension().absoluteString+additionalFilename)!
            .appendingPathExtension("heic").lastPathComponent
        index += 1
    case "-c":
        guard index + 1 < imageOptions.count else {
            print("Error: The -c option requires color space argument.")
            exit(14)
        }
        let colorSpaceArgument = String(arguments[index + 4])
        let colorSpaceOption = colorSpaceArgument.lowercased()
        switch colorSpaceOption {
            case "srgb","709","rec709","rec.709","bt709","bt.709","itu709":
                sdrColorSpace = CGColorSpace.itur_709
                hdrColorSpace = CGColorSpace.itur_709_PQ
                hlgColorSpace = CGColorSpace.itur_709_HLG
            case "p3","dcip3","dci-p3","dci.p3","displayp3":
                sdrColorSpace = CGColorSpace.displayP3
                hdrColorSpace = CGColorSpace.displayP3_PQ
                hlgColorSpace = CGColorSpace.displayP3_HLG
            case "rec2020","2020","rec.2020","bt2020","itu2020","2100","rec2100","rec.2100":
                sdrColorSpace = CGColorSpace.itur_2020_sRGBGamma
                hdrColorSpace = CGColorSpace.itur_2100_PQ
                hlgColorSpace = CGColorSpace.itur_2100_HLG
            default:
                print("Error: The -c option requires color space argument. (srgb, p3, rec2020)")
                exit(15)
        }
        index += 1
    case "-help":
        print(helpInfo)
        exit(2)
    default:
        print("Warning: Unknown option: \(option)")
    }
    index += 1
}


let exportPath = URL(fileURLWithPath: arguments[2])
let heicExportURL = exportPath.appendingPathComponent(filename)

if [pqExport, hlgExport, sdrExport, appleGainMap, monochromeExport].filter({$0}).count >= 2 {
    print("Error: Only one export format can be used.")
    exit(16)
}
if toneMappingRatio < 1.0 {
    print("Error: The -r option requires a valid numeric value.")
    exit(17)
}
if imageQuality < 0 || imageQuality > 1 {
    print("Error: The -q option requires a valid numeric value.")
    exit(18)
}
if maxHeadroom < 1.0 {
    print("Error: The -R option requires a valid numeric value.")
    exit(19)
}
if baseImageBool && monochromeExport {
    print("Warning: Base image specified, will use RGB gain map.")
    monochromeExport = false
}
if baseImageBool && appleGainMap {
    print("Warning: Base image specified, will use RGB gain map.")
    appleGainMap = false
}

if hlgExport && eightBit {print("Warning: Suggested to use 10-bit with HLG.")}
if pqExport && eightBit {print("Warning: Color depth will be 10 when exporting PQ HDR.")}
if toneMappingRatioBool && baseImageBool {print("Warning: Base image specified, tone mapping ratio will not be applied.")}
if toneMappingRatioBool && hlgExport {print("Warning: Tone mapping ratio will not be applied when exporting HLG HDR image.")}
if toneMappingRatioBool && pqExport {print("Warning: Tone mapping ratio will not be applied when exporting PQ HDR image.")}



// export hlg and pq hdr file
if hlgExport {
    let hlgExportOptions = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imageQuality])
    if eightBit {
        try! ctx.writeHEIFRepresentation(of: hdrImage,
                                         to: heicExportURL,
                                         format: CIFormat.RGBA8,
                                         colorSpace: CGColorSpace(name: hlgColorSpace)!,
                                         options:hlgExportOptions as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIF10Representation(of: hdrImage,
                                         to: heicExportURL,
                                         colorSpace: CGColorSpace(name: hlgColorSpace)!,
                                         options:hlgExportOptions as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

if pqExport {
    let pqExportOptions = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imageQuality])
    try! ctx.writeHEIF10Representation(of: hdrImage,
                                       to: heicExportURL,
                                       colorSpace: CGColorSpace(name: hdrColorSpace)!,
                                       options:pqExportOptions as! [CIImageRepresentationOption : Any])
    exit(0)
}


// Custom filter

private func getGainMap(hdrInput: CIImage, sdrInput: CIImage, hdrMax: Float) -> CIImage {
    let filter = GainMapFilter()
    filter.HDRImage = hdrInput
    filter.SDRImage = sdrInput
    filter.hdrmax = hdrMax
    let outputImage = filter.outputImage
    return outputImage!
}
private func getRGBGainMap(hdrInput: CIImage, sdrInput: CIImage, hdrMax: Float) -> CIImage {
    let filter = RGBGainMapFilter()
    filter.HDRImage = hdrInput
    filter.SDRImage = sdrInput
    filter.hdrmax = hdrMax
    let outputImage = filter.outputImage
    return outputImage!
}

func lanczosResizeImage(_ image: CIImage) -> CIImage {
    let lanczosScaleFilter = CIFilter.lanczosScaleTransform()
    lanczosScaleFilter.inputImage = image
    lanczosScaleFilter.scale = 0.5
    lanczosScaleFilter.aspectRatio = 1
    return lanczosScaleFilter.outputImage!
}

func maxLuminance(_ image: CIImage) -> Float? {
    let extent = image.extent
    let filter = CIFilter.areaMaximum()
    filter.inputImage = image
    filter.extent = extent
    
    guard let outputImage = filter.outputImage else { return nil }
    
    // Use floating point format to preserve HDR values
    var bitmap = [Float](repeating: 0, count: 4)
    ctx.render(outputImage,
                   toBitmap: &bitmap,
                   rowBytes: MemoryLayout<Float>.size * 4,
                   bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                   format: .RGBAf,
                   colorSpace: nil)
    
    let r = bitmap[0]
    let g = bitmap[1]
    let b = bitmap[2]
    
    let luminance: Float = max(r,g,b)
    return luminance
}

func makeEvenSized(_ image: CIImage) -> CIImage {
    let extent = image.extent
    var newWidth = Int(extent.width)
    var newHeight = Int(extent.height)
    
    if Int(extent.width) == 1 || Int(extent.height) == 1 {
        print("Error: Unable to process image with one pixel height/width.")
        exit(3)
    }
    
    if newWidth % 2 != 0 {
        newWidth -= 1
    }
    if newHeight % 2 != 0 {
        newHeight -= 1
    }
    
    if newWidth == Int(extent.width) && newHeight == Int(extent.height) {
        return image
    }
    
    let newRect = CGRect(
        x: extent.origin.x,
        y: extent.origin.y,
        width: CGFloat(newWidth),
        height: CGFloat(newHeight)
    )
    if !isCropped {
        print("Warning: Subsampling gain map requires even width/height, cropped 1 pixel.")
        isCropped = true
    }
    return image.cropped(to: newRect)
}


var picHeadroom : Float = 1.0
var picHeadroom2 : Float
var headroomRatio : Float = maxHeadroom

if subsamplingBool {
    hdrImage = makeEvenSized(hdrImage)
}

if !(baseImageBool && !subsamplingBool) {
    let transform = CGAffineTransform(scaleX: 1.0 / CGFloat(toneMappingRatio), y: 1.0 / CGFloat(toneMappingRatio))
    picHeadroom = maxLuminance(hdrImage)!
    picHeadroom2 = maxLuminance(hdrImage.transformed(by: transform))!

    if picHeadroom < 1.05 {
        print("Warning: Picture headroom < 1.05, this is an SDR image, outputting SDR image.")
        sdrExport = true
        baseImageBool = false
        headroomRatio = 1.0
    }

    if picHeadroom2 < 1.0 {
        picHeadroom2 = 1.0
    }
    
    if picHeadroom2 > headroomRatio {
        print("Warning: Picture headroom > max headroom (set with -R parameter), highlight clipped.")
    } else {
        headroomRatio = picHeadroom2
    }
    
    if maxHeadroom > picHeadroom {
        maxHeadroom = picHeadroom
    }
}

func generateSDRImage() -> CIImage?{
    if baseImageBool {
        if CIImage(contentsOf: baseImageURL!) == nil {
            print("Warning: Could not load base image, will generate base image by tone mapping.")
            baseImageBool = false
            return hdrImage.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":headroomRatio,"inputTargetHeadroom":1.0])
        }
        var baseImageTemp: CIImage
        baseImageTemp = CIImage(contentsOf: baseImageURL!)!
        if subsamplingBool {
            baseImageTemp = makeEvenSized(baseImageTemp)
        }
        if baseImageTemp.extent != hdrImage.extent{
            print("Warning: Size of base image is different, will generate base image by tone mapping.")
            return hdrImage.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":headroomRatio,"inputTargetHeadroom":1.0])
        }
        return baseImageTemp
    }
    return hdrImage.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":headroomRatio,"inputTargetHeadroom":1.0])
}



if sdrExport {
    let tonemappedSDRImage = generateSDRImage()!
    let sdrExportOptions = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imageQuality])
    if tenBit {
        try! ctx.writeHEIF10Representation(of: tonemappedSDRImage,
                                               to: heicExportURL,
                                               colorSpace: CGColorSpace(name: sdrColorSpace)!,
                                               options:sdrExportOptions as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: tonemappedSDRImage,
                                             to: heicExportURL,
                                             format: CIFormat.RGBA8,
                                             colorSpace: CGColorSpace(name: sdrColorSpace)!,
                                             options:sdrExportOptions as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

// export subsampled RGB gain map by imageIO
// there are some compatibility issues
// not recommended to use
if !appleGainMap && subsamplingBool {

    let tonemappedSDRImage = generateSDRImage()!
    let rgbGainMap = lanczosResizeImage(getRGBGainMap(hdrInput: hdrImage, sdrInput: tonemappedSDRImage, hdrMax: picHeadroom))
    
    let tmpHeight = Int(rgbGainMap.extent.height)
    let tmpWidth = Int(rgbGainMap.extent.width)

    var gainMapDataMono = Data(count: tmpHeight * tmpWidth)
    var gainMapDataRGB = Data(count: tmpHeight * tmpWidth * 4)
    
    var dict: [CFString: Any] = [:]
    var xmlString: String
    
    if monochromeExport{
        gainMapDataMono.withUnsafeMutableBytes {
            if let baseAddress = $0.baseAddress {
                ctx.render(
                    rgbGainMap,
                    toBitmap: baseAddress,
                    rowBytes: tmpWidth,
                    bounds: rgbGainMap.extent,
                    format: CIFormat.L8,
                    colorSpace: CGColorSpace(name: CGColorSpace.linearGray)!
                )
            }
        }
        xmlString = defaultHDRMetadata(GainMapMax: log2(picHeadroom), GainMapMin: 0.0, RGBType: 2)
    } else {
        gainMapDataRGB.withUnsafeMutableBytes {
            if let baseAddress = $0.baseAddress {
                ctx.render(
                    rgbGainMap,
                    toBitmap: baseAddress,
                    rowBytes: tmpWidth * 4,
                    bounds: rgbGainMap.extent,
                    format: CIFormat.ARGB8,
                    colorSpace: CGColorSpace(name: CGColorSpace.linearITUR_2020)!
                )
            }
        }
        xmlString = defaultHDRMetadata(GainMapMax: log2(picHeadroom), GainMapMin: 0.0, RGBType: 1)
    }
    
    let xmlData = xmlString.data(using: .utf8)
    let metaData = CGImageMetadataCreateFromXMPData(xmlData! as CFData)
    let metaDataInfo: Any? = CGColorSpace(name: sdrColorSpace)!
    var metaDataDescription: Any?
    
    if monochromeExport{
        metaDataDescription = [
            "PixelFormat": kCVPixelFormatType_OneComponent8,
            "Width": String(tmpWidth),
            "Height": String(tmpHeight),
            "BytesPerRow": String(tmpWidth)
          ]
        dict[kCGImageAuxiliaryDataInfoData] = gainMapDataMono
    } else {
        metaDataDescription = [
            "PixelFormat": kCVPixelFormatType_32ARGB,
            "Width": String(tmpWidth),
            "Height": String(tmpHeight),
            "BytesPerRow": String(tmpWidth*4)
          ]
        dict[kCGImageAuxiliaryDataInfoData] = gainMapDataRGB
    }
    dict[kCGImageAuxiliaryDataInfoMetadata] = metaData
    dict[kCGImageAuxiliaryDataInfoDataDescription] = metaDataDescription
    dict[kCGImageAuxiliaryDataInfoColorSpace] = metaDataInfo

    let auxDict = dict as CFDictionary
    let dest = CGImageDestinationCreateWithURL(
        heicExportURL as CFURL,
        UTType.heic.identifier as CFString,
        1,
        nil
        )
    
    let context = CIContext(options: [CIContextOption.outputColorSpace:CGColorSpace(name: sdrColorSpace)!])
    
    var baseCG : CGImage
    if tenBit {
        baseCG = context.createCGImage(tonemappedSDRImage, from: tonemappedSDRImage.extent, format: CIFormat.RGB10, colorSpace: CGColorSpace(name: sdrColorSpace)!)!
    } else {
        baseCG = context.createCGImage(tonemappedSDRImage, from: tonemappedSDRImage.extent)!
    }
    
    let properties = hdrImage.properties
    
    var exportOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: imageQuality]
    for (key, value) in properties {
        exportOptions[key as CFString] = value
    }
    
    CGImageDestinationAddImage(dest!, baseCG, exportOptions as CFDictionary)
    CGImageDestinationAddAuxiliaryDataInfo(
            dest!,
            kCGImageAuxiliaryDataTypeISOGainMap,
            auxDict
        )
    
    CGImageDestinationFinalize(dest!)
    
    exit(0)
}

// export gain map in YUV format (default format)
if !appleGainMap {
    var adaptiveExportOptions: NSDictionary
    
    let tonemappedSDRImage = generateSDRImage()!
    if monochromeExport {
        adaptiveExportOptions = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imageQuality, CIImageRepresentationOption.hdrImage:hdrImage,CIImageRepresentationOption.hdrGainMapAsRGB:false])
    } else {
        adaptiveExportOptions = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imageQuality, CIImageRepresentationOption.hdrImage:hdrImage,CIImageRepresentationOption.hdrGainMapAsRGB:true])
    }
    if tenBit {
        try! ctx.writeHEIF10Representation(of: tonemappedSDRImage,
                                           to: heicExportURL,
                                           colorSpace: CGColorSpace(name: sdrColorSpace)!,
                                           options: adaptiveExportOptions as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: tonemappedSDRImage,
                                         to: heicExportURL,
                                         format: CIFormat.RGBA8,
                                         colorSpace: CGColorSpace(name: sdrColorSpace)!,
                                         options: adaptiveExportOptions as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

// -g: Apple HDR gain map by CIFilter
if appleGainMap {
    var gainMap : CIImage
    let tonemappedSDRImage = generateSDRImage()!
    gainMap = getGainMap(hdrInput: hdrImage, sdrInput: tonemappedSDRImage, hdrMax: maxHeadroom)

    if subsamplingBool{
        gainMap = lanczosResizeImage(gainMap)
    }
    
    let stops = log2(maxHeadroom)
    var imageProperties = hdrImage.properties
    var makerApple = imageProperties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] ?? [:]

    switch stops {
    case let x where x >= 2.3:
        makerApple["33"] = 1.0
        makerApple["48"] = (3.0 - stops)/70.0
    case 1.8..<2.3:
        makerApple["33"] = 1.0
        makerApple["48"] = (2.30303 - stops)/0.303
    case 1.6..<1.8:
        makerApple["33"] = 0.0
        makerApple["48"] = (1.80 - stops)/20.0
    default:
        makerApple["33"] = 0.0
        makerApple["48"] = (1.60101 - stops)/0.101
    }
    
    imageProperties[kCGImagePropertyMakerAppleDictionary as String] = makerApple
    let modifiedImage = tonemappedSDRImage.settingProperties(imageProperties)
    
    let altExportOptions = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imageQuality, CIImageRepresentationOption.hdrGainMapImage:gainMap])
    if tenBit {
        try! ctx.writeHEIF10Representation(of: modifiedImage,
                                           to: heicExportURL,
                                           colorSpace: CGColorSpace(name: sdrColorSpace)!,
                                           options: altExportOptions as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: modifiedImage,
                                         to: heicExportURL,
                                         format: CIFormat.RGBA8,
                                         colorSpace: CGColorSpace(name: sdrColorSpace)!,
                                         options: altExportOptions as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}
