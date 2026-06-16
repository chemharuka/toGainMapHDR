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

let ctx = CIContext()
let help_info = "Usage: toGainMapHDR <source file> <destination folder> <options>\n       default: output HDR-heic with ISO gain map in RGB\n       options:\n         -q <value>: image quality (default: 0.85)\n         -r <value>: SDR tone mapping ratio (≥ 1.0, default: 3.0)\n             ratio = 1.0: keep full highlight details\n             ratio >> 100: lose all highlight details\n         -R <value>: max headroom for tone mapping (default: 6)\n         -b <file_path>: specify base image\n         -t <text>: add extra text after the output file name\n         -c <color space>: specify output color space (srgb, p3, rec2020)\n         -d <color depth>: specify output color depth (default: 6)\n         -g: output Apple gain map HDR\n         -m: export ISO Gain Map HDR in monochrome\n         -H: subsampling gain map to half size\n         -s: export tone mapped SDR image\n         -p: export 10bit PQ HDR heic image\n         -h: export HLG HDR heic image (default in 10bit)\n         -j : export image in JPEG format\n         -help: print help information"
let arguments = CommandLine.arguments
guard arguments.count > 2 else {
    print(help_info)
    exit(1)
}

let url_hdr = URL(fileURLWithPath: arguments[1])
var filename: String?
var filename_jpg: String?
filename = url_hdr.deletingPathExtension().appendingPathExtension("heic").lastPathComponent
filename_jpg = url_hdr.deletingPathExtension().appendingPathExtension("jpg").lastPathComponent

let imageoptions = arguments.dropFirst(3)
var base_image_url : URL?

var imagequality: Double? = 0.85
var tonemappingratio: Float? = 3.0
var max_headroom: Float? = 6.0
var tonemappingratio_bool : Bool = false
var base_image_bool : Bool = false
var sdr_export: Bool = false
var pq_export: Bool = false
var hlg_export: Bool = false
var eight_bit: Bool = false
var ten_bit: Bool = false
var subsampling_bool : Bool = false
var apple_gain_map: Bool = false
var hdr_image: CIImage
var monochrome_export: Bool = false
var is_cropped_bool : Bool = false

let read_hdr_image = CIImage(contentsOf: url_hdr, options: [.expandToHDR: true])
if read_hdr_image == nil {
    print("Error: No input image found.")
    exit(1)
}

hdr_image = read_hdr_image!

var sdr_color_space = CGColorSpace.displayP3
var hdr_color_space = CGColorSpace.displayP3_PQ
var hlg_color_space = CGColorSpace.displayP3_HLG

let image_color_space = String(describing: hdr_image.colorSpace)
if image_color_space.contains("709") {
    sdr_color_space = CGColorSpace.itur_709
    hdr_color_space = CGColorSpace.itur_709_PQ
    hlg_color_space = CGColorSpace.itur_709_HLG
}
if image_color_space.contains("sRGB") {
    sdr_color_space = CGColorSpace.itur_709
    hdr_color_space = CGColorSpace.itur_709_PQ
    hlg_color_space = CGColorSpace.itur_709_HLG
}
if image_color_space.contains("2100") {
    sdr_color_space = CGColorSpace.itur_2020_sRGBGamma
    hdr_color_space = CGColorSpace.itur_2100_PQ
    hlg_color_space = CGColorSpace.itur_2100_HLG
}
if image_color_space.contains("2020") {
    sdr_color_space = CGColorSpace.itur_2020_sRGBGamma
    hdr_color_space = CGColorSpace.itur_2100_PQ
    hlg_color_space = CGColorSpace.itur_2100_HLG
}

