> 模板版本: v0.0.1

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

本项目基于 [mobile_scanner](https://pub.dev/packages/mobile_scanner) 开发。

## 简介

`mobile_scanner` 是一个通用的 Flutter 条形码和二维码扫描库，在 OHOS 平台基于 ScanKit 实现条码识别。支持实时相机扫描和图片分析，提供完整的扫描控制器、扫描窗口定制、手电筒控制、缩放控制等功能。

## 1. 安装与使用

### 1.1 安装方式

进入项目目录，在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml

dependencies:
  fluttertpc_mobile_scanner:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
      # ref: 根据下方表格选择不同框架适配的TAG版本
      ref: TAG  # Select a TAG from the TAG version mapping table below
      #path: ohos 如果是 3.7 的框架版本，需要注意添加path
```

> TAG 命名规则：`原库版本-ohos-版本号-betax`，不同 TAG 之间的变更详见 CHANGELOG.OpenHarmony.md。实际使用时请将依赖示例中的 `TAG` 替换为下表选择的 TAG。

| Flutter 框架版本 | TAG 名称 | 分支名 |	 
 |---|---|---|	 
| 3.7 | 3.5.6-ohos-1.0.0-beta.1 | master |	 
| 3.22 | 6.0.2-ohos-1.0.0-beta.2 | br_v6.0.2_ohos |	 
| 3.27 | 6.0.10-ohos-1.0.0-beta.2 | br_v6.0.10_ohos |
| 3.35 | 7.1.4-ohos-1.0.1         | br_v7.1.4_ohos |

> Flutter 3.7 分支基于 API 9，不支持前置摄像头切换；Flutter 3.22/3.27/3.35 分支基于 API 12/21，功能更完整。从 3.7 迁移到高版本时，请注意 Flutter 框架的 breaking changes（详见 [Flutter 官方迁移指南](https://docs.flutter.dev/release/breaking-changes)）以及 SDK 配套升级。

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

#### 基本用法

```dart
import 'package:fluttertpc_mobile_scanner/mobile_scanner.dart';

// 创建控制器
final MobileScannerController controller = MobileScannerController();

// 在 Widget 树中使用 MobileScanner
MobileScanner(
  controller: controller,
  onDetect: (BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      // OHOS: barcode.calendarEvent、contactInfo 等结构化字段不支持，请使用 rawValue
      print('识别到条码: ${barcode.rawValue}');
    }
  },
)

// 使用完毕后释放控制器
controller.dispose();
```

> **OHOS 提示**：在 OHOS 平台上，`Barcode` 对象的结构化内容字段（如 `calendarEvent`、`contactInfo`、`email`、`phone` 等）始终为 `null`。建议统一使用 `rawValue` 获取条码内容。详见 [2.2.1 条形码内容字段不支持](#221-条形码内容字段不支持)。

#### 图片分析（analyzeImage）

从图片中识别条形码：

```dart
import 'package:fluttertpc_mobile_scanner/mobile_scanner.dart';

// OHOS 支持：返回 BarcodeCapture，但 Barcode 对象仅包含 scanType 和 originalValue
final BarcodeCapture? result = await controller.analyzeImage(
  '/path/to/image.jpg', // 请替换为实际图片路径，如使用 image_picker 获取
  formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128],
);

if (result != null) {
  for (final barcode in result.barcodes) {
    // OHOS: 使用 rawValue 获取识别内容
    print('识别结果: ${barcode.rawValue}');
  }
}
```

> **注意**：请将示例中的 `/path/to/image.jpg` 替换为设备上的实际图片路径，建议结合 [image_picker](https://pub.dev/packages/image_picker) 插件获取图片。

#### 手电筒控制（toggleTorch）

```dart
// 开启闪光灯
await controller.toggleTorch();
print('手电筒状态: ${controller.value.torchState}');
// TorchState.on 表示开启，TorchState.off 表示关闭

// 再次调用关闭闪光灯
await controller.toggleTorch();
```

> **OHOS 提示**：toggleTorch 在 OHOS 平台功能完整，行为与 Android/iOS 一致。

#### 缩放控制（setZoomScale / resetZoomScale）

```dart
// 设置缩放比（0.0 ~ 1.0，1.0 为最大缩放）
await controller.setZoomScale(0.5);

