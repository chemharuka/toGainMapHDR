# Convert HDR files to Gain Map HDR

[中文](README.zh-CN.md)

A macOS tool for converting HDR files to Adaptive (Gain Map) HDR / ISO HDR.

Includes:

1. toGainMapHDR, which converts png, tiff etc. HDR files to Adaptive HDR (gain map heic file) / ISO HDR (PQ or HLG curve image). The program will read an image as both SDR and HDR image, then calculate difference between the two images as gain map.
2. heic_hdr.py, a ChatGPT generated python script to convert all TIFF file to HEIC.
3. GainMapKernel.ci.metallib, library needed to output Apple gain map.
4. RGBGainMapKernel.ci.metallib, library needed to output ISO gain map.

GUI program created by @vincenttsang [HDR-Gain-Map-Convert](https://github.com/vincenttsang/HDR-Gain-Map-Convert)

Lightroom Plugin created by @fengshenx [LR_GainMap_HDR_Export_Plugin](https://github.com/fengshenx/LR_GainMap_HDR_Export_Plugin)

## Usage

### toGainMapHDR

Convert any HDR Files to Gain_Map_HDR.heic by toGainMapHDR:

`./toGainMapHDR $file_dir $folder_dir $options`

Supported input format: 

* AVIF、JXL、HEIF (in PQ/HLG/gain map)
* TIFF (in PQ/HLG/Linear32)
* PNG (in PQ/HLG)
* ISO gain map HDR
* EXR、HDR

Supported output format: 

* ISO Gain Map HDR in HEIC (default)
* Apple Gain Map HDR in HEIC
* PQ/HLG HDR in HEIC
* Tone mapped SDR in HEIC

Notes: 

1. Some formats have width/height limitation, only support the image file which could be opened by Preview.app

2. CIImage cannot handle the brightness of Apple gain map HDR correctly, not recommended to input in this format

3. Do not use zip-compressed TIFF as input, as this will significantly slow down the processing speed

#### System Requirements

Require macOS 26.0+. Fully tested on Apple Silicon.

There are some issues with Intel Mac, not all features available. 

PLEASE UPGRADE your system to LATEST version for more compatibility.

---

### Options:

default: output HDR-heic with ISO gain map in RGB

-q \<value>: image quality (default: 0.85)

-r \<value>: SDR tone mapping ratio (≥1.0, default: 3.0)

    ratio = 1.0: keep full highlight details
    ratio >> 10: lose all highlight details

-R \<value>: max headroom for tone mapping (default: 6.0)

-b \<file_path>: specify the base image

-t \<text>: add extra text after the output file name

-c \<color space>: specify output color space (srgb, p3, rec2020)

-d \<color depth>: specify output color depth (default: 8)

-g: output Apple gain map HDR

-H: subsampling gain map to half size

-m: export ISO gain map HDR in monochrome

-s: export tone mapped SDR image

-p: export 10-bit PQ HDR heic image

-h: export HLG HDR heic image (default in 10-bit)

-help: print help information

---

#### Notes for options

-r: Reduce the picture by `-r` times, and then measure the maximum brightness at this time as the headroom, this headroom will be used for tone mapping. Recommended value for monochrome gain map is 3.0, and 10.0 for RGB gain map.

-R: If `-R` is less than `-r` headroom, this value will be used for tone mapping. `-R` value will also limit headroom of Apple gain map.

-g: Apple gain map use monochrome L8 image with Rec709 like non-linear transformation. (CIImage)

default: Adaptive gain map created as a color (RGB) ratio, and read as YUV420. (CIImage)

-m: Adaptive gain map created as a brightness ratio, and read as L8. (CIImage)

-H: Subsampling gain map to half size. If the width or length is not a multiple of 2, one row or column will be cropped.

-H only: Adaptive gain map created as a color (RGB) ratio, and read as ARGB. (imageIO)

-H -m: Adaptive gain map created as a brightness ratio, and read as L8. (imageIO)

-H -g: Apple gain map created as a brightness ratio, and read as L8 with Rec709 transformation. (CIImage)

### Sample command：

 `./toGainMapHDR ~/Downloads/abc.png ~/Documents/ -q 0.95 -d 10 -c rec2020`

Using an existing gain map HDR as input and keep its embedded base image (no re-tone-mapping):

 `./toGainMapHDR ~/Downloads/abc.avif ~/Documents/ -b ~/Downloads/abc.avif` 

convert abc.tiff to Apple HDR by CIFilter and subsample gain map to half size:

 `./toGainMapHDR ~/Downloads/abc.tiff ~/Documents/ -g -H` 

convert abc.tiff to HLG HDR file:

 `./toGainMapHDR ~/Downloads/abc.tiff ~/Documents/ -h` 

convert RGB gain map (adaptive HDR) file to monochrome gain map (Apple HDR) heic file:

 `./toGainMapHDR ~/Downloads/abc.heic ~/Downloads/ -g -t -mono` 

#### Note: 

1. Using a specific base photo will result larger file size.
2. Subsample the gain map can reduce file size, with slightly lose highlight detail.
3. Images with odd extent will be cropped by 1 pixel while subsampling.
4. \*\* Apple gain map compatible with Google Photos (Android version), Instagram, Edge Browser etc. Recommended to use for sharing.
5. When exporting 8-bit heic image, color discontinuity may occur in low-texture areas, like clouds, lakes.

### heic_hdr.py

Batch convert all tiff files in a folder by heic_hdr.py:

1. Clone \bin to a folder (or download them from release):

`git clone https://github.com/chemharuka/toGainMapHDR.git`

`cd toGainMapHDR/bin`

`chmod 711 ./toGainMapHDR`

2. run heic_hdr.py (default run with 8 threads, change it according to your chip's performance cores.)

`python3 ./heic_hdr.py $folder_for_convert $options`

You may need to change the **DIR** of toGainMapHDR in heic_hdr.py before running. (in line 44)

#### Sample：

`python3 ./heic_hdr.py ~/Documents/export/ -q 0.90 -c rec2020 -g`

#### Note: 

1. Not support specifying base image in batch converting.

## Sample

Sample Apple Gain Map HDR files: (options: -g, ONLY this format supported by Edge Browser on macOS)

Sample 1: (Wu-kung Mountains as UNESCO Geopark, Jiangxi, China)
![DJI_1_0616_D](https://github.com/user-attachments/assets/d4fd48bb-6561-496f-b1ab-083ee1ae8a95)

Sample 2: (Sanqing Mountain as World Heritage, Jiangxi, China)
![DJI_1_0226_D](https://github.com/user-attachments/assets/0a718722-6939-41d3-844d-14517442de05)

Sample 3: (Kanbula National Park, Qinghai, China)
![DJI_1_0927_D](https://github.com/user-attachments/assets/66da879e-d56a-4bae-8185-d2d7d462e10f)

### File Size and Quality

Input image: Half Dome sunset, 16-bit TIFF, 4000x6000 px, 144 MB.

| options                            | JPG     | HEIC    | PSNR/dB | PSNR/dB |
| ---------------------------------- | ------- | ------- | ------- | ------- |
| -p (PQ HDR 10 bit)                 | -       | 5.6 MB  |         | 43.93   |
| -p -q 100                          | -       | 21.5 MB |         | 50.42   |
| -h -d 8 (HLG 8 bit)                | -       | 3.3 MB  |         | ≈40.14  |
| -h (HLG 10 bit)                    | -       | 7.4 MB  |         | ≈44.82  |
| -s (SDR image)                     | 7.5 MB  | 3.9 MB  | 27.94   | 27.83   |
| -g (Apple HDR)                     | 11.1 MB | 6.5 MB  | 40.83   | ≈39.47  |
| -g -H (with subsample)             | 8.4 MB  | 4.6 MB  | 40.66   | ≈39.27  |
| -g -d 10 (Apple HDR in 10 bit)     | -       | 11.0 MB |         | ≈42.38  |
| default (ISO Gain Map HDR)         | 11.5 MB | 7.4 MB  | 43.03   | 41.43   |
| -d 10 (ISO Gain Map HDR in 10 bit) | -       | 11.9 MB |         | 46.08   |
| -q 100 (ISO Gain Map best quality) | 27.5 MB | 26.4 MB | 48.75   | 48.49   |

Compare with other HDR formats exported by LR.

| Format                          | Size       | PSNR/dB |
| ------------------------------- | ---------- | ------- |
| UltraHDR (quality 60)           | 5.1 MB     | 36.96   |
| UltraHDR (quality 85)           | 19.7 MB    | 45.58   |
| AVIF (quality 70 with gain map) | 4.7 MB     | 38.65   |
| AVIF (quality 85 with gain map) | 7.3 MB     | 41.37   |
| AVIF (quality 85, PQ HDR)       | 1.9 MB     | 37.76   |
| AVIF (quality 95, PQ HDR)       | 2.7 MB     | 39.63   |
| AVIF (quality 100, PQ HDR)      | 7.7 MB     | 46.31   |
| JXL (quality 85, PQ HDR)        | 4.9 MB     | 41.30   |

### Sample images for options

Quality for 8 bit heic SDR export: (-s -q 0.2~1.0)

| -s -q                                                        |                                                              |                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| quality0.2    34.22 dB                                       | quality0.4    37.78 dB                                       | quality0.6    41.34 dB                                       |
| ![test-q=0 2](https://github.com/user-attachments/assets/f6916630-e607-4393-94ab-531b01217f2f) | ![test-q=0 4](https://github.com/user-attachments/assets/78735c04-91ee-42e8-8793-b4bb4a13f5cf) | ![test-q=0 6](https://github.com/user-attachments/assets/2ce8b0c5-5557-4eb2-a915-6355bdd45005) |
| quality0.8    45.33 dB                                       | quality1.0    50.31 dB                                       |                                                              |
| ![test-q=0 8](https://github.com/user-attachments/assets/e0a5813c-c812-413c-b3bc-a395f737e92b) | ![test-q=1.0](https://github.com/user-attachments/assets/a706bc60-8ef3-48bc-a878-6aa5f1be384b) |                                                              |

SDR mapping ratio for jpg SDR export: (-s -j -r 1.0~50.0)

| ratio1.0                                                     | ratio2.0                                                     | ratio3.0                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![DJI_air3_2250_D1 0](https://github.com/user-attachments/assets/1a305539-49b0-4c53-8b31-28e907c4f21c) | ![DJI_air3_2250_D2 0](https://github.com/user-attachments/assets/0ba575b9-8a80-442b-bff3-bcf744d86955) | ![DJI_air3_2250_D3 0](https://github.com/user-attachments/assets/96a90f9b-c4ae-420c-bca9-5107ff4aa253) |
| ratio6.0                                                     | ratio20.0                                                     | ratio50.0                                                     |
| ![DJI_air3_2250_D6 0](https://github.com/user-attachments/assets/b9feda17-9e05-4787-aa1d-f0fb68ab5966) | ![DJI_air3_2250_D20 0](https://github.com/user-attachments/assets/93ab6610-1a69-4074-be8f-f9651552dbd3) | ![DJI_air3_2250_D50 0](https://github.com/user-attachments/assets/967d2a61-6d74-446e-8dbe-655e3614bd60) |

HDR export: (-j -r 1.0~50.0). Edge.app on macOS not support RGB HDR, view HDR effect on Safari.app.

| ratio1.0 | ratio2.0  | ratio3.0 |
| -------- | --------- | -------- |
| ![_12742701 0](https://github.com/user-attachments/assets/42e406d3-2d23-45ec-baa5-22837e2ee846) | ![_12742702 0](https://github.com/user-attachments/assets/b6e6b2b5-7c7e-4718-8b9d-1eca6a038fb5) | ![_12742703 0](https://github.com/user-attachments/assets/3a791f5d-da6a-4175-a1e6-bd4a5f865421) |
| ratio6.0 | ratio20.0 | ratio50.0|
| ![_12742706 0](https://github.com/user-attachments/assets/ac5e1680-8298-40ff-be06-913814e0495e) | ![_127427020 0](https://github.com/user-attachments/assets/d80979cf-ab1d-4813-adbb-7a3eff16ee58) | ![_127427050 0](https://github.com/user-attachments/assets/8c3df467-61c1-4f75-889c-412bccf565a4) |




## Known Issue

HDR decoding path mis-handle when large AVIF image (long edge ≥ 8192) as input on Intel Mac.

10-bit Gain Map HDR exporting issue on Intel Mac.