var index:Int = 0
while index < imageoptions.count {
    let option = arguments[index+3]
    switch option {
    case "-q":
        guard index + 1 < imageoptions.count else {
            print("Error: The -q option requires a valid numeric value.")
            exit(1)
        }
        if let value = Double(arguments[index + 4]) {
            if value > 1 {
                imagequality = value/100
            } else {
                imagequality = value
            }
            index += 1 // Skip the next value
        } else {
            print("Error: The -q option requires a valid numeric value.")
            exit(1)
        }
    case "-r":
        guard index + 1 < imageoptions.count else {
            print("Error: The -r option requires a valid numeric value.")
            exit(1)
        }
        if let value = Float(arguments[index + 4]) {
            tonemappingratio_bool = true
            tonemappingratio = value
            index += 1 // Skip the next value
        } else {
            print("Error: The -r option requires a valid numeric value.")
            exit(1)
        }
    case "-R":
        guard index + 1 < imageoptions.count else {
            print("Error: The -R option requires a valid numeric value.")
            exit(1)
        }
        if let value = Float(arguments[index + 4]) {
            max_headroom  = value
            index += 1 // Skip the next value
        } else {
            print("Error: The -R option requires a valid numeric value.")
            exit(1)
        }
    case "-b":
        guard index + 1 < imageoptions.count else {
            print("Error: The -b option requires an argument.")
            exit(1)
        }
        base_image_url = URL(fileURLWithPath: arguments[index + 4])
        base_image_bool = true
        index += 1
    case "-s":
        sdr_export = true
    case "-p":
        pq_export = true
    case "-h":
        hlg_export = true
    case "-m":
        monochrome_export = true
    case "-H":
        subsampling_bool = true
    case "-g":
        apple_gain_map = true
    case "-d":
        guard index + 1 < imageoptions.count else {
            print("Error: The -d option requires an argument.")
            exit(1)
        }
        let bit_depth_argument = String(arguments[index + 4])
        if bit_depth_argument == "8"{
            index += 1
            eight_bit = true
        } else { if bit_depth_argument == "10"{
            ten_bit = true
            index += 1
        } else {
            print("Error: Color depth must be either 8 or 10.")
            exit (1)
        }}
    case "-t":
        guard index + 1 < imageoptions.count else {
            print("Error: The -n option requires an argument.")
            exit(1)
        }
        let additional_filename = String(arguments[index + 4])
        filename = URL(string: url_hdr.deletingPathExtension().absoluteString+additional_filename)!           .appendingPathExtension("heic").lastPathComponent
        filename_jpg = URL(string: url_hdr.deletingPathExtension().absoluteString+additional_filename)!           .appendingPathExtension("jpg").lastPathComponent
        index += 1
    case "-c":
        guard index + 1 < imageoptions.count else {
            print("Error: The -c option requires color space argument.")
            exit(1)
        }
        let color_space_argument = String(arguments[index + 4])
        let color_space_option = color_space_argument.lowercased()
        switch color_space_option {
            case "srgb","709","rec709","rec.709","bt709","bt.709","itu709":
                sdr_color_space = CGColorSpace.itur_709
                hdr_color_space = CGColorSpace.itur_709_PQ
                hlg_color_space = CGColorSpace.itur_709_HLG
            case "p3","dcip3","dci-p3","dci.p3","displayp3":
                sdr_color_space = CGColorSpace.displayP3
                hdr_color_space = CGColorSpace.displayP3_PQ
                hlg_color_space = CGColorSpace.displayP3_HLG
            case "rec2020","2020","rec.2020","bt2020","itu2020","2100","rec2100","rec.2100":
                sdr_color_space = CGColorSpace.itur_2020_sRGBGamma
                hdr_color_space = CGColorSpace.itur_2100_PQ
                hlg_color_space = CGColorSpace.itur_2100_HLG
            default:
                print("Error: The -c option requires color space argument. (srgb, p3, rec2020)")
                exit(1)
        }
        index += 1
    case "-help":
        print(help_info)
        exit(1)
    default:
        print("Warning: Unknown option: \(option)")
    }
    index += 1
}


let path_export = URL(fileURLWithPath: arguments[2])
let url_export_heic = path_export.appendingPathComponent(filename!)
let url_export_jpg = path_export.appendingPathComponent(filename_jpg!)

