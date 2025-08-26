//
//  toGainMapHDR
//  This code will convert HDR photo to gain map HDR photo.
//
//  Created by Luyao Peng on 2024/9/27. Distributed under MIT license.
//

import CoreImage
import Foundation
import CoreImage.CIFilterBuiltins
import CoreVideo

let ctx = CIContext()
let help_info = "Usage: toGainMapHDR <source file> <destination folder> <options>\n       options:\n         -q <value>: image quality (default: 0.85)\n         -r <value>: tone mapping ratio (between 0 and 1, default: 0.4).\n             ratio = 0: keep full highlight details\n             ratio = 1: hard clip all parts exceeding SDR range\n             ratio = -1: only work with -g, generate Apple Gain Map by CIFilter\n         -b <base_photo>: specify base image and output ISO HDR with RGB gain map\n         -t <text>: Add extra text after the output file name\n         -c <color space>: specify output color space (srgb, p3, rec2020)\n         -d <color depth>: specify output color depth (default: 8)\n         -g: output Apple HDR file (monochannel gain map)\n         -s: export tone mapped SDR image without HDR gain map\n         -p: export 10bit PQ HDR heic image\n         -h: export HLG HDR heic image (default in 10bit)\n         -j : export image in JPEG format\n         -help: print help information"
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
var tonemappingratio: Float? = 0.4
var tonemappingratio_bool : Bool = false
var base_image_bool : Bool = false
var sdr_export: Bool = false
var pq_export: Bool = false
var hlg_export: Bool = false
var jpg_export: Bool = false
var bit_depth = CIFormat.RGBA8
var eight_bit: Bool = false
var gain_map_mono: Bool = false

let hdr_image = CIImage(contentsOf: url_hdr, options: [.expandToHDR: true])
if hdr_image == nil {
    print("Error: No input image found.")
    exit(1)
}


var sdr_color_space = CGColorSpace.displayP3
var hdr_color_space = CGColorSpace.displayP3_PQ
var hlg_color_space = CGColorSpace.displayP3_HLG

let image_color_space = String(describing: hdr_image?.colorSpace)
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
            if value > 1 {
                tonemappingratio = value/100
            } else {
                tonemappingratio = value
            }
            index += 1 // Skip the next value
        } else {
            print("Error: The -r option requires a valid numeric value.")
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
    case "-j":
        jpg_export = true
    case "-g":
        gain_map_mono = true
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
            bit_depth = CIFormat.RGB10
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
        print("Warrning: Unknown option: \(option)")
    }
    index += 1
}


let path_export = URL(fileURLWithPath: arguments[2])
let url_export_heic = path_export.appendingPathComponent(filename!)
let url_export_jpg = path_export.appendingPathComponent(filename_jpg!)

if [pq_export, hlg_export, sdr_export, gain_map_mono, base_image_bool].filter({$0}).count >= 2 {
    print("Error: Only one export format can be used.")
    exit(1)
}
if (jpg_export && hlg_export) || (jpg_export && pq_export) {
    print("Error: Not support exporting JPEG with HLG or PQ transfer function.")
    exit(1)
}
if tonemappingratio! < 0 && tonemappingratio != -1 {
    print("Error: The -r option requires a valid numeric value.")
    exit(1)
}

if hlg_export && eight_bit {print("Warrning: Suggested to use 10-bit with HLG.")}
if jpg_export && bit_depth == CIFormat.RGB10 {print("Warning: Color depth will be 8 when exporting JPEG.")}
if pq_export && eight_bit {print("Warning: Color depth will be 10 when exporting PQ HDR.")}
if tonemappingratio_bool && base_image_bool {print("Warrning: Base image specified, tone mapping ratio will not be applied.")}
if tonemappingratio_bool && hlg_export {print("Warrning: Tone mapping ratio will not be applied when exporting HLG HDR image.")}
if tonemappingratio_bool && pq_export {print("Warrning: Tone mapping ratio will not be applied when exporting PQ HDR image.")}


