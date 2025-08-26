# Convert HDR files to Gain Map HDR

A macOS tool for converting HDR files to Adaptive (Gain Map) HDR / ISO HDR.

Include:

1. toGainMapHDR, which convert png, tiff etc. HDR file to Adaptive HDR (gain map heic file) / ISO HDR (PQ or HLG curve image). The program will read a image as both SDR and HDR image, then calculate difference between two images as gain map.
2. heic_hdr.py, a ChatGPT generated python script to convert all TIFF file to HEIC.
3. HDRmaxKernel.ci.metallib, library needed to get headroom of HDR image.
4. GainMapKernel.ci.metallib, library needed to output Apple gain map.

GUI program created by @vincenttsang [HDR-Gain-Map-Convert](https://github.com/vincenttsang/HDR-Gain-Map-Convert)

Lightroom Plugin created by @fengshenx [LR_GainMap_HDR_Export_Plugin](https://github.com/fengshenx/LR_GainMap_HDR_Export_Plugin)

## Usage

### toGainMapHDR

Convert any HDR Files to Gain_Map_HDR.heic by toGainMapHDR:

`./toGainMapHDR $file_dir $folder_dir $options`

Supported input format: 

* AVIF、JXL、HEIF (in PQ/HLG/Gain map)
* TIFF (in PQ/HLG/Linear32)
* PNG (in PQ/HLG)
* JPG (gain map)
* EXR、HDR

(Note: Some formats have width/height limitation, only support the image file which could be openned by preview app)

#### System Require

Require macOS 15.0+ (Some format support require 26.0+).

PLEASE UPGRADE your system to LATEST version for more compatibility.

PLEASE UPGRADE your system to LATEST version for more compatibility.

#### Options:

-q \<value>: image quality (default: 0.85)

-r \<value>: tone mapping ratio (between 0 and 1, default: 0.2)

    ratio = 0: keep full highlight details
    ratio = 1: hard clip all parts exceeding SDR range
    ratio = -1: only work with -g, generate Apple Gain Map by CIFilter

-b \<file_path>: specify the base image and output in RGB gain map format.

-t \<text>: add extra text after the output file name.

-c \<color space>: output color space (srgb, p3, rec2020), default use source file's color space.

-d \<color depth>: output color depth (default: 8)

-g: output Apple Gain map HDR \*\*

-s: export tone mapped SDR image without HDR gain map

-j: export image in JPEG format

-p: export 10-bit PQ HDR heic image

-h: export HLG HDR heic image (default in 10-bit)

-help: print help information

#### Sample images for options

Quality for 8 bit heic SDR export: (-s -q 0.2~1.0)

| quality0.2                                                   | quality0.4                                                   | quality0.6                                                   |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![test-q=0 2](https://github.com/user-attachments/assets/f6916630-e607-4393-94ab-531b01217f2f) | ![test-q=0 4](https://github.com/user-attachments/assets/78735c04-91ee-42e8-8793-b4bb4a13f5cf) | ![test-q=0 6](https://github.com/user-attachments/assets/2ce8b0c5-5557-4eb2-a915-6355bdd45005) |
| quality0.8                                                   | quality1.0                                                   |                                                              |
| ![test-q=0 8](https://github.com/user-attachments/assets/e0a5813c-c812-413c-b3bc-a395f737e92b) | ![test-q=1.0](https://github.com/user-attachments/assets/a706bc60-8ef3-48bc-a878-6aa5f1be384b) |                                                              |

SDR mapping ratio for jpg SDR export: (-s -j -r 0.0~1.0)

| ratio0.0                                                     | ratio0.2                                                     | ratio0.4                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![test-r-0](https://github.com/user-attachments/assets/719e408f-f274-4346-8f16-5d2e6efc74fe) | ![test-r-0 2](https://github.com/user-attachments/assets/8505d64b-dd40-4dae-93a9-db38fd727e60) | ![test-r-0 4](https://github.com/user-attachments/assets/ec3e3e5d-df27-4c97-b98c-68c835f6b2d1) |
| ratio0.6                                                     | ratio0.8                                                     | ratio1.0                                                     |
| ![test-r-0 6](https://github.com/user-attachments/assets/d012d536-d604-492a-ae71-ae94ee8c20bb) | ![test-r-0 8](https://github.com/user-attachments/assets/3215db3a-99b3-461b-ade6-50256b1cb127) | ![test-r-1 0](https://github.com/user-attachments/assets/a0d4f857-3403-4874-88d4-cdf53ed6694f) |


HDR export: (-j -r 0.0~1.0). Edge.app on macOS not support RGB HDR, using Safari.app.

| ratio0.0 | ratio0.2  | ratio0.4 |
| -------- | --------- | -------- |
| ![test-hdr-0 0](https://github.com/user-attachments/assets/7b53bb9f-bfe6-418c-9e29-c2285f4d7bc8) | ![test-hdr-0 2](https://github.com/user-attachments/assets/1c8c6fb1-bd78-4966-9ddc-0fd48911b38c) | ![test-hdr-0 4](https://github.com/user-attachments/assets/7245b902-7bcc-4ebf-b84a-e60dd1807253) |
| ratio0.6 | ratio0.8 | ratio1.0|
| ![test-hdr-0 6](https://github.com/user-attachments/assets/2fd00f49-ef87-4b05-8b4c-6083724c2394) | ![test-hdr-0 8](https://github.com/user-attachments/assets/64045808-6d75-410b-bc4e-1eb4bad9397e) | ![test-hdr-1 0](https://github.com/user-attachments/assets/a32fa542-9616-48ae-b625-cdbcb6a23c0d)|


#### Sample command：

 `./toGainMapHDR ~/Downloads/abc.png ~/Documents/ -q 0.95 -d 10 -c rec2020`

 `./toGainMapHDR ~/Downloads/abc.tiff ~/Documents/ -q 0.80 -j`

convert gain map abc.avif to gain map heic file and keep base image:

 `./toGainMapHDR ~/Downloads/abc.avif ~/Documents/ -b ./Downloads/abc.avif` 

convert abc.tiff to Apple gain map HDR file (less compatibility, but can adjust SDR mapping ratio):

 `./toGainMapHDR ~/Downloads/abc.tiff ~/Documents/ -g` 

convert abc.tiff to Apple gain map HDR file (more compatibility, with fixed SDR mapping ratio):

 `./toGainMapHDR ~/Downloads/abc.tiff ~/Documents/ -g -r -1` 

convert abc.tiff to HLG HDR file:

 `./toGainMapHDR ~/Downloads/abc.tiff ~/Documents/ -h` 

convert RGB gain map (adaptive HDR) file to monochrome gain map (Apple HDR) heic file:

 `./toGainMapHDR ~/Downloads/abc.heic ~/Downloads/ -g -t -mono` 

#### Note: 

1. Using a specific base photo will result larger file size (approximately double)
2. Exporting 10-bit heic files will result larger file size (approximately double)
3. \*\* Monochrome gain map compatible with Google Photos (Android version), Instagram etc. Recommended to use for sharing.
4. When exporting 8-bit heic photo, color discontinuity may occur in low-texture areas, like clouds, lakes.

### heic_hdr.py

Batch convert all tiff files in a folder by heic_hdr.py:

1. Download all files in a folder:

`git clone https://github.com/chemharuka/toGainMapHDR.git`

`cd toGainMapHDR/bin`

`chmod 711 ./toGainMapHDR`

2. run heic_hdr.py (default run with 8 threads, change it accroding to your chip's performance core.)

`python3 ./heic_hdr.py $folder_for_convert $options`

You may need to change the DIR of toGainMapHDR in heic_hdr.py before running. (in line 44)

#### Sample：

`python3 ./heic_hdr.py ~/Documents/export/ -q 0.90 -c rec2020 -g`

#### Note: 

1. Not support specifying base image in batch converting.

## Sample

Sample Apple Gain Map HDR files: (options: -g -r -1, ONLY this format supported by Edge Browser on macOS)

Sample 1: (Wu-kung Mountains as UNSECO Geopark, Jiangxi, China)
![DJI_1_0616_D](https://github.com/user-attachments/assets/d4fd48bb-6561-496f-b1ab-083ee1ae8a95)

Sample 2: (Sanqing Mountain as World Heritage, Jiangxi, China)
![DJI_1_0226_D](https://github.com/user-attachments/assets/0a718722-6939-41d3-844d-14517442de05)

Sample 3: (Kanbula National Park, Qinghai, China)
![DJI_1_0927_D](https://github.com/user-attachments/assets/66da879e-d56a-4bae-8185-d2d7d462e10f)

## Known Issue

HDR decoding path mis-handle when large AVIF image (long edge ≥ 8192) as input on Intel Mac. This is a problem with the system's built-in function and may be fixed in a future system version.

When using Gain Map HDR image as input, output image brightness might be incorrect. You can export image as PQ HDR then input generated PQ HDR image.