if [pq_export, hlg_export, sdr_export, apple_gain_map, monochrome_export].filter({$0}).count >= 2 {
    print("Error: Only one export format can be used.")
    exit(1)
}
if tonemappingratio! < 1.0 {
    print("Error: The -r option requires a valid numeric value.")
    exit(1)
}
if imagequality! < 0 || imagequality! > 1 {
    print("Error: The -q option requires a valid numeric value.")
    exit(1)
}
if max_headroom! < 1.0 {
    print("Error: The -R option requires a valid numeric value.")
    exit(1)
}
if base_image_bool && monochrome_export {
    print("Warning: Base image specified, will use RGB gain map.")
    monochrome_export = false
}
if base_image_bool && apple_gain_map {
    print("Warning: Base image specified, will use RGB gain map.")
    apple_gain_map = false
}

if hlg_export && eight_bit {print("Warning: Suggested to use 10-bit with HLG.")}
if pq_export && eight_bit {print("Warning: Color depth will be 10 when exporting PQ HDR.")}
if tonemappingratio_bool && base_image_bool {print("Warning: Base image specified, tone mapping ratio will not be applied.")}
if tonemappingratio_bool && hlg_export {print("Warning: Tone mapping ratio will not be applied when exporting HLG HDR image.")}
if tonemappingratio_bool && pq_export {print("Warning: Tone mapping ratio will not be applied when exporting PQ HDR image.")}



