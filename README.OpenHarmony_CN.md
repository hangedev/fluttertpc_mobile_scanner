> 模板版本: v0.1.0

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

本项目基于 [mobile_scanner](https://pub.dev/packages/mobile_scanner) 开发。

## 目录

- [简介](#简介)
- [下载安装](#下载安装)
- [使用示例](#使用示例)
- [约束与限制](#约束与限制)
- [使用说明](#使用说明)
- [接口说明](#接口说明)
- [新增特性](#新增特性)
- [遗留问题](#遗留问题)
- [常见问题](#常见问题)
- [目录结构](#目录结构)
- [贡献代码](#贡献代码)
- [开源协议](#开源协议)

## 简介

mobile_scanner 是一款通用条码/二维码扫描 Flutter 插件。在 OpenHarmony 上通过华为 ScanKit 实现条码检测，支持实时相机预览扫描、图片条码分析、闪光灯控制、变焦控制等功能。

## 下载安装

### 依赖配置

在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  mobile_scanner:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
      ref: 6.0.10-ohos-1.0.0-beta.2
```

执行命令：

```bash
flutter pub get
```

### TAG 版本对应表

| Flutter (OHOS) | TAG |
|----------------|-----|
| 3.7.12-ohos-1.0.6 | 6.0.10-ohos-1.0.0-beta.2 |
| 3.22.1-ohos-1.0.1 | 6.0.10-ohos-1.0.0-beta.2 |
| 3.27.4-ohos-1.0.0 | 6.0.10-ohos-1.0.0-beta.2 |

## 使用示例

### 简单扫描示例

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// 1. 创建扫描页面
class BarcodeScannerSimple extends StatefulWidget {
  const BarcodeScannerSimple({super.key});

  @override
  State<BarcodeScannerSimple> createState() => _BarcodeScannerSimpleState();
}

class _BarcodeScannerSimpleState extends State<BarcodeScannerSimple> {
  Barcode? _barcode;

  // 2. 处理条码检测结果
  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('简单扫描器')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 3. 使用 MobileScanner Widget 展示相机预览
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          // 4. 显示扫描结果
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: Text(
                    _barcode?.displayValue ?? '扫描中...',
                    overflow: TextOverflow.fade,
                    style: const TextStyle(color: Colors.white),
                  ))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 完整使用流程

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

// 1. 创建控制器
// 注意：OHOS 仅支持后置摄像头（facing 参数被忽略）
final MobileScannerController controller = MobileScannerController(
  autoStart: false,
  torchEnabled: false,
  returnImage: false,
  formats: [BarcodeFormat.qrCode], // OHOS 支持 BarcodeFormat 中列出的所有格式
);

// 2. 监听条码流
controller.barcodes.listen((BarcodeCapture capture) {
  for (final Barcode barcode in capture.barcodes) {
    // 注意：OHOS 上 barcode.rawBytes 为 null（ScanKit 不支持）
    // 注意：OHOS 上结构化内容 barcode.type 始终返回 BarcodeType.unknown
    print('扫描到条码: ${barcode.displayValue}');
  }
});

// 3. 启动扫描
await controller.start();

// 4. Widget 使用
MobileScanner(
  controller: controller,
  onDetect: (BarcodeCapture capture) {
    // 处理条码检测结果
  },
  errorBuilder: (context, error, child) {
    return Text('扫描器错误: $error');
  },
);

// 5. 暂停/恢复（轻量级）
await controller.pause();
await controller.start();

// 6. 停止并释放资源
await controller.stop();
await controller.dispose();
```

### 独立接口示例

**toggleTorch（切换闪光灯）：**
```dart
// 切换闪光灯开/关
// 注意：OHOS 不支持 TorchState.auto 模式
await controller.toggleTorch();
```

**setZoomScale / resetZoomScale（设置/重置变焦）：**
```dart
// 设置相机变焦倍数
// 注意：OHOS 变焦范围为 0.0 ~ 10.0（其余平台为 0.0 ~ 1.0）
await controller.setZoomScale(2.0); // OHOS 上 2x 变焦
// 重置变焦到 1x
await controller.resetZoomScale();
```

**analyzeImage（分析图片）：**
```dart
// 分析图片文件中的条码（OHOS 通过 ScanKit 支持）
final BarcodeCapture? result = await controller.analyzeImage(
  '/path/to/image.jpg',
  formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
);
if (result != null) {
  for (final Barcode barcode in result.barcodes) {
    print('检测到条码: ${barcode.displayValue}');
  }
}
```

**updateScanWindow（更新扫码区域）：**
```dart
import 'dart:ui';

// 更新扫码窗口区域（仅在此区域内扫描）
controller.updateScanWindow(
  Rect.fromLTWH(50, 100, 300, 300),
);
```

**pause / resume（暂停/恢复）：**
```dart
// 暂停相机（轻量级，保留资源）
await controller.pause();
// 恢复扫描
await controller.start();
```

**switchCamera（切换摄像头）：**
```dart
// 注意：OHOS 不支持切换摄像头（仅后置摄像头可用）
await controller.switchCamera();
```

## 约束与限制

### 兼容性

| 三方库版本 | Flutter (OHOS) | DevEco Studio | SDK | ROM |
|-----------|----------------|---------------|-----|------|
| 6.0.10 | 3.7.12-ohos-1.0.6 | 5.0.13.200 | 5.0.0(12) | 5.1.0.120 SP3 |
| 6.0.10 | 3.22.1-ohos-1.0.1 | 5.0.13.200 | 5.0.0(12) | 5.1.0.120 SP3 |
| 6.0.10 | 3.27.4-ohos-1.0.0 | 5.0.13.200 | 5.0.0(12) | 5.1.0.120 SP3 |

> **已知不兼容情况：**
> - OHOS 不支持前置摄像头切换
> - `detectionSpeed`、`detectionTimeoutMs`、`cameraResolution`、`useNewCameraSelector` 在 OHOS 上不可用
> - 结构化条码内容解析（calendarEvent、contactInfo 等）在 OHOS 上返回 `type: unknown`
> - `zoomScaleState` 事件在 OHOS 上不可用（缩放状态通过 setScale/resetScale 同步返回）
> - `TorchState.auto` 在 OHOS 上不可用

### 权限要求

在 entry 目录下的 `module.json5` 中添加相机权限：

```diff
...
"requestPermissions": [
+  {
+    "name": "ohos.permission.CAMERA",
+    "reason": "$string:camera_reason",
+    "usedScene": {
+      "abilities": [
+        "EntryAbility"
+      ],
+      "when":"inuse"
+    }
+  }
]
```

在 `entry/src/main/resources/base/element/string.json` 中添加权限申请原因：

```diff
...
{
  "string": [
+    {
+      "name": "camera_reason",
+      "value": "使用相机"
+    }
  ]
}
```

### 环境配置

**前置要求：**
- DevEco Studio 5.0.13.200 或更高版本
- OHOS SDK 5.0.0(12) 或更高版本
- Flutter OHOS 插件 3.7.12-ohos-1.0.6 / 3.22.1-ohos-1.0.1 / 3.27.4-ohos-1.0.0

**构建步骤：**
1. 从官方网站安装 DevEco Studio
2. 在 DevEco Studio 中配置 OHOS SDK（设置 → SDK Manager → ohos）
3. 克隆项目并执行 `flutter pub get`
4. 在 DevEco Studio 中打开 `ohos/` 目录进行 OHOS 特定构建配置
5. 使用 DevEco Studio 或 CLI 构建和运行

## 使用说明

> **MobileScannerController** 是核心控制器，负责管理扫描生命周期（启动、暂停、停止、释放）。
> 通过 `barcodes` 流接收条码检测结果，通过 `MobileScanner` Widget 展示相机预览。

### 典型使用流程

1. 创建 `MobileScannerController` 实例，配置扫描参数
2. 监听 `controller.barcodes` 流获取检测结果
3. 使用 `MobileScanner` Widget 展示相机预览
4. 调用 `controller.start()` 启动扫描
5. 使用完毕后调用 `controller.dispose()` 释放资源

## 接口说明

> "OHOS 支持"列为 yes 表示 ohos 平台支持该属性；no 表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android。

### 方法列表

| 名称 | 描述 | 类型 | 输入 | 输出 | OHOS 支持 |
|----------|----------------|-----------|-----------|------------|-----------------|
| start | 开始扫码服务 | function | {CameraFacing? cameraDirection} | Future\<void\> | yes |
| stop | 停止扫码（不释放控制器） | function | {bool? force} | Future\<void\> | yes |
| pause | 暂停扫码（轻量级，保留资源） | function | {bool? force} | Future\<void\> | yes |
| toggleTorch | 开启/关闭相机闪光灯 | function | / | Future\<void\> | yes |
| analyzeImage | 识别图像文件中的条码 | function | String path, {List\<BarcodeFormat\> formats = const \<BarcodeFormat\>[]} | Future\<BarcodeCapture?\> | yes |
| setZoomScale | 设置相机变焦比 | function | double zoomScale | Future\<void\> | yes |
| resetZoomScale | 重置相机变焦比为 1x | function | / | Future\<void\> | yes |
| updateScanWindow | 更新扫码框大小 | function | Rect? window | Future\<void\> | yes |
| switchCamera | 切换摄像头 | function | / | Future\<void\> | yes |
| dispose | 释放控制器持有的所有资源 | function | / | Future\<void\> | yes |

**额外数据流：**

| 名称 | 描述 | 类型 | OHOS 支持 |
|----------|----------------|-----------|-----------------|
| barcodes | 条码检测结果流 | Stream\<BarcodeCapture\> | yes |
| zoomScaleState | 缩放比例变化事件流 | Stream\<double\> | no |

- [ ] 自定义二维码扫描无法切换到前置摄像头: [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)

#### MobileScannerController

| 名称 | 描述 | 类型 | OHOS 支持 |
|----------|----------------|-----------|-----------------|
| facing | 选择相机朝向 | CameraFacing | no |
| torchEnabled | 开启/关闭闪光灯 | bool | yes |
| returnImage | 扫码成功时返回图像缓冲区 | bool | yes |
| formats | 码制式格式列表 | List\<BarcodeFormat\> | yes |
| detectionTimeoutMs | 设置扫码超时时间（毫秒） | int | no |
| autoStart | 初始化时自动启动扫码服务 | bool | yes |
| cameraResolution | 相机分辨率 | Size | no |
| useNewCameraSelector | 使用新的分辨率选择器 | bool | no |
| detectionSpeed | 设置扫码检测速度 | DetectionSpeed | no |

### 额外参数

| 名称 | 描述 | 类型 | OHOS 支持 |
|----------|----------------|-----------|-----------------|
| window | 扫码框大小 | Rect? | yes |
| zoomScale | 相机变焦比（OHOS：0.0~10.0，其余平台：0.0~1.0，最大值表示最远缩放） | double? | yes（OHOS 范围：0.0~10.0） |
| path | 图像文件路径 | String? | yes |

### 数据类

#### BarcodeCapture

条码检测返回的结果容器，包含检测到的条码列表及图像帧。

| 名称 | 描述 | 类型 | OHOS 支持 |
|------|------|------|-----------|
| barcodes | List\<Barcode\> | 检测到的条码列表 | yes |
| image | Uint8List? | 原始图像数据（`returnImage` 启用时返回） | yes |
| raw | Object? | 条码扫描的原始数据（输入图像、条码和尺寸） | yes |
| size | Size | 捕获图像尺寸 | yes |

#### Barcode

单个检测到的条码。

| 属性 | 类型 | 描述 | OHOS 支持 |
|-------------|----------|----------------|-----------------|
| displayValue | String? | 人类可读的解码内容 | yes |
| rawValue | String? | 原始解码内容（字符串） | yes |
| format | BarcodeFormat | 检测到的条码格式（如 qrCode、code128） | yes |
| type | BarcodeType | 结构化内容类型（calendarEvent、contactInfo、email、geoPoint、isbn、phone、product、sms、text、url、wifi、driverLicense、unknown） | partially（OHOS 上所有结构化类型均返回 `type: unknown`） |
| rawBytes | Uint8List? | 条码原始字节数据 | no（ScanKit 不提供原始字节数据） |
| corners | List\<Offset\> | 条码的四个角点（顺时针，从左上开始） | yes |
| size | Size | 条码边界框的标准化尺寸 | yes |
| calendarEvent | CalendarEvent? | 条码中嵌入的日历事件 | partially（OHOS 上返回 type: unknown） |
| contactInfo | ContactInfo? | 条码中嵌入的联系人信息（如 vCard） | partially（OHOS 上返回 type: unknown） |
| driverLicense | DriverLicense? | 条码中嵌入的驾照信息 | partially（OHOS 上返回 type: unknown） |
| email | Email? | 条码中嵌入的邮件信息 | partially（OHOS 上返回 type: unknown） |
| geoPoint | GeoPoint? | 条码中嵌入的地理坐标 | partially（OHOS 上返回 type: unknown） |
| phone | Phone? | 条码中嵌入的电话号码 | partially（OHOS 上返回 type: unknown） |
| sms | SMS? | 条码中嵌入的短信消息 | partially（OHOS 上返回 type: unknown） |
| url | UrlBookmark? | 条码中嵌入的 URL 书签 | partially（OHOS 上返回 type: unknown） |
| wifi | WiFi? | 条码中嵌入的 WiFi 配置 | partially（OHOS 上返回 type: unknown） |

#### BarcodeType

表示从条码中提取的结构化内容类型的枚举。

| 枚举值 | 描述 |
|------------------|----------------|
| unknown | 未识别或不支持的类型 |
| contactInfo | 联系人信息（如 vCard） |
| email | 电子邮件地址 |
| isbn | ISBN |
| phone | 电话号码 |
| product | 产品代码 |
| sms | 短信消息 |
| text | 纯文本 |
| url | URL |
| wifi | WiFi 配置 |
| geo | 地理坐标 |
| calendarEvent | 日历事件（如 vEvent） |
| driverLicense | 驾照信息 |

#### BarcodeFormat

指定要扫描的条码码制的枚举。

| 枚举值 | 描述 | OHOS 支持 |
|------------------|----------------|-----------------|
| unknown | 未知格式 | yes |
| all | 所有支持的格式 | yes |
| code128 | Code 128 | yes |
| code39 | Code 39 | yes |
| code93 | Code 93 | yes |
| codabar | Codabar | yes |
| dataMatrix | Data Matrix | yes |
| ean13 | EAN-13 | yes |
| ean8 | EAN-8 | yes |
| itf | ITF（Interleaved Two-of-Five） | yes |
| qrCode | QR 码 | yes |
| upcA | UPC-A | yes |
| upcE | UPC-E | yes |
| pdf417 | PDF417 | yes |
| aztec | Aztec 码 | yes |

#### MobileScannerState

扫描控制器的当前状态。

| 属性 | 类型 | 描述 | OHOS 支持 |
|-------------|----------|----------------|-----------------|
| availableCameras | int? | 可用相机数量（null 表示未知） | yes |
| cameraDirection | CameraFacing | 当前相机朝向 | yes |
| isInitialized | bool | 扫描器是否已初始化 | yes |
| isRunning | bool | 扫描器是否正在运行 | yes |
| torchState | TorchState | 当前闪光灯状态 | yes |
| zoomScale | double | 当前缩放比例 | yes |
| size | Size | 相机输出尺寸 | yes |
| error | MobileScannerException? | 设置或使用相机时的错误 | yes |
| hasCameraPermission | bool | 是否已获得相机权限（getter） | yes |

#### MobileScannerException

表示扫描过程中发生的错误，通过 `onDetectError` 回调或错误流传递。

| 属性 | 类型 | 描述 |
|-------------|----------|----------------|
| errorCode | MobileScannerErrorCode | 异常的错误码（如 controllerDisposed、permissionDenied） |
| errorDetails | MobileScannerErrorDetails? | 来自平台的附加错误详情 |

#### StartOptions

`start()` 方法的配置选项。

| 属性 | 类型 | 描述 | OHOS 支持 |
|------|------|------|-----------|
| cameraDirection | CameraFacing | 启动时使用的摄像头方向 | no（扫描始终使用默认后置摄像头） |
| cameraResolution | Size? | 期望的相机分辨率 | no |
| detectionSpeed | DetectionSpeed | 检测速度模式 | no |
| detectionTimeoutMs | int | 检测超时时间（毫秒） | no |
| formats | List\<BarcodeFormat\> | 要检测的条码格式列表 | yes |
| returnImage | bool | 是否返回扫描图像数据 | yes |
| torchEnabled | bool | 启动时是否开启闪光灯 | yes |
| useNewCameraSelector | bool | 是否使用新分辨率选择器 | no |

#### CameraFacing

摄像头方向的枚举。

| 枚举值 | 描述 | OHOS 支持 |
|------------------|----------------|-----------------|
| back | 后置摄像头 | yes |
| front | 前置摄像头 | no（ScanKit 不支持前置摄像头选择） |

#### TorchState

闪光灯状态的枚举。

| 枚举值 | 描述 | OHOS 支持 |
|------------------|----------------|-----------------|
| unavailable | 闪光灯不可用（无闪光灯硬件） | yes |
| off | 闪光灯关闭 | yes |
| on | 闪光灯开启 | yes |
| auto | 自动模式 | no（仅 iOS 支持） |

#### DetectionSpeed

检测频率控制的枚举。

| 枚举值 | 描述 | OHOS 支持 |
|------------------|----------------|-----------------|
| noDuplicates | 每条条码仅允许扫描一次；在扫描到另一条码之前，不重复处理当前条码 | no |
| normal | 常规检测速度，遵守配置的超时时间 | no |
| unrestricted | 无限制检测速度（最大吞吐量） | no |

#### MobileScannerErrorCode

移动扫描器错误码枚举。

| 枚举值 | 描述 |
|------------------|----------------|
| controllerAlreadyInitialized | 控制器已启动，需先 stop 再重启 |
| controllerDisposed | 控制器已被释放后使用 |
| controllerUninitialized | 控制器未初始化（未调用 start）时使用 |
| genericError | 通用错误 |
| permissionDenied | 相机权限被拒绝 |
| unsupported | 当前设备不支持扫描 |

#### MobileScannerAuthorizationState

扫描器授权状态枚举。

| 枚举值 | 描述 |
|------------------|----------------|
| undetermined | 尚未请求所需权限 |
| authorized | 已获得所需权限 |
| denied | 用户拒绝了所需权限 |

#### MobileScannerViewAttributes

扫描器视图属性，由 `start()` 返回。

| 属性 | 类型 | 描述 | OHOS 支持 |
|------|------|------|-----------|
| currentTorchMode | TorchState | 当前闪光灯状态 | yes |
| numberOfCameras | int? | 可用相机数量 | yes |
| size | Size | 相机输出尺寸 | yes |
| cameraDirection | CameraFacing? | 平台实际使用的摄像头方向 | yes |

#### ScannerErrorWidget

扫描器错误显示 Widget。

| 属性 | 类型 | 描述 | OHOS 支持 |
|------|------|------|-----------|
| error | MobileScannerException | 要显示的异常信息 | yes |

#### MobileScannerErrorDetails

`MobileScannerException` 的原始错误详情。

| 属性 | 类型 | 描述 |
|-------------|----------|----------------|
| code | String? | `PlatformException` 的错误码 |
| details | Object? | `PlatformException` 的详情 |
| message | String? | `PlatformException` 的错误消息 |

#### MobileScannerBarcodeException

处理输入帧时条码扫描错误抛出的异常。

| 属性 | 类型 | 描述 |
|-------------|----------|----------------|
| message | String? | 异常的错误消息 |

#### Address

条码中提取的地址信息。

| 属性 | 类型 | 描述 |
|-------------|----------|----------------|
| addressLines | List\<String\> | 地址行列表 |
| type | AddressType | 地址类型（work、home、unknown） |

#### PersonName

人员姓名，分为各组成部分。

| 属性 | 类型 | 描述 |
|-------------|----------|----------------|
| first | String? | 名 |
| middle | String? | 中间名 |
| last | String? | 姓 |
| prefix | String? | 姓名前缀 |
| suffix | String? | 姓名后缀 |
| formattedName | String? | 格式化姓名 |
| pronunciation | String? | 姓名发音（日语电话簿假名） |

#### UrlBookmark

来自条码的 URL 和标题（如 MEBKM）。

| 属性 | 类型 | 描述 |
|-------------|----------|----------------|
| url | String | 书签的 URL |
| title | String? | 书签的标题 |

#### AddressType

地址类型枚举。

| 枚举值 | 描述 |
|------------------|----------------|
| unknown | 未知地址类型 |
| work | 工作地址 |
| home | 家庭地址 |

#### EmailType

邮件类型枚举。

| 枚举值 | 描述 |
|------------------|----------------|
| unknown | 未知邮件类型 |
| work | 工作邮件 |
| home | 家庭邮件 |

#### EncryptionType

WiFi 加密类型枚举。

| 枚举值 | 描述 |
|------------------|----------------|
| unknown | 未知加密类型 |
| open | 未加密 |
| wpa | WPA 加密 |
| wep | WEP 加密 |

#### PhoneType

电话类型枚举。

| 枚举值 | 描述 |
|------------------|----------------|
| unknown | 未知电话类型 |
| work | 工作电话 |
| home | 家庭电话 |
| fax | 传真 |
| mobile | 手机 |

### MobileScanner Widget

| 名称 | 描述 | 类型 | OHOS 支持 |
|----------|----------------|-----------|-----------------|
| constructor | 创建 MobileScanner Widget | Widget | yes |
| controller | MobileScannerController 实例 | MobileScannerController | yes |
| onDetect | 条码检测回调 | void Function(BarcodeCapture) | yes |
| onDetectError | 检测错误回调 | void Function(Object,StackTrace?) | yes |
| errorBuilder | 自定义错误 Widget 构建器 | Widget Function(BuildContext, MobileScannerException, Widget?) | yes |
| placeholderBuilder | 初始化时占位 Widget 构建器 | Widget Function(BuildContext,Object?) | yes |
| fit | 扫描器在 Widget 中的适配方式 | BoxFit | yes |
| scanWindow | 扫码区域 | Rect? | yes |
| overlayBuilder | 在扫描器上叠加 Widget | Widget Function(BuildContext,Rect?) | yes |
| scanWindowUpdateThreshold | 扫描窗口更新阈值 | double | yes |

## 新增特性

无。

## 遗留问题

- [ ] 自定义二维码扫描无法切换到前置摄像头：[issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)
- [ ] `hasFlashUnit` 检测在某些设备上可能返回 false（使用 CameraKit API）
- [ ] `analyzeImage` 的格式过滤受 ScanKit 能力限制

## 常见问题

### 平台限制

以下功能在 OHOS 上因 ScanKit API 限制而不可用或受限：

| 功能 | 状态 | 说明 |
|------|------|------|
| 前置摄像头切换 | 不支持 | ScanKit customScan 不支持选择摄像头方向 |
| 检测速度配置 | 不支持 | ScanKit customScan 无速度配置 API |
| 检测超时配置 | 不支持 | 使用自定义 setTimeout 替代（250ms/100ms） |
| 相机分辨率控制 | 不支持 | ScanKit 内部管理分辨率 |
| useNewCameraSelector | 不支持 | 仅 Android 支持 |
| 结构化条码内容解析 | 不支持 | CalendarEvent、ContactInfo、Email、GeoPoint、Phone、SMS、URL、WiFi、DriverLicense 均返回 type: unknown |
| rawBytes 字段 | 不支持 | ScanKit ScanResult 不提供原始字节数据 |
| TorchState.auto | 不支持 | 仅 iOS 支持 |
| zoomScaleState 事件 | 不可用 | 缩放状态通过 setScale/resetScale 同步返回 |

### 迁移指南

#### 从 6.0.10-ohos-1 升级到 6.0.10-ohos-2

无破坏性 API 变更。以下改进对用户透明：

- **内存泄漏修复**：所有系统资源（PixelMap、ImagePacker、ImageSource）被正确释放
- **更好的错误处理**：异常被正确传播到 Flutter 层
- **一致性改进**：`setScale`/`resetScale` 现在返回 `null`（void）符合预期
- **稳定性增强**：引擎分离时正确清理所有资源

#### 通用升级步骤

1. 更新 pubspec.yaml 中的依赖版本
2. 执行 `flutter pub get`
3. 查看 [CHANGELOG.OpenHarmony.md](./CHANGELOG.OpenHarmony.md) 了解详细变更

## 目录结构

```
├── lib/                         # 核心代码目录
│   ├── mobile_scanner.dart      # 入口文件
│   ├── src/
│   │   ├── mobile_scanner.dart           # MobileScanner Widget
│   │   ├── mobile_scanner_controller.dart # 扫描控制器
│   │   ├── mobile_scanner_exception.dart  # 异常定义
│   │   ├── mobile_scanner_platform_interface.dart # 平台接口
│   │   ├── mobile_scanner_view_attributes.dart    # 视图属性
│   │   ├── enums/                 # 枚举定义
│   │   └── objects/               # 数据模型
│   └── ...
├── ohos/                        # OpenHarmony 原生代码
│   └── src/main/ets/
│       ├── MobileScannerPlugin.ets  # 插件主实现
│       ├── Barcode.ets              # 条码数据模型与转换
│       ├── CameraUtil.ets           # 相机工具函数
│       └── CameraPermissions.ets    # 权限管理
├── example/                      # 示例工程
├── test/                         # 单元测试
├── README.OpenHarmony.md         # 英文文档
├── README.OpenHarmony_CN.md      # 中文文档
└── CHANGELOG.OpenHarmony.md      # 变更日志
```

## 贡献代码

欢迎通过 Issue 或 Pull Request 贡献代码。请确保：

1. 代码风格遵循项目规范
2. 新增功能包含单元测试
3. 文档已同步更新

## 开源协议

本项目基于 [BSD 3-Clause License](/LICENSE)，请自由地享受和参与开源。