// 重置为初始缩放比
await controller.resetZoomScale();
```

> **OHOS 提示**：缩放功能在 OHOS 平台功能完整，行为与 Android/iOS 一致。

#### 切换摄像头（switchCamera）

```dart
// 切换前后摄像头
await controller.switchCamera();
```

> **OHOS 提示**：switchCamera 在 OHOS 平台**不支持**切换前置/后置摄像头（`facing` 参数无效）。调用此方法不会报错，但不会产生实际效果（摄像头保持不变）。详见 [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)。

#### 生命周期管理

```dart
// OHOS 提示：OHOS 上 pause 实际执行 stop+release，恢复需完整重启
// 建议在应用生命周期变化时使用 stop()/start() 代替 pause()
// 仅当确实需要释放相机资源时才调用 pause()

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (!controller.value.hasCameraPermission) return;

  switch (state) {
    case AppLifecycleState.resumed:
      // 恢复扫描
      controller.start();
      break;
    case AppLifecycleState.inactive:
      // 暂停扫描（使用 stop 而非 pause，以避免 OHOS 上的额外开销）
      controller.stop();
      break;
    default:
      break;
  }
}
```

更多详细使用案例见 [example](/example/lib/main.dart)


## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过：

| 三方库版本 | Flutter (OHOS) | SDK | DevEco Studio | ROM |
|-----------|---------------|-----|---------------|-----|
| mobile_scanner 7.1.4 | 3.35.7-ohos-0.0.1 | 6.0.1(API 21) | 6.0.1.260 | 6.0.0.120 SP6 |

**多版本兼容说明**：版本对应表（见 [1.1 安装方式](#11-安装方式)）覆盖了 Flutter 3.7（API 9）到 3.35（API 21）四个版本。低版本（3.7）不支持前置摄像头切换，部分 API 选项（如 `useNewCameraSelector`、`detectionSpeed`）在 OHOS 平台均不支持（详见 [2.2.3](#223-不支持的属性)）。高版本（3.22+）基于 API 12 及以上，SDK 和 IDE 版本更高，功能覆盖更完整。建议新项目优先选用 Flutter 3.35 最新版本。

### 2.2 OHOS 平台行为差异

> [!IMPORTANT]
> 以下为 OHOS 平台与 Android/iOS 的关键行为差异，开发时请特别留意。

#### 2.2.1 条形码内容字段不支持

OHOS 平台的 ScanKit 仅提供 `scanType`（格式）和 `originalValue`（原始值），**不支持**以下条形码内容结构化解析字段：

| 不支持字段 | 说明 | 替代方案 |
|-----------|------|---------|
| `calendarEvent` | 日历事件信息 | 使用 `rawValue` 自行解析 |
| `contactInfo` | 联系人信息 | 使用 `rawValue` 自行解析 |
| `email` | 电子邮件信息 | 使用 `rawValue` 自行解析 |
| `phone` | 电话号码信息 | 使用 `rawValue` 自行解析 |
| `sms` | 短信信息 | 使用 `rawValue` 自行解析 |
| `geoPoint` | 地理位置信息 | 使用 `rawValue` 自行解析 |
| `url` / `urlBookmark` | URL 书签信息 | 使用 `rawValue` 自行解析 |
| `wifi` | Wi-Fi 配置信息 | 使用 `rawValue` 自行解析 |
| `driverLicense` | 驾驶证信息 | 使用 `rawValue` 自行解析 |
| `displayValue` | 格式化显示值 | 使用 `rawValue` 替代 |
| `rawBytes` | 原始字节数据 | 部分支持，以实际返回为准 |
| `address` | 地址信息（含街道、城市、邮编等） | 使用 `rawValue` 自行解析 |
| `personName` | 人名信息（含姓、名、前后缀等） | 使用 `rawValue` 自行解析 |

> 在 OHOS 平台上，`Barcode` 对象的 `rawValue` 字段可用，但结构化内容字段（如 `calendarEvent`、`contactInfo` 等）始终为 `null`。建议统一使用 `rawValue` 获取条码内容。

#### 2.2.2 pause 方法行为差异

在 OHOS 平台上，`MobileScannerController.pause()` 实际执行 **stop + release** 操作，与 Android/iOS 的"暂停并保留相机状态"行为不同：

| 平台 | pause 行为 | 恢复方式 |
|------|-----------|---------|
| Android | `unbindAll()` 保留 surfaceProducer | 调用 `start()` 快速恢复 |
| iOS | `captureSession.stopRunning()` | 调用 `start()` 快速恢复 |
| OHOS | `customScan.stop() + release()`，释放相机资源 | 需完整重启（`stop()` → `start()`） |

> **影响**：OHOS 上频繁调用 `pause()`/`start()` 会有明显的性能开销，建议仅在确实需要释放相机资源时调用 `pause()`，平时使用 `stop()`/`start()` 控制扫描启停。

#### 2.2.3 不支持的属性

以下属性在 OHOS 平台**不支持**（设置无效）：

| 属性 | 所属类 | 说明 |
|------|--------|------|
| `facing` | MobileScannerController | 无法切换前置/后置摄像头（见 [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)） |
| `detectionSpeed` | MobileScannerController | 不支持检测速度调节 |
| `detectionTimeoutMs` | MobileScannerController | 不支持检测超时设置 |
| `useNewCameraSelector` | MobileScannerController | 不支持新的分辨率选择器 |

#### 2.2.4 部分支持的属性

以下属性在 OHOS 平台**部分支持**：

| 属性 | 支持情况 | 差异说明 |
|------|---------|---------|
| `analyzeImage` | ✅ 支持 | 返回结果仅包含 `scanType` 和 `originalValue`，无结构化内容字段 |
| `returnImage` | ✅ 支持 | 行为与 Android/iOS 一致 |
| `autoZoom` | ✅ 支持 | 行为与 Android 一致 |
| `invertImage` | ✅ 支持 | 行为与 Android 一致 |
| `cameraResolution` | ✅ 支持 | 分辨率选择逻辑与 Android 略有差异，但功能正常 |

### 2.3 权限要求

####  2.3.1 在 entry 目录下的 module.json5 中添加权限

打开 `entry/src/main/module.json5`，添加：

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

#### 2.3.2 在 entry 目录下添加申请以上权限的原因

打开 `entry/src/main/resources/base/element/string.json`，添加：

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

### 2.4 OHOS 开发环境配置

#### 2.4.1 DevEco Studio 安装

1. 从 [DevEco Studio 官网] 下载对应版本的 DevEco Studio（版本要求见 [1.1 版本对应表](#11-安装方式)）
2. 安装并启动 DevEco Studio
3. 在欢迎页选择 **Customize** → **All settings** → **SDK Manager**，配置 OHOS SDK
   - SDK 下载路径：SDK Manager 中选择 **OpenHarmony SDK** 标签页，勾选所需 API 版本（如 API 21 对应 SDK 6.0.1），点击 **Apply** 下载安装
4. 确保 SDK 版本与版本对应表要求一致（如 API 21 对应 SDK 6.0.1）

#### 2.4.2 项目编译构建

**方式一：通过 DevEco Studio 构建**

1. 打开项目中的 `example/ohos/` 目录（或集成方项目的 `ohos/` 目录）
2. DevEco Studio 会自动检测并同步 Gradle 依赖
3. 连接 OHOS 设备或启动模拟器
4. 点击 **Run** 按钮运行项目

**方式二：通过命令行构建**

```bash
# 进入 ohos 模块目录
cd example/ohos