// export hlg and pq hdr file
while hlg_export{
    let hlg_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85])
    if !eight_bit {bit_depth = CIFormat.RGB10}
    try! ctx.writeHEIFRepresentation(of: hdr_image!,
                                     to: url_export_heic,
                                     format: bit_depth,
                                     colorSpace: CGColorSpace(name: hlg_color_space)!,
                                     options:hlg_export_options as! [CIImageRepresentationOption : Any])
    exit(0)
}

while pq_export {
    let pq_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85])
    try! ctx.writeHEIF10Representation(of: hdr_image!,
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


func maxLuminanceHDR(from ciImage: CIImage, context: CIContext) -> Float? {
    let extent = ciImage.extent
    
    let filter = CIFilter.areaMaximum()
    filter.inputImage = ciImage
    filter.extent = extent
    
    guard let outputImage = filter.outputImage else { return nil }
    
    // Use floating point format to preserve HDR values
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
    
    // Calculate luminance using linear RGB (Rec.709 coefficients)
    let luminance: Float = 0.2126 * r + 0.7152 * g + 0.0722 * b
    
    return luminance
}

var pic_headroom : Float
pic_headroom = maxLuminanceHDR(from: hdr_image!, context: ctx)!
let headroom_ratio = 1.0 + pic_headroom - pow(pic_headroom,tonemappingratio!)
if pic_headroom < 2 {pic_headroom = 2}

var tonemapped_sdrimage : CIImage?
if tonemappingratio == -1 {
    tonemapped_sdrimage = hdr_image?.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":pic_headroom as Any,"inputTargetHeadroom":1.0])
} else {
    if base_image_bool{
        if CIImage(contentsOf: base_image_url!) == nil {
            print("Warning: Could not load base image, will generate base image by tone mapping.")
            base_image_bool = false
            tonemapped_sdrimage = hdr_image?.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":headroom_ratio,"inputTargetHeadroom":1.0])
        }
        else {
            tonemapped_sdrimage = CIImage(contentsOf: base_image_url!)
        }
    } else {
        tonemapped_sdrimage = hdr_image?.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":headroom_ratio,"inputTargetHeadroom":1.0])
    }
}


while sdr_export{
    let sdr_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85])
    if jpg_export{
        try! ctx.writeJPEGRepresentation(of: tonemapped_sdrimage!,
                                         to: url_export_jpg,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options:sdr_export_options as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: tonemapped_sdrimage!,
                                         to: url_export_heic,
                                         format: bit_depth,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options:sdr_export_options as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

// -b: export adaptive RGB gain map image
if base_image_bool {
    let rgb_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85, CIImageRepresentationOption.hdrImage:hdr_image!,CIImageRepresentationOption.hdrGainMapAsRGB:true])
    
    if jpg_export {
        try! ctx.writeJPEGRepresentation(of: tonemapped_sdrimage!,
                                         to: url_export_jpg,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options: rgb_export_options as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: tonemapped_sdrimage!,
                                         to: url_export_heic,
                                         format: bit_depth,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options: rgb_export_options as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

// export adaptive gain map image (default format)
if !gain_map_mono {
    let adaptive_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85, CIImageRepresentationOption.hdrImage:hdr_image!,CIImageRepresentationOption.hdrGainMapAsRGB:false])
    if jpg_export {
        try! ctx.writeJPEGRepresentation(of: tonemapped_sdrimage!,
                                         to: url_export_jpg,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options: adaptive_export_options as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: tonemapped_sdrimage!,
                                         to: url_export_heic,
                                         format: bit_depth,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options: adaptive_export_options as! [CIImageRepresentationOption : Any])
    }
    exit(0)
}

// -g -r -1: generate Apple HDR gain map by CIFilter
if tonemappingratio == -1 {
    let gain_map = getGainMap(hdr_input: hdr_image!, sdr_input: tonemapped_sdrimage!, hdr_max: pic_headroom)
    let gain_map_sdr = gain_map.applyingFilter("CIToneMapHeadroom", parameters: ["inputSourceHeadroom":1.0,"inputTargetHeadroom":1.0])
    let stops = log2(pic_headroom)
    var imageProperties = hdr_image!.properties
    var makerApple = imageProperties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] ?? [:]

    switch stops {
    case let x where x >= 2.303:
        makerApple["33"] = 1.0
        makerApple["48"] = (3.0 - stops)/70.0
    case 1.8..<3:
        makerApple["33"] = 1.0
        makerApple["48"] = (2.303 - stops)/0.303
    case 1.6..<1.8:
        makerApple["33"] = 0.0
        makerApple["48"] = (1.80 - stops)/20.0
    default:
        makerApple["33"] = 0.0
        makerApple["48"] = (1.601 - stops)/0.101
    }
    
    imageProperties[kCGImagePropertyMakerAppleDictionary as String] = makerApple
    let modifiedImage = tonemapped_sdrimage!.settingProperties(imageProperties)

    let alt_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85, CIImageRepresentationOption.hdrGainMapImage:gain_map_sdr])
    if jpg_export {
        try! ctx.writeJPEGRepresentation(of: modifiedImage,
                                         to: url_export_jpg,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options:alt_export_options as! [CIImageRepresentationOption : Any])
    } else {
        try! ctx.writeHEIFRepresentation(of: modifiedImage,
                                         to: url_export_heic,
                                         format: bit_depth,
                                         colorSpace: CGColorSpace(name: sdr_color_space)!,
                                         options: alt_export_options as! [CIImageRepresentationOption : Any])
    }
    
    exit(0)
}

