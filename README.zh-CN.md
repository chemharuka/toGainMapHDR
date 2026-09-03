# 将 HDR 文件转换为 Gain Map HDR

一个用于将 HDR 文件转换为 Adaptive (Gain Map) HDR / ISO HDR 的 macOS 工具。

内容包含：

1. **toGainMapHDR**：将 png、tiff 等 HDR 文件转换为 Adaptive HDR（gain map 的 heic 文件）/ ISO HDR（PQ 或 HLG 曲线的图像）。程序会将一张图片同时作为 SDR 和 HDR 图像读取，然后计算两幅图像之间的差异作为 gain map。
2. **heic_hdr.py**：一个由 ChatGPT 生成的 Python 脚本，用于将文件夹中的所有 TIFF 文件批量转换为 HEIC。
3. **GainMapKernel.ci.metallib**：输出 Apple gain map 所需的库。
4. **RGBGainMapKernel.ci.metallib**：输出 ISO gain map 所需的库。

GUI 程序由 @vincenttsang 开发：[HDR-Gain-Map-Convert](https://github.com/vincenttsang/HDR-Gain-Map-Convert)

Lightroom 插件由 @fengshenx 开发：[LR_GainMap_HDR_Export_Plugin](https://github.com/fengshenx/LR_GainMap_HDR_Export_Plugin)

## 使用方法

### toGainMapHDR

使用 toGainMapHDR 将任意 HDR 文件转换为 Gain_Map_HDR.heic：

`./toGainMapHDR $file_dir $folder_dir $options`

支持的输入格式：

* AVIF、JXL、HEIF（PQ/HLG/gain map）
* TIFF（PQ/HLG/Linear32）
* PNG（PQ/HLG）
* ISO gain map HDR
* EXR、HDR

支持的输出格式：

* HEIC 格式的 ISO Gain Map HDR（默认）
* HEIC 格式的 Apple Gain Map HDR
* HEIC 格式的 PQ/HLG HDR
* HEIC 格式的 Tone mapped SDR

说明：

1. 部分格式存在宽高限制，仅支持能被 Preview.app 打开的图片文件。
2. CIImage 无法正确处理 Apple gain map HDR 的亮度，不建议以该格式作为输入。
3. 请勿使用 zip 压缩的 TIFF 作为输入，这会显著降低处理速度。

#### 系统要求

需要 macOS 26.0 及以上版本。已在 Apple Silicon 上完整测试。

Intel Mac 存在一些问题，并非所有功能都可用。

请将系统升级到**最新**版本以获得更好的兼容性。

---

### 选项：

默认：输出带 ISO gain map（RGB）的 HDR-heic

- -q \<value\>：图像质量（默认：0.85）
- -r \<value\>：SDR 色调映射比率（≥1.0，默认：3.0）

    ratio = 1.0：保留全部高光细节
    ratio >> 10：丢失全部高光细节

- -R \<value\>：色调映射的最大 headroom（默认：6.0）
- -b \<file_path\>：指定基础（base）图像
- -t \<text\>：在输出文件名后附加额外文本
- -c \<color space\>：指定输出色彩空间（srgb、p3、rec2020）
- -d \<color depth\>：指定输出色彩深度（默认：8）
- -g：输出 Apple gain map HDR
- -H：将 gain map 降采样为一半尺寸
- -m：以单色导出 ISO gain map HDR
- -s：导出 tone mapped 的 SDR 图像
- -p：导出 10-bit PQ HDR heic 图像
- -h：导出 HLG HDR heic 图像（默认为 10-bit）
- -help：打印帮助信息

---

#### 选项说明

- **-r**：将图片缩小 `-r` 倍，再测量此时的最大亮度作为 headroom，该 headroom 将用于色调映射。单色 gain map 推荐值为 3.0，RGB gain map 推荐值为 10.0。

- **-R**：如果 `-R` 小于 `-r` 计算出的 headroom，则使用此值进行色调映射。`-R` 也会限制 Apple gain map 的 headroom。

- **-g**：Apple gain map 使用带 Rec709 类非线性变换的单色 L8 图像。（CIImage）

默认：Adaptive gain map 以彩色（RGB）比率生成，并按 YUV420 读取。（CIImage）

- **-m**：Adaptive gain map 以亮度比率生成，并按 L8 读取。（CIImage）

- **-H**：将 gain map 降采样为一半尺寸。若宽或长不是 2 的倍数，将裁剪一行或一列。

- **-H only**：Adaptive gain map 以彩色（RGB）比率生成，并按 ARGB 读取。（imageIO）

- **-H -m**：Adaptive gain map 以亮度比率生成，并按 L8 读取。（imageIO）

- **-H -g**：Apple gain map 以亮度比率生成，并带 Rec709 变换按 L8 读取。（CIImage）

### 示例命令：

 `./toGainMapHDR ~/Downloads/abc.png ~/Documents/ -q 0.95 -d 10 -c rec2020`

以现有的 gain map HDR 作为输入，并保留其内嵌的 base 图像（不重新 tone mapping）：

 `./toGainMapHDR ~/Downloads/abc.avif ~/Documents/ -b ~/Downloads/abc.avif`

使用 CIFilter 将 abc.tiff 转换为 Apple HDR，并将 gain map 降采样为一半尺寸：

 `./toGainMapHDR ~/Downloads/abc.tiff ~/Documents/ -g -H`

将 abc.tiff 转换为 HLG HDR 文件：

 `./toGainMapHDR ~/Downloads/abc.tiff ~/Documents/ -h`

将 RGB gain map（adaptive HDR）文件转换为单色 gain map（Apple HDR）heic 文件：

 `./toGainMapHDR ~/Downloads/abc.heic ~/Downloads/ -g`

#### 注意：

1. 使用特定的基础照片会导致文件体积更大。
2. 对 gain map 进行降采样可减小文件体积，但会轻微损失高光细节。
3. 降采样时，边为奇数的图像会被裁剪 1 像素。
4. \*\* Apple gain map 兼容 Google Photos（Android 版）、Instagram、Edge 浏览器等。推荐用于分享。
5. 导出 8-bit heic 图像时，在云、湖泊等低纹理区域可能出现色彩断层。

### heic_hdr.py

使用 heic_hdr.py 批量转换文件夹中的所有 tiff 文件：

1. 将 bin 克隆到一个文件夹中（或从 release 下载）：

`git clone https://github.com/chemharuka/toGainMapHDR.git`

`cd toGainMapHDR/bin`

`chmod 711 ./toGainMapHDR`

2. 运行 heic_hdr.py（默认以 8 线程运行，请根据你芯片的性能核心数量修改）：

`python3 ./heic_hdr.py $folder_for_convert $options`

运行前你可能需要修改 heic_hdr.py 中 toGainMapHDR 的 **DIR**（第 44 行）。

#### 示例：

`python3 ./heic_hdr.py ~/Documents/export/ -q 0.90 -c rec2020 -g`

#### 注意：

1. 批量转换不支持指定基础图像。

## 示例

Apple Gain Map HDR 示例文件：（选项：-g，macOS 上只有该格式被 Edge 浏览器支持）

示例 1：（江西武功山，UNESCO 世界地质公园）
![DJI_1_0616_D](https://github.com/user-attachments/assets/d4fd48bb-6561-496f-b1ab-083ee1ae8a95)

示例 2：（江西三清山，世界遗产）
![DJI_1_0226_D](https://github.com/user-attachments/assets/0a718722-6939-41d3-844d-14517442de05)

示例 3：（青海坎布拉国家公园）
![DJI_1_0927_D](https://github.com/user-attachments/assets/66da879e-d56a-4bae-8185-d2d7d462e10f)

### 文件体积与质量

输入图像：Half Dome 日落，16-bit TIFF，4000x6000 px，144 MB。

| 选项                                | JPG     | HEIC    | PSNR/dB | PSNR/dB |
| ---------------------------------- | ------- | ------- | ------- | ------- |
| -p (PQ HDR 10 bit)                 | -       | 5.6 MB  |         | 43.93   |
| -p -q 100                          | -       | 21.5 MB |         | 50.42   |
| -h -d 8 (HLG 8 bit)                | -       | 3.3 MB  |         | ≈40.14  |
| -h (HLG 10 bit)                    | -       | 7.4 MB  |         | ≈44.82  |
| -s (SDR 图像)                      | 7.5 MB  | 3.9 MB  | 27.94   | 27.83   |
| -g (Apple HDR)                     | 11.1 MB | 6.5 MB  | 40.83   | ≈39.47  |
| -g -H（带降采样）                  | 8.4 MB  | 4.6 MB  | 40.66   | ≈39.27  |
| -g -d 10 (10-bit 的 Apple HDR)     | -       | 11.0 MB |         | ≈42.38  |
| 默认 (ISO Gain Map HDR)            | 11.5 MB | 7.4 MB  | 43.03   | 41.43   |
| -d 10 (10-bit 的 ISO Gain Map HDR) | -       | 11.9 MB |         | 46.08   |
| -q 100 (最佳质量的 ISO Gain Map)   | 27.5 MB | 26.4 MB | 48.75   | 48.49   |

与 LR 导出的其他 HDR 格式对比。

| 格式                              | 大小     | PSNR/dB |
| ------------------------------- | ---------- | ------- |
| UltraHDR (quality 60)           | 5.1 MB     | 36.96   |
| UltraHDR (quality 85)           | 19.7 MB    | 45.58   |
| AVIF (quality 70 with gain map) | 4.7 MB     | 38.65   |
| AVIF (quality 85 with gain map) | 7.3 MB     | 41.37   |
| AVIF (quality 85, PQ HDR)       | 1.9 MB     | 37.76   |
| AVIF (quality 95, PQ HDR)       | 2.7 MB     | 39.63   |
| AVIF (quality 100, PQ HDR)      | 7.7 MB     | 46.31   |
| JXL (quality 85, PQ HDR)        | 4.9 MB     | 41.30   |

### 选项的示例图片

8-bit heic SDR 导出的质量：（-s -q 0.2~1.0）

| -s -q                                                        |                                                              |                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| quality0.2    34.22 dB                                       | quality0.4    37.78 dB                                       | quality0.6    41.34 dB                                       |
| ![test-q=0 2](https://github.com/user-attachments/assets/f6916630-e607-4393-94ab-531b01217f2f) | ![test-q=0 4](https://github.com/user-attachments/assets/78735c04-91ee-42e8-8793-b4bb4a13f5cf) | ![test-q=0 6](https://github.com/user-attachments/assets/2ce8b0c5-5557-4eb2-a915-6355bdd45005) |
| quality0.8    45.33 dB                                       | quality1.0    50.31 dB                                       |                                                              |
| ![test-q=0 8](https://github.com/user-attachments/assets/e0a5813c-c812-413c-b3bc-a395f737e92b) | ![test-q=1.0](https://github.com/user-attachments/assets/a706bc60-8ef3-48bc-a878-6aa5f1be384b) |                                                              |

jpg SDR 导出的 SDR 映射比率：（-s -j -r 1.0~50.0）

| ratio1.0                                                     | ratio2.0                                                     | ratio3.0                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![DJI_air3_2250_D1 0](https://github.com/user-attachments/assets/1a305539-49b0-4c53-8b31-28e907c4f21c) | ![DJI_air3_2250_D2 0](https://github.com/user-attachments/assets/0ba575b9-8a80-442b-bff3-bcf744d86955) | ![DJI_air3_2250_D3 0](https://github.com/user-attachments/assets/96a90f9b-c4ae-420c-bca9-5107ff4aa253) |
| ratio6.0                                                     | ratio20.0                                                     | ratio50.0                                                     |
| ![DJI_air3_2250_D6 0](https://github.com/user-attachments/assets/b9feda17-9e05-4787-aa1d-f0fb68ab5966) | ![DJI_air3_2250_D20 0](https://github.com/user-attachments/assets/93ab6610-1a69-4074-be8f-f9651552dbd3) | ![DJI_air3_2250_D50 0](https://github.com/user-attachments/assets/967d2a61-6d74-446e-8dbe-655e3614bd60) |

HDR 导出：（-j -r 1.0~50.0）。macOS 上的 Edge.app 不支持 RGB HDR，请在 Safari.app 中查看 HDR 效果。

| ratio1.0 | ratio2.0  | ratio3.0 |
| -------- | --------- | -------- |
| ![_12742701 0](https://github.com/user-attachments/assets/42e406d3-2d23-45ec-baa5-22837e2ee846) | ![_12742702 0](https://github.com/user-attachments/assets/b6e6b2b5-7c7e-4718-8b9d-1eca6a038fb5) | ![_12742703 0](https://github.com/user-attachments/assets/3a791f5d-da6a-4175-a1e6-bd4a5f865421) |
| ratio6.0 | ratio20.0 | ratio50.0 |
| ![_12742706 0](https://github.com/user-attachments/assets/ac5e1680-8298-40ff-be06-913814e0495e) | ![_127427020 0](https://github.com/user-attachments/assets/d80979cf-ab1d-4813-adbb-7a3eff16ee58) | ![_127427050 0](https://github.com/user-attachments/assets/8c3df467-61c1-4f75-889c-412bccf565a4) |

## 已知问题

Intel Mac 上以较大 AVIF 图像（长边 ≥ 8192）作为输入时，HDR 解码路径处理错误。

Intel Mac 上存在 10-bit Gain Map HDR 导出问题。