# 使用 hvigor 构建（需配置 hvigor 环境）
# hvigor 环境变量配置：在 DevEco Studio 安装目录中找到 hvigor 路径
hvigorw assembleHap --mode module -p module=entry@default -p product=default

# 构建产物位于 entry/build/default/outputs/default/
```

> **注意**：
> - 命令行构建前需确保已配置 hvigor 环境变量，并完成 SDK 的安装和配置（见 [2.4.1 DevEco Studio 安装](#241-deveco-studio-安装)）
> - Flutter OHOS 版本环境：确保 Flutter SDK 已安装 ohos 平台支持，可通过 `flutter doctor` 验证

## 3. API

> [!TIP] "ohos 支持"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

### MobileScanner Widget

| 参数名 | 描述 | 类型 | ohos 支持 |
|--------|------|------|-------------|
| controller | 相机预览的控制器 | MobileScannerController? | yes |
| onDetect | 检测到新条形码时的回调函数 | void Function(BarcodeCapture)? | yes |
| onDetectError | onDetect 的错误处理函数 | void Function(Object, StackTrace) | yes |
| errorBuilder | 相机预览错误时的自定义 Widget 构建器 | Widget Function(BuildContext, MobileScannerException)? | yes |
| fit | 相机预览的 BoxFit 模式，默认 cover | BoxFit | yes |
| overlayBuilder | 相机预览上方的叠加层构建器 | LayoutWidgetBuilder? | yes |
| placeholderBuilder | 相机预览初始化时的占位 Widget 构建器 | WidgetBuilder? | yes |
| scanWindow | 扫码窗口矩形区域（仅扫描此区域内的条形码） | Rect? | yes |
| scanWindowUpdateThreshold | 扫码窗口更新的阈值，默认 0.0 | double | yes |
| useAppLifecycleState | 是否根据应用生命周期自动暂停/恢复，默认 true | bool | yes |
| tapToFocus | 是否启用点击聚焦功能，默认 false | bool | yes |

### MobileScannerController 方法

| 方法名 | 功能描述 | 类型 | 输入 | 输出 | ohos 支持 |
|--------|---------|------|------|------|-------------|
| start | 开始扫码服务 | function | {CameraFacing? cameraDirection} | Future<void> | yes |
| toggleTorch | 开启或者关闭相机闪光灯 | function | / | Future<void> | yes |
| stop | 停止扫码服务 | function | / | Future<void> | yes |
| pause | 暂停相机，释放资源（⚠️ OHOS 行为差异：实际执行 stop+release，见 [2.2.2](#222-pause-方法行为差异)） | function | / | Future<void> | yes |
| dispose | 释放控制器所有资源 | function | / | Future<void> | yes |
| analyzeImage | 识别本地的图像文件（⚠️ OHOS 返回结果仅含 scanType 和 originalValue，无结构化内容字段） | function | String path, {List<BarcodeFormat> formats = const <BarcodeFormat>[]} | Future<BarcodeCapture?> | yes |
| setZoomScale | 设置相机变焦比 | function | double zoomScale | Future<void> | yes |
| resetZoomScale | 重置相机变焦比为初始值 | function | / | Future<void> | yes |
| updateScanWindow | 更新扫码框大小 | function | Rect? window | Future<void> | yes |
| switchCamera | 切换摄像头 | function | / | Future<void> | yes |
| setFocusPoint | 设置相机焦点 | function | Offset position | Future<void> | yes |
| barcodes | 条码捕获结果流 | stream | / | Stream<BarcodeCapture> | yes |
| buildCameraView | 构建相机预览 Widget | function | / | Widget | yes |

### 其余核心类

| 类名 | 属性 | 类型 | 功能描述 | ohos 支持 |
|------|------|------|---------|----------|
| BarcodeCapture | barcodes | List\<Barcode\> | 扫描到的条形码列表 | yes |
| | image | Uint8List? | 输入图像字节（仅在 returnImage=true 时可用） | yes |
| | raw | Object? | 扫描的原始数据 | yes |
| | size | Size | 相机输入图像的原始尺寸 | yes |
| MobileScannerState | availableCameras | int? | 可用相机数量 | yes |
| | cameraDirection | CameraFacing | 相机方向（OHOS 无效，见 [2.2.3](#223-不支持的属性)） | no |
| | error | MobileScannerException? | 相机设置或使用过程中的错误 | yes |
| | isInitialized | bool | 扫描器是否已初始化 | yes |
| | isStarting | bool | 扫描器是否正在启动中 | yes |
| | isRunning | bool | 扫描器是否正在运行 | yes |
| | size | Size | 相机输出尺寸 | yes |
| | torchState | TorchState | 闪光灯当前状态 | yes |
| | zoomScale | double | 当前缩放比 | yes |
| | deviceOrientation | DeviceOrientation | 当前设备 UI 方向 | yes |
| | hasCameraPermission | bool | 是否已获得相机权限（只读 getter） | yes |
| MobileScannerException | errorCode | MobileScannerErrorCode | 异常错误码 | yes |
| | errorDetails | MobileScannerErrorDetails? | 附加错误详情 | yes |
| MobileScannerErrorDetails | code | String? | PlatformException 错误码 | yes |
| | details | Object? | PlatformException 详情 | yes |
| | message | String? | PlatformException 错误消息 | yes |
| MobileScannerBarcodeException | message | String? | 异常的错误消息 | yes |
| MobileScannerPlatform | start | (StartOptions) → Future\<MobileScannerViewAttributes\> | 启动扫描器并准备视图（抽象平台接口，不直接调用） | yes |
| | stop | () → Future\<void\> | 停止相机 | yes |
| | pause | () → Future\<void\> | 暂停相机 | yes |
| | dispose | () → Future\<void\> | 释放平台实例 | yes |
| | toggleTorch | () → Future\<void\> | 切换闪光灯开关 | yes |
| | analyzeImage | (String, List\<BarcodeFormat\>) → Future\<BarcodeCapture?\> | 分析图片中的条形码 | yes |
| | setZoomScale | (double) → Future\<void\> | 设置缩放比 | yes |
| | resetZoomScale | () → Future\<void\> | 重置缩放比 | yes |
| | setFocusPoint | (Offset) → Future\<void\> | 设置焦点位置 | yes |
| | updateScanWindow | (Rect?) → Future\<void\> | 更新扫描窗口 | yes |
| | buildCameraView | () → Widget | 构建相机预览 Widget | yes |
| | barcodesStream | Stream\<BarcodeCapture?\> | 条形码捕获流 | yes |
| | torchStateStream | Stream\<TorchState\> | 闪光灯状态变化流 | yes |
| | zoomScaleStateStream | Stream\<double\> | 缩放比变化流 | yes |
| | instance | MobileScannerPlatform | 默认平台实例（getter/setter） | yes |
| | setBarcodeLibraryScriptUrl | (String) → void | 设置条形码库脚本 URL（仅 Web 平台） | yes |
| MobileScannerViewAttributes | cameraDirection | CameraFacing | 当前活跃相机的方向 | yes |
| | currentTorchMode | TorchState | 当前闪光灯状态 | yes |
| | numberOfCameras | int? | 可用相机数量 | yes |
| | size | Size | 相机输出尺寸 | yes |
| | initialDeviceOrientation | DeviceOrientation? | 设备初始方向 | yes |
| Barcode | format | BarcodeFormat | 条形码格式 | yes |
| | rawValue | String? | 条形码的 UTF-8 原始值 | yes |
| | rawBytes | Uint8List? | 条形码的原始字节数据 | partially |
| | corners | List\<Offset\> | 条形码的角点坐标列表 | yes |
| | size | Size | 条形码边界框的标准化尺寸 | yes |
| | type | BarcodeType | 条形码的类型 | yes |
| | displayValue | String? | 条形码的用户友好格式值（OHOS 不支持） | no |
| | calendarEvent | CalendarEvent? | 日历事件（OHOS 不支持） | no |
| | contactInfo | ContactInfo? | 联系人信息（OHOS 不支持） | no |
| | email | Email? | 邮件信息（OHOS 不支持） | no |
| | phone | Phone? | 电话号码（OHOS 不支持） | no |
| | sms | SMS? | 短信信息（OHOS 不支持） | no |
| | geoPoint | GeoPoint? | 地理坐标（OHOS 不支持） | no |
| | url | UrlBookmark? | URL 书签（OHOS 不支持） | no |
| | wifi | WiFi? | 无线网络信息（OHOS 不支持） | no |
| | driverLicense | DriverLicense? | 驾驶证信息（OHOS 不支持） | no |
| | address | Address? | 地址信息（OHOS 不支持） | no |
| | personName | PersonName? | 人名信息（OHOS 不支持） | no |
| | scaleCorners | (Size) → List\<Offset\> | 将角点缩放到目标尺寸 | yes |
| | fromNative | (Map) → Barcode | 从原生数据创建 Barcode 实例 | yes |
| StartOptions | cameraDirection | CameraFacing | 相机方向（OHOS 无效） | no |
| | cameraResolution | Size? | 相机期望分辨率 | yes |
| | detectionSpeed | DetectionSpeed | 检测速度（OHOS 不支持，见 [2.2.3](#223-不支持的属性)） | no |
| | detectionTimeoutMs | int | 检测超时时间（毫秒，OHOS 不支持） | no |
| | formats | List\<BarcodeFormat\> | 要检测的条形码格式 | yes |
| | returnImage | bool | 是否返回检测到的条形码图像数据 | yes |
| | torchEnabled | bool | 启动时是否开启闪光灯 | yes |
| | invertImage | bool | 是否反转图片颜色 | yes |
| | autoZoom | bool | 是否自动变焦 | yes |
| | initialZoom | double? | 初始变焦比 | yes |
| | toMap | () → Map\<String, Object?\> | 将 StartOptions 转换为 Map 用于方法通道调用 | yes |
| BarcodeOverlay | boxFit | BoxFit | 绘制条形码框的 BoxFit 模式 | yes |
| | controller | MobileScannerController | 提供条形码数据的控制器 | yes |
| | color | Color | 绘制条形码框的颜色，默认红色 30% 透明度 | yes |
| | style | PaintingStyle | 绘制条形码框的样式，默认 fill | yes |
| BarcodePainter | barcodeCorners | List\<Offset\> | 条形码的角点坐标 | yes |
| | barcodeSize | Size | 条形码尺寸 | yes |
| | barcodeValue | String | 条形码值 | yes |
| | boxFit | BoxFit | 缩放 BoxFit 模式 | yes |
| | cameraPreviewSize | Size | 相机预览尺寸 | yes |
| | color | Color | 轮廓颜色 | yes |
| | style | PaintingStyle | 绘制样式 | yes |
| | textPainter | TextPainter | 文字绘制器 | yes |
| | deviceOrientation | DeviceOrientation | 设备方向 | yes |
| | strokeWidth | double | 边框宽度，默认 4.0 | yes |
| ScanWindowOverlay | controller | MobileScannerController | 管理相机预览的控制器 | yes |
| | scanWindow | Rect | 扫描窗口矩形 | yes |
| | borderColor | Color | 扫描窗口边框颜色，默认白色 | yes |
| | borderRadius | BorderRadius | 扫描窗口边框圆角，默认零 | yes |
| | borderStrokeCap | StrokeCap | 边框笔端样式，默认 butt | yes |
| | borderStrokeJoin | StrokeJoin | 边框连接样式，默认 miter | yes |
| | borderStyle | PaintingStyle | 边框绘制样式，默认 stroke | yes |
| | borderWidth | double | 扫描窗口边框宽度 | yes |
| | color | Color | 扫描窗口镂空外的覆盖颜色 | yes |
| ScanWindowPainter | borderColor | Color | 边框颜色 | yes |
| | borderRadius | BorderRadius | 边框圆角 | yes |
| | borderStrokeCap | StrokeCap | 边框笔端样式 | yes |
| | borderStrokeJoin | StrokeJoin | 边框连接样式 | yes |
| | borderStyle | PaintingStyle | 边框绘制样式 | yes |
| | borderWidth | double | 边框宽度 | yes |
| | color | Color | 遮罩颜色 | yes |
| | scanWindow | Rect | 扫描窗口矩形 | yes |

> 以上类中，除特别标注 "OHOS 不支持" 的字段外，均为 OHOS 平台通用支持。Address、PersonName、CalendarEvent、ContactInfo、Email、Phone、SMS、GeoPoint、UrlBookmark、WiFi、DriverLicense 等结构化数据类在 OHOS 平台**不支持**，详见 [2.2.1 条形码内容字段不支持](#221-条形码内容字段不支持)。

### 枚举类型

| 枚举名 | 枚举值 | 功能描述 | ohos 支持 |
|--------|--------|---------|----------|
| CameraFacing | back, front, external, unknown | 相机朝向（OHOS 仅支持默认摄像头，无法切换） | yes |
| TorchState | on, off, unavailable | 闪光灯状态 | yes |
| BarcodeFormat | unknown, all, qrCode, code128, code39, code93, ean13, ean8, upcA, upcE, pdf417, aztec, dataMatrix, itf, codabar | 条形码格式 | yes |
| BarcodeType | calendarEvent, contactInfo, driverLicense, email, geo, isbn, phone, product, sms, text, url, wifi, unknown | 条形码类型（OHOS 仅识别 text/unknown） | partially |
| DetectionSpeed | noDuplicates, normal, unrestricted | 检测速度（OHOS 不支持） | no |
| AddressType | home, work, unknown | 地址类型 | yes |
| EmailType | home, work, unknown | 邮件类型 | yes |
| PhoneType | fax, home, mobile, work, unknown | 电话类型 | yes |
| EncryptionType | unknown, open, wpa, wep | 无线网络加密类型 | yes |
| MobileScannerAuthorizationState | undetermined, authorized, denied | 相机授权状态 | yes |
| MobileScannerErrorCode | controllerAlreadyInitialized, controllerDisposed, controllerUninitialized, genericError, permissionDenied, unsupported, controllerInitializing, controllerNotAttached | Dart 公共 API 枚举值 | yes |
| | (OHOS 原生映射) | cameraError → genericError, permissionError → permissionDenied, unspecified → unsupported | OHOS 原生错误码到 Dart API 的映射关系 |

### 导出的函数

| 函数名 | 签名 | 功能描述 | ohos 支持 |
|--------|------|---------|----------|
| calculateBoxFitRatio | (BoxFit, Size, Size) → {double widthRatio, double heightRatio} | 计算给定 BoxFit 模式和原始尺寸下的缩放比例，返回包含 widthRatio 和 heightRatio 的 Record | yes |


## 4. 属性

> [!TIP] "ohos 支持"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

### MobileScannerController

| 属性名 | 功能描述 | 类型 | ohos 支持 |
|--------|---------|------|-------------|
| facing               | 选择相机（OHOS 不支持，见 [2.2.3](#223-不支持的属性)）                   | CameraFacing            | no           |
| torchEnabled         | 开启或者关闭闪光灯                             | bool                    | yes          |
| returnImage          | 扫码成功时返回图像缓冲区                         | bool                    | yes          |
| formats              | 码制式格式                                    | List<BarcodeFormat>?    | yes          |
| detectionTimeoutMs   | 设置扫码超时时间，单位毫秒（OHOS 不支持，见 [2.2.3](#223-不支持的属性)）                        | int                     | no           |
| autoStart            | 初始化时自动启动扫码服务                          | bool                    | yes          |
| cameraResolution     | 相机分辨率                                    | Size                    | yes           |
| useNewCameraSelector | 使用新的分辨率选择器（OHOS 不支持，见 [2.2.3](#223-不支持的属性)）                             | bool                    | no           |
| detectionSpeed       | 设置扫码检测速度（OHOS 不支持，见 [2.2.3](#223-不支持的属性)）                                | DetectionSpeed          | no           |
| invertImage          | 处理图片颜色反转                             | bool                    | yes           |
| autoZoom             | 是否自动变焦                                   | bool                    | yes           |
| initialZoom          | 初始化相机变焦比                                | double?                 | yes           |

### 参数

| 参数名 | 功能描述 | 类型 | ohos 支持 |
|--------|---------|------|-------------|
| window    | 扫码框大小                                      | Rect?     | yes          |
| zoomScale | 相机变焦比必须在 0.0 和 1.0 之间，其中 1.0 为最大缩放，0.0 为缩小 | double?   | yes          |
| path      | 本地的图像文件路径                                  | String?   | yes          |


## 5. 遗留问题

- [ ] 自定义二维码扫描无法切换到前置摄像头: [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)

## 6. 目录结构

```
ohos/                          # OHOS 平台适配代码
├── index.ets                  # 插件导出入口
├── src/main/ets/
│   ├── MobileScannerPlugin.ets # 主编排类，管理 Flutter Engine 与 Ability 生命周期
│   ├── MethodHandlers.ets      # 方法处理器（手电筒、缩放、扫描窗口、焦点等）
│   ├── ScanCameraManager.ets   # 相机扫描管理器
│   ├── ScanResultProcessor.ets # 扫描结果处理器（过滤、去重）
│   ├── ScanImageProcessor.ets  # 图像帧处理器（PixelMap 转换）
│   ├── ScanOptionsParser.ets   # 启动参数解析器（纯函数）
│   ├── ScanDisplayConfig.ets   # 显示配置计算工具（纯函数）
│   ├── DeviceOrientationListener.ets # 设备方向监听器
│   ├── CameraUtil.ets          # 相机工具函数
│   ├── CameraPermissions.ets   # 相机权限管理
│   ├── Barcode.ets             # 条码数据模型与枚举
│   └── Types.ets               # 类型定义
example/                       # 示例应用
├── lib/                       # 示例 Dart 代码
└── ohos/                      # 示例 OHOS 工程配置
test/                          # 测试目录
```

## 7. 开源协议

本项目基于 [BSD 3-Clause License](/LICENSE)，请自由地享受和参与开源。