// export hlg and pq hdr file
while hlg_export{
    let hlg_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85])
    if eight_bit {
        try! ctx.writeHEIFRepresentation(of: hdr_image,
                                         to: url_export_heic,
                                         format: CIFormat.RGBA8,
                                         colorSpace: CGColorSpace(name: hlg_color_space)!,
                                         options:hlg_export_options as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIF10Representation(of: hdr_image,
                                         to: url_export_heic,
                                         colorSpace: CGColorSpace(name: hlg_color_space)!,
                                         options:hlg_export_options as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

while pq_export {
    let pq_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85])
    try! ctx.writeHEIF10Representation(of: hdr_image,
                                       to: url_export_heic,
                                       colorSpace: CGColorSpace(name: hdr_color_space)!,
                                       options:pq_export_options as! [CIImageRepresentationOption : Any])
    exit(0)
}


// Custom filter

private func getGainMap(hdr_input: CIImage,sdr_input: CIImage,hdr_max: Float) -> CIImage {
    let filter = GainMapFilter()
    filter.HDRImage = hdr_input
    filter.SDRImage = sdr_input
    filter.hdrmax = hdr_max
    let outputImage = filter.outputImage
    return outputImage!
}
private func getRGBGainMap(hdr_input: CIImage,sdr_input: CIImage,hdr_max: Float) -> CIImage {
    let filter = RGBGainMapFilter()
    filter.HDRImage = hdr_input
    filter.SDRImage = sdr_input
    filter.hdrmax = hdr_max
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
        exit(1)
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
    if !is_cropped_bool {
        print("Warning: Subsampling gain map requires even width/hight, cropped 1 pixel.")
        is_cropped_bool = true
    }
    return image.cropped(to: newRect)
}


var pic_headroom : Float = 1.0
var pic_headroom2 : Float
var headroom_ratio : Float = max_headroom!

if subsampling_bool {
    hdr_image = makeEvenSized(hdr_image)
}

if base_image_bool && !subsampling_bool {}
else {
    let transform = CGAffineTransform(scaleX: 1.0 / CGFloat(tonemappingratio!), y: 1.0 / CGFloat(tonemappingratio!))
    pic_headroom = maxLuminance(hdr_image)!
    pic_headroom2 = maxLuminance(hdr_image.transformed(by: transform))!

    if pic_headroom < 1.05 {
        print("Warning: Picture headroom < 1.05, this is an SDR image, outputing SDR image.")
        sdr_export = true
        base_image_bool = false
        headroom_ratio = 1.0
    }

    if pic_headroom2 < 1.0 {
        pic_headroom2 = 1.0
    }
    
    if pic_headroom2 > headroom_ratio {
        print("Warning: Picture headroom > max headroom (set with -R parameter), highlight clipped.")
    } else {
        headroom_ratio = pic_headroom2
    }
    
    if max_headroom! > pic_headroom {
        max_headroom = pic_headroom
    }
}

func generate_sdr_image() -> CIImage?{
    if base_image_bool {
        if CIImage(contentsOf: base_image_url!) == nil {
            print("Warning: Could not load base image, will generate base image by tone mapping.")
            base_image_bool = false
            return hdr_image.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":headroom_ratio,"inputTargetHeadroom":1.0])
        }
        var base_image_temp: CIImage
        base_image_temp = CIImage(contentsOf: base_image_url!)!
        if subsampling_bool {
            base_image_temp = makeEvenSized(base_image_temp)
        }
        if base_image_temp.extent != hdr_image.extent{
            print("Warning: Size of base image is different, will generate base image by tone mapping.")
            return hdr_image.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":headroom_ratio,"inputTargetHeadroom":1.0])
        }
        return base_image_temp
    }
    return hdr_image.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":headroom_ratio,"inputTargetHeadroom":1.0])
}



while sdr_export{
    let tonemapped_sdrimage = generate_sdr_image()!
    let sdr_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85])
    if ten_bit{
        try! ctx.writeHEIF10Representation(of: tonemapped_sdrimage,
                                               to: url_export_heic,
                                               colorSpace: CGColorSpace(name: sdr_color_space)!,
                                               options:sdr_export_options as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: tonemapped_sdrimage,
                                             to: url_export_heic,
                                             format: CIFormat.RGBA8,
                                             colorSpace: CGColorSpace(name: sdr_color_space)!,
                                             options:sdr_export_options as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

// export subsampled RGB gain map by imageIO
// there are some compatibility issues
// not recommended to use
if !apple_gain_map && subsampling_bool {

    let tonemapped_sdrimage = generate_sdr_image()!
    let rgb_gain_map = lanczosResizeImage(getRGBGainMap(hdr_input: hdr_image,sdr_input: tonemapped_sdrimage, hdr_max: pic_headroom))
    
    let tmp_height = Int(rgb_gain_map.extent.height)
    let tmp_width = Int(rgb_gain_map.extent.width)

    var gain_map_data_mono = Data(count: tmp_height * tmp_width)
    var gain_map_data_rgb = Data(count: tmp_height * tmp_width * 4)
    
    var dict: [CFString: Any] = [:]
    var xmlString: String
    
    if monochrome_export{
        gain_map_data_mono.withUnsafeMutableBytes {
            if let baseAddress = $0.baseAddress {
                ctx.render(
                    rgb_gain_map,
                    toBitmap: baseAddress,
                    rowBytes: tmp_width,
                    bounds: rgb_gain_map.extent,
                    format: CIFormat.L8,
                    colorSpace: CGColorSpace(name: CGColorSpace.linearGray)!
                )
            }
        }
        xmlString = defaultHDRMetadata(GainMapMax: log2(pic_headroom),GainMapMin: 0.0, RGBType: 2)
    } else {
        gain_map_data_rgb.withUnsafeMutableBytes {
            if let baseAddress = $0.baseAddress {
                ctx.render(
                    rgb_gain_map,
                    toBitmap: baseAddress,
                    rowBytes: tmp_width * 4,
                    bounds: rgb_gain_map.extent,
                    format: CIFormat.ARGB8,
                    colorSpace: CGColorSpace(name: CGColorSpace.linearITUR_2020)!
                )
            }
        }
        xmlString = defaultHDRMetadata(GainMapMax: log2(pic_headroom),GainMapMin: 0.0, RGBType: 1)
    }
    
    let xmlData = xmlString.data(using: .utf8)
    let metaData = CGImageMetadataCreateFromXMPData(xmlData! as CFData)
    let metaDataInfo: Any? = CGColorSpace(name: sdr_color_space)!
    var metaDataDescription: Any?
    
    if monochrome_export{
        metaDataDescription = [
            "PixelFormat": 1278226488,
            "Width": String(tmp_width),
            "Height": String(tmp_height),
            "BytesPerRow": String(tmp_width)
          ]
        dict[kCGImageAuxiliaryDataInfoData] = gain_map_data_mono
    } else {
        metaDataDescription = [
            "PixelFormat": 32,
            "Width": String(tmp_width),
            "Height": String(tmp_height),
            "BytesPerRow": String(tmp_width*4)
          ]
        dict[kCGImageAuxiliaryDataInfoData] = gain_map_data_rgb
    }
    dict[kCGImageAuxiliaryDataInfoMetadata] = metaData
    dict[kCGImageAuxiliaryDataInfoDataDescription] = metaDataDescription
    dict[kCGImageAuxiliaryDataInfoColorSpace] = metaDataInfo

    let auxDict = dict as CFDictionary
    let dest = CGImageDestinationCreateWithURL(
        url_export_heic as CFURL,
        UTType.heic.identifier as CFString,
        1,
        nil
        )
    
    let context = CIContext(options: [CIContextOption.outputColorSpace:CGColorSpace(name: sdr_color_space)!])
    
    var baseCG : CGImage
    if ten_bit {
        baseCG = context.createCGImage(tonemapped_sdrimage, from: tonemapped_sdrimage.extent, format: CIFormat.RGB10, colorSpace: CGColorSpace(name: sdr_color_space)!)!
    } else {
        baseCG = context.createCGImage(tonemapped_sdrimage, from: tonemapped_sdrimage.extent)!
    }
    
    let properties = hdr_image.properties
    
    var export_options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: imagequality ?? 0.85]
    for (key, value) in properties {
        export_options[key as CFString] = value
    }
    
    CGImageDestinationAddImage(dest!, baseCG, export_options as CFDictionary)
    CGImageDestinationAddAuxiliaryDataInfo(
            dest!,
            kCGImageAuxiliaryDataTypeISOGainMap,
            auxDict
        )
    
    CGImageDestinationFinalize(dest!)
    
    exit(0)
}

// export gain map in YUV format (default format)
if !apple_gain_map {
    var adaptive_export_options: NSDictionary
    
    let tonemapped_sdrimage = generate_sdr_image()!
    if monochrome_export {
        adaptive_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85, CIImageRepresentationOption.hdrImage:hdr_image,CIImageRepresentationOption.hdrGainMapAsRGB:false])
    } else {
        adaptive_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85, CIImageRepresentationOption.hdrImage:hdr_image,CIImageRepresentationOption.hdrGainMapAsRGB:true])
    }
    if ten_bit {
        try! ctx.writeHEIF10Representation(of: tonemapped_sdrimage,
                                           to: url_export_heic,
                                           colorSpace: CGColorSpace(name: sdr_color_space)!,
                                           options: adaptive_export_options as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: tonemapped_sdrimage,
                                         to: url_export_heic,
                                         format: CIFormat.RGBA8,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options: adaptive_export_options as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

// -g: Apple HDR gain map by CIFilter
if apple_gain_map {
    var gain_map : CIImage
    let tonemapped_sdrimage = generate_sdr_image()!
    gain_map = getGainMap(hdr_input: hdr_image, sdr_input: tonemapped_sdrimage, hdr_max: max_headroom!)

    if subsampling_bool{
        gain_map = lanczosResizeImage(gain_map)
    }
    
    let stops = log2(max_headroom!)
    var imageProperties = hdr_image.properties
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
    let modifiedImage = tonemapped_sdrimage.settingProperties(imageProperties)
    
    let alt_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85, CIImageRepresentationOption.hdrGainMapImage:gain_map])
    if ten_bit {
        try! ctx.writeHEIF10Representation(of: modifiedImage,
                                           to: url_export_heic,
                                           colorSpace: CGColorSpace(name: sdr_color_space)!,
                                           options: alt_export_options as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: modifiedImage,
                                         to: url_export_heic,
                                         format: CIFormat.RGBA8,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options: alt_export_options as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}


//let filename2 = url_hdr.deletingPathExtension().appendingPathExtension("png").lastPathComponent
//let url_export_heic2 = path_export.appendingPathComponent(filename2)
//try! ctx.writePNGRepresentation(of: sdr_image!, to: url_export_heic2, format: CIFormat.RGBA8, colorSpace:CGColorSpace(name: CGColorSpace.displayP3)!)
exit(20)
// debug
//let filename2 = url_hdr.deletingPathExtension().appendingPathExtension("png").lastPathComponent
//let url_export_heic2 = path_export.appendingPathComponent(filename2)
//try! ctx.writePNGRepresentation(of: gainmap!, to: url_export_heic2, format: CIFormat.RGBA8, colorSpace:CGColorSpace(name: CGColorSpace.displayP3)!)



