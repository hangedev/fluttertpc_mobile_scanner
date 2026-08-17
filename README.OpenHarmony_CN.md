> 模板版本: v0.0.1

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

本项目基于 [mobile_scanner](https://pub.dev/packages/mobile_scanner) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入工程目录并在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  fluttertpc_mobile_scanner:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: TAG  # Select a TAG from the TAG version mapping table below
```

执行命令：

```bash
flutter pub get
```

### 1.2 TAG 版本对应表

| Flutter 框架版本 | TAG 名称 | 分支名 |
|---|---|---|
| 3.7 | 3.5.6-ohos-1.0.0-beta.1 | master |
| 3.22 | 6.0.2-ohos-1.0.0 | br_v6.0.2_ohos |
| 3.27 | 6.0.10-ohos-1.0.0 | br_v6.0.10_ohos |
| 3.35 | 7.1.4-ohos-1.0.0 | br_v7.1.4_ohos |
		
### 1.3 完整调用流程

在 Dart 代码中导入并使用：

```dart
// 1. 导入库
import 'package:mobile_scanner/mobile_scanner.dart';

// 2. 创建控制器（可选，不传则使用默认配置）
final controller = MobileScannerController(
  autoStart: true,       // 初始化时自动启动扫码
  returnImage: false,    // 是否返回图像缓冲区
  torchEnabled: false,   // 是否开启闪光灯
  formats: const [],     // 空表示检测所有码制式
);

// 3. 使用 MobileScanner Widget 渲染扫码界面
MobileScanner(
  controller: controller,
  onDetect: (BarcodeCapture capture) {
    // 处理扫码结果
    for (final barcode in capture.barcodes) {
      print('条码值: ${barcode.rawValue}');
    }
  },
);

// 4. 释放资源（在 State.dispose() 中调用）
controller.dispose();
```

### 1.4 使用案例

完整的使用案例详见 [example](/example/lib/main.dart)。

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过：

| 三方库版本 | Flutter (OHOS) | SDK | DevEco Studio | ROM |
|-----------|----------------|-----|---------------|-----|
| 6.0.2 | 3.22.1-ohos-1.0.1 | 5.0.0(17) | 6.1.1.290 | 6.1.0.135.SP8 |

**不兼容说明：**
- Flutter 版本低于 3.22.1-ohos-1.0.1 不支持
- SDK 版本低于 5.0.0(12) 不支持
- OHOS 3.x 及以下版本不兼容

**升级迁移指南：**
- 从 5.x 升级到 6.0.2：`MobileScannerState` 已重命名为 `MobileScannerAuthorizationState`，控制器改为 `ChangeNotifier`
- 从 6.0.0 升级到 6.0.2：`analyzeImage` 格式支持已修复，iOS 需排除 arm64 模拟器架构

### 2.2 权限与开发环境配置

#### 权限配置

**（1）在 `entry/src/main/module.json5` 中添加相机权限：**

```diff
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

**（2）在 `entry/src/main/resources/base/element/string.json` 中添加权限原因：**

```diff
{
  "string": [
+    {
+      "name": "camera_reason",
+      "value": "使用相机"
+    }
  ]
}
```

#### 开发环境配置

1. 安装 DevEco Studio 5.0.13.200 或更高版本
2. 安装 OHOS SDK 5.0.0(12) 或更高版本
3. 配置 `oh-package.json5` 依赖
4. 使用 `flutter pub get` 拉取依赖
5. 使用 DevEco Studio 打开 `ohos/` 目录进行编译构建

## 3. API

> [!TIP] "ohos 支持" 列为 **yes** 表示 ohos 平台支持该接口；**no** 则表示不支持；**partially** 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android。

### 3.1 MobileScannerController 方法

| 名称 | 功能说明 | 类型 | 输入参数 | 输出 | ohos 支持 |
|------|----------|------|----------|------|-----------|
| start | 开始扫码服务 | function | {CameraFacing? cameraDirection} | Future\<void\> | yes |
| stop | 停止扫码服务 | function | / | Future\<void\> | yes |
| toggleTorch | 开启或关闭闪光灯 | function | / | Future\<void\> | yes |
| analyzeImage | 识别图片文件 | function | String path, {List\<BarcodeFormat\> formats = const \<BarcodeFormat\>[]} | Future\<BarcodeCapture?\> | yes |
| setZoomScale | 设置相机变焦比（OHOS 范围 0.0-10.0） | function | double zoomScale | Future\<void\> | yes |
| resetZoomScale | 重置相机变焦比为 1 | function | / | Future\<void\> | yes |
| updateScanWindow | 更新扫码框大小 | function | Rect? window | Future\<void\> | yes |
| switchCamera | 切换摄像头 | function | / | Future\<void\> | yes |
| dispose | 释放控制器资源 | function | / | Future\<void\> | yes |
| barcodes | 扫码结果事件流 | Stream | / | Stream\<BarcodeCapture?\> | yes |

### 3.2 MobileScanner 组件

| 名称 | 功能说明 | 类型 | 输入参数 | ohos 支持 |
|------|----------|------|----------|-----------|
| MobileScanner | 核心扫码界面 Widget | Widget | controller, onDetect, onDetectError, errorBuilder, placeholderBuilder, overlayBuilder, fit, scanWindow, scanWindowUpdateThreshold | yes |

### 3.3 BarcodeCapture 结果类型

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| BarcodeCapture | 扫码结果对象，包含条码列表和可选图像 | class | yes |
| BarcodeCapture.barcodes | 检测到的条码列表 | List\<Barcode\> | yes |
| BarcodeCapture.image | 扫码时的图像缓冲区（需开启 returnImage） | Uint8List? | yes |
| BarcodeCapture.raw | 扫码原始数据（包含输入图像和尺寸） | Object? | yes |
| BarcodeCapture.size | 相机输入图像尺寸 | Size | yes |

### 3.4 Barcode 条码数据

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| Barcode | 单个条码数据 | class | yes |
| Barcode.rawValue | 条码原始 UTF-8 编码值 | String? | yes |
| Barcode.displayValue | 条码用户友好格式的值 | String? | yes |
| Barcode.format | 条码格式（如 QRCode、EAN13 等） | BarcodeFormat | yes |
| Barcode.type | 条码上下文类型（如 TEXT、URL、PRODUCT 等） | BarcodeType | yes |
| Barcode.corners | 条码四个角点坐标（顺时针，左上角起始） | List\<Offset\> | yes |
| Barcode.size | 条码边界框归一化尺寸 | Size | yes |
| Barcode.rawBytes | 条码原始字节数据 | Uint8List? | no |

## 4. 属性

> [!TIP] "ohos 支持" 列为 **yes** 表示 ohos 平台支持该属性；**no** 则表示不支持；**partially** 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android。

### 4.1 MobileScannerController 属性

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| facing | 选择使用前置或后置摄像头 | CameraFacing | no |
| torchEnabled | 初始化时开启闪光灯 | bool | yes |
| returnImage | 扫码成功时返回图像缓冲区 | bool | yes |
| formats | 指定检测的码制式列表（空列表表示检测所有格式） | List\<BarcodeFormat\> | yes |
| detectionTimeoutMs | 扫码超时时间（毫秒） | int | no |
| autoStart | 初始化时自动启动扫码服务 | bool | yes |
| cameraResolution | 相机分辨率 | Size | no |
| useNewCameraSelector | 使用新的分辨率选择器 | bool | no |
| detectionSpeed | 扫码检测速度 | DetectionSpeed | no |

### 4.2 Parameters 参数

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| window | 扫码框大小 | Rect? | yes |
| zoomScale | OHOS 平台相机变焦比必须在 0.0 和 10.0 之间，其中 1.0 为默认缩放，0.0 为最小，10.0 为最大 | double? | yes |
| path | 图片文件路径 | String? | yes |

### 4.3 StartOptions 启动选项

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| cameraDirection | 摄像头方向 | CameraFacing | yes |
| cameraResolution | 期望的相机分辨率 | Size? | no |
| detectionSpeed | 检测速度 | DetectionSpeed | no |
| detectionTimeoutMs | 检测超时（毫秒） | int | no |
| formats | 要检测的码制式列表 | List\<BarcodeFormat\> | yes |
| returnImage | 是否返回图像数据 | bool | yes |
| torchEnabled | 启动时是否开启闪光灯 | bool | yes |
| useNewCameraSelector | 是否使用新分辨率选择器（仅 Android） | bool | yes |

## 5. 类型与状态

### 5.1 MobileScannerState 控制器状态

`MobileScannerController` 通过 `value` 属性暴露当前状态。状态对象包含以下字段：

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| availableCameras | 可用摄像头数量（未知时为 null） | int? | yes |
| cameraDirection | 当前摄像头方向 | CameraFacing | yes |
| isInitialized | 扫码器是否已成功初始化 | bool | yes |
| isRunning | 扫码器是否正在运行 | bool | yes |
| size | 相机输出尺寸 | Size | yes |
| torchState | 闪光灯当前状态 | TorchState | yes |
| zoomScale | 当前变焦比 | double | yes |
| error | 发生的异常（无异常时为 null） | MobileScannerException? | yes |
| hasCameraPermission | 相机权限是否已授予（计算属性） | bool | yes |

**使用示例：**

```dart
// 监听控制器状态变化
controller.addListener(() {
  final state = controller.value;
  print('已初始化: ${state.isInitialized}');
  print('正在运行: ${state.isRunning}');
  print('闪光灯状态: ${state.torchState}');
  print('变焦比: ${state.zoomScale}');
  print('摄像头方向: ${state.cameraDirection}');
  print('可用摄像头数: ${state.availableCameras}');
  print('相机尺寸: ${state.size}');
  print('有相机权限: ${state.hasCameraPermission}');
  if (state.error != null) {
    print('错误: ${state.error!.errorCode}');
  }
});
```

## 6. 异常处理

### 6.1 MobileScannerException

扫码控制器在发生错误时抛出 `MobileScannerException`，可通过 `controller.value.error` 获取当前错误状态，或通过 `MobileScanner` 的 `onDetectError` 回调接收错误通知。

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| MobileScannerException | 扫码控制器异常 | class | yes |
| errorCode | 错误码 | MobileScannerErrorCode | yes |
| errorDetails | 错误详细信息 | MobileScannerErrorDetails? | yes |

### 6.2 MobileScannerErrorDetails

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| MobileScannerErrorDetails | 错误详情 | class | yes |
| code | 来自 PlatformException 的错误码 | String? | yes |
| details | 来自 PlatformException 的详细信息 | Object? | yes |
| message | 来自 PlatformException 的错误消息 | String? | yes |

### 6.3 MobileScannerBarcodeException

| 名称 | 功能说明 | 类型 | ohos 支持 |
|------|----------|------|-----------|
| MobileScannerBarcodeException | 条码扫描过程中发生的异常 | class | yes |
| message | 错误消息 | String? | yes |

**错误处理示例：**

```dart
// 通过 onDetectError 回调处理错误
MobileScanner(
  controller: controller,
  onDetect: (capture) { /* 处理扫码结果 */ },
  onDetectError: (error, details) {
    // OHOS: 处理扫码错误
    if (error == MobileScannerErrorCode.permissionDenied) {
      print('相机权限被拒绝');
    } else {
      print('扫码错误: ${details?.message}');
    }
  },
);

// 或通过控制器状态监听错误
controller.addListener(() {
  final error = controller.value.error;
  if (error != null) {
    // OHOS: 根据错误码处理不同异常
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        // 处理权限拒绝
        break;
      case MobileScannerErrorCode.genericError:
        // 处理通用错误（包含条码识别错误）
        break;
      case MobileScannerErrorCode.unsupported:
        // 处理设备不支持
        break;
    }
  }
});
```

## 7. 代码示例

### 7.1 基础扫码示例

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  // OHOS: 创建控制器，autoStart 设为 true 自动启动扫码
  MobileScannerController controller = MobileScannerController(
    autoStart: true,
    returnImage: false,
    formats: const [], // 空列表表示检测所有码制式
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫码器')),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          // OHOS: 遍历扫码结果
          for (final barcode in capture.barcodes) {
            print('条码值: ${barcode.rawValue}');
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // OHOS: 释放控制器资源，防止内存泄漏
    controller.dispose();
    super.dispose();
  }
}
```

### 7.2 闪光灯控制示例

```dart
// OHOS: 切换闪光灯开关
await controller.toggleTorch();

// OHOS: 通过事件流监听扫码结果
controller.barcodes.listen((BarcodeCapture capture) {
  for (final barcode in capture.barcodes) {
    print('识别结果: ${barcode.rawValue}');
  }
});
```

### 7.3 图片分析示例

```dart
// OHOS: 分析图片文件中的条码
final BarcodeCapture? result = await controller.analyzeImage(
  '/path/to/image.jpg',
  formats: [BarcodeFormat.qrCode], // 仅检测 QR 码
);

if (result != null) {
  // OHOS: 遍历识别结果
  for (final barcode in result.barcodes) {
    print('识别结果: ${barcode.rawValue}');
    print('码制式: ${barcode.format}');
  }
}
```

### 7.4 扫码窗口与变焦控制示例

```dart
// OHOS: 设置扫码框为屏幕中央区域
final screenSize = MediaQuery.of(context).size;
final scanWindow = Rect.fromCenter(
  center: Offset(screenSize.width / 2, screenSize.height / 2),
  width: screenSize.width * 0.8,
  height: screenSize.width * 0.8,
);
await controller.updateScanWindow(scanWindow);

// OHOS: 设置变焦比（OHOS 支持范围 0.0-10.0）
await controller.setZoomScale(2.0); // 2 倍变焦

// OHOS: 重置变焦比到 1.0
await controller.resetZoomScale();
```

## 8. 遗留问题

- [ ] 自定义二维码扫描无法切换到前置摄像头: [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)
- [ ] OHOS 平台不支持检测速度/超时配置（ScanKit 限制）
- [ ] OHOS 平台不支持结构化条码内容解析（ScanKit 仅返回原始值）
- [ ] OHOS 平台不支持 `rawBytes` 字段

## 9. 开源协议

本项目基于 [BSD 3-Clause License](/LICENSE)，请自由地享受和参与开源。