// -g: export monochrome Apple HDR gain map photo.



let tmp_export_options = NSDictionary(dictionary:[ CIImageRepresentationOption.hdrImage:hdr_image!,CIImageRepresentationOption.hdrGainMapAsRGB:false])
let tmp_heic_data = ctx.heifRepresentation(of: tonemapped_sdrimage!,
                                           format: CIFormat.RGBA8,
                                           colorSpace: CGColorSpace(name: sdr_color_space)!,
                                           options: tmp_export_options as! [CIImageRepresentationOption : Any])

let tmp_gainmap_data = CIImage(data: tmp_heic_data!, options: [.init(rawValue: "kCIImageAuxiliaryHDRGainMap"): true])

let apple_export_options = NSDictionary(dictionary:[kCGImageDestinationLossyCompressionQuality:imagequality ?? 0.85, CIImageRepresentationOption.hdrGainMapImage:tmp_gainmap_data as Any])

var imageproperties = hdr_image!.properties

var makerapple = imageproperties[kCGImagePropertyMakerAppleDictionary as String] as? [String: Any] ?? [:]

makerapple["33"] = 1.01
makerapple["48"] = 0.009986
imageproperties[kCGImagePropertyMakerAppleDictionary as String] = makerapple

let modifiedimage = tonemapped_sdrimage!.settingProperties(imageproperties)



if jpg_export {
    try! ctx.writeJPEGRepresentation(of: modifiedimage,
                                     to: url_export_jpg,
                                     colorSpace: CGColorSpace(name: sdr_color_space)!,
                                     options:apple_export_options as! [CIImageRepresentationOption : Any])
} else {
    try! ctx.writeHEIFRepresentation(of: modifiedimage,
                                     to: url_export_heic,
                                     format: bit_depth,
                                     colorSpace: CGColorSpace(name: sdr_color_space)!,
                                     options: apple_export_options as! [CIImageRepresentationOption : Any])
}

//let filename2 = url_hdr.deletingPathExtension().appendingPathExtension("png").lastPathComponent
//let url_export_heic2 = path_export.appendingPathComponent(filename2)
//try! ctx.writePNGRepresentation(of: sdr_image!, to: url_export_heic2, format: CIFormat.RGBA8, colorSpace:CGColorSpace(name: CGColorSpace.displayP3)!)
exit(0)
// debug
//let filename2 = url_hdr.deletingPathExtension().appendingPathExtension("png").lastPathComponent
//let url_export_heic2 = path_export.appendingPathComponent(filename2)
//try! ctx.writePNGRepresentation(of: gainmap!, to: url_export_heic2, format: CIFormat.RGBA8, colorSpace:CGColorSpace(name: CGColorSpace.displayP3)!)

