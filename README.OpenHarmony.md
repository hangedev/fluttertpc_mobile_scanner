> Template version: v0.0.1

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

This project is based on [mobile_scanner](https://pub.dev/packages/mobile_scanner).

## Introduction

`mobile_scanner` is a universal Flutter barcode and QR code scanner. On the OHOS platform, it uses ScanKit for barcode recognition. It supports real-time camera scanning and local image analysis, providing a full-featured scan controller, customizable scan window, torch control, zoom control, and more.

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
...

dependencies:
  fluttertpc_mobile_scanner:
    git: 
      url: https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
      # ref: Select the TAG version that matches your Flutter framework version from the table below
      ref: TAG  # Select a TAG from the TAG version mapping table below

...
```

> Tag naming: `library-version-ohos-version-betax`. For changes between tags, see [CHANGELOG.OpenHarmony.md](./CHANGELOG.OpenHarmony.md). Replace `TAG` in the dependency with the tag from the table below.

| Flutter Version | TAG                      | Branch |
|-----------------|--------------------------|--------|
| 3.7 | 3.5.6-ohos-1.0.0-beta.1  | master |
| 3.22 | 6.0.2-ohos-1.0.0-beta.2 | br_v6.0.2_ohos |	 
| 3.27 | 6.0.10-ohos-1.0.0-beta.2 | br_v6.0.10_ohos |
| 3.35 | 7.1.4-ohos-1.0.1         | br_v7.1.4_ohos |

> Flutter 3.7 branch is based on API 9 and does not support front camera switching. Flutter 3.22/3.27/3.35 branches are based on API 12/21 with more complete functionality. When migrating from 3.7 to a higher version, be aware of Flutter framework breaking changes (see [Flutter Migration Guide](https://docs.flutter.dev/release/breaking-changes)) and required SDK upgrades.

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

#### Basic usage

```dart
import 'package:fluttertpc_mobile_scanner/mobile_scanner.dart';

// Create a controller
final MobileScannerController controller = MobileScannerController();

// Use the MobileScanner widget in your widget tree
MobileScanner(
  controller: controller,
  onDetect: (BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      // OHOS: barcode.calendarEvent, contactInfo, etc. are not supported.
      // Use barcode.rawValue to get the barcode content.
      print('Barcode found: ${barcode.rawValue}');
    }
  },
)

// Remember to dispose the controller
controller.dispose();
```

> **OHOS Note**: On OHOS, the `Barcode` object's structured content fields (such as `calendarEvent`, `contactInfo`, `email`, `phone`, etc.) are always `null`. It is recommended to use `rawValue` to obtain barcode content. See [2.2.1 Barcode Content Fields Not Supported](#221-barcode-content-fields-not-supported).

#### Image Analysis (analyzeImage)

Analyze barcodes from a local image:

```dart
import 'package:fluttertpc_mobile_scanner/mobile_scanner.dart';

// OHOS: Returns BarcodeCapture, but Barcode only contains scanType and originalValue
final BarcodeCapture? result = await controller.analyzeImage(
  '/path/to/image.jpg', // Replace with actual image path, e.g. using image_picker plugin
  formats: const [BarcodeFormat.qrCode, BarcodeFormat.code128],
);

if (result != null) {
  for (final barcode in result.barcodes) {
    // OHOS: Use rawValue to get the recognized content
    print('Result: ${barcode.rawValue}');
  }
}
```

> **Note**: Replace `/path/to/image.jpg` with the actual image path on the device. It is recommended to use the [image_picker](https://pub.dev/packages/image_picker) plugin to obtain images.

#### Torch Control (toggleTorch)

```dart
// Turn on the torch
await controller.toggleTorch();
print('Torch state: ${controller.value.torchState}');
// TorchState.on means on, TorchState.off means off

// Call again to turn off
await controller.toggleTorch();
```

> **OHOS Note**: toggleTorch is fully supported on OHOS, behavior is consistent with Android/iOS.

#### Zoom Control (setZoomScale / resetZoomScale)

```dart
// Set zoom scale (0.0 ~ 1.0, 1.0 is max zoom)
await controller.setZoomScale(0.5);

// Reset to initial zoom scale
await controller.resetZoomScale();
```

> **OHOS Note**: Zoom control is fully supported on OHOS, behavior is consistent with Android/iOS.

#### Camera Switching (switchCamera)

```dart
// Switch between front and back cameras
await controller.switchCamera();
```

> **OHOS Note**: switchCamera is **not supported** on OHOS for switching front/back cameras (the `facing` parameter has no effect). Calling this method will not throw an error, but will have no actual effect (the camera remains unchanged). See [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57).

#### Lifecycle Management

```dart
// OHOS Note: On OHOS, pause() actually performs stop+release, requiring a full restart.
// Use stop()/start() instead of pause() for lifecycle control.
// Only call pause() when you actually need to release camera resources.

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (!controller.value.hasCameraPermission) return;
  
  switch (state) {
    case AppLifecycleState.resumed:
      // Resume scanning
      controller.start();
      break;
    case AppLifecycleState.inactive:
      // Pause scanning (use stop instead of pause to avoid OHOS overhead)
      controller.stop();
      break;
    default:
      break;
  }
}
```

For more detailed use cases, see the [example](/example/lib/main.dart).

### 1.3 Upgrade Migration

To upgrade from an older version to a newer version:

1. **Update the TAG reference** in `pubspec.yaml` to the target version's TAG name
2. **Update OHOS SDK and DevEco Studio** to match the target version's compatibility requirements (see table above)
3. **Cross-major-version migration** (e.g., 3.7 → 3.22/3.27/3.35):
   - Check Flutter framework breaking changes, refer to [Flutter Migration Guide](https://docs.flutter.dev/release/breaking-changes)
   - The OHOS adaptation layer (`ohos/` directory) is updated with the version — no manual changes needed
   - If API incompatibility is encountered, check `ohos/src/main/ets/` against the target SDK version
4. **Rollback**: Restore the old TAG in `pubspec.yaml` and run `flutter pub get`


## 2. Constraints

### 2.1 Compatibility

Tested on the following versions:

| Library Version | Flutter (OHOS) | SDK | DevEco Studio | ROM |
|----------------|---------------|-----|---------------|-----|
| mobile_scanner 7.1.4 | 3.35.7-ohos-0.0.1 | 6.0.1(API 21) | 6.0.1.260 | 6.0.0.120 SP6 |

**Multi-version compatibility notes**: The version compatibility table (see [1.1 Installation](#11-installation)) covers four Flutter versions from 3.7 (API 9) to 3.35 (API 21). The lower version (3.7) does not support front camera switching; certain API options (such as `useNewCameraSelector`, `detectionSpeed`) are not supported on OHOS for all versions (see [2.2.3](#223-unsupported-properties)). Higher versions (3.22+) are based on API 12 and above with more complete functionality. It is recommended to use the latest Flutter 3.35 version for new projects.

### 2.2 OHOS Platform Behavior Differences

> [!IMPORTANT]
> The following are key behavioral differences between OHOS and Android/iOS platforms. Please pay special attention during development.

#### 2.2.1 Barcode Content Fields Not Supported

OHOS ScanKit only provides `scanType` (format) and `originalValue` (raw value), and does **NOT** support the following structured barcode content fields:

| Unsupported Field | Description | Alternative |
|-------------------|-------------|-------------|
| `calendarEvent` | Calendar event information | Use `rawValue` and parse manually |
| `contactInfo` | Contact information | Use `rawValue` and parse manually |
| `email` | Email information | Use `rawValue` and parse manually |
| `phone` | Phone number information | Use `rawValue` and parse manually |
| `sms` | SMS information | Use `rawValue` and parse manually |
| `geoPoint` | Geographic location | Use `rawValue` and parse manually |
| `url` / `urlBookmark` | URL bookmark information | Use `rawValue` and parse manually |
| `wifi` | Wi-Fi configuration | Use `rawValue` and parse manually |
| `driverLicense` | Driver's license information | Use `rawValue` and parse manually |
| `displayValue` | Formatted display value | Use `rawValue` instead |
| `rawBytes` | Raw byte data | Partially supported, check actual return |
| `address` | Address information (street, city, zip, etc.) | Use `rawValue` and parse manually |
| `personName` | Person name information (first, last, prefix, suffix, etc.) | Use `rawValue` and parse manually |

> On OHOS, the `Barcode` object's `rawValue` field is available, but structured content fields (such as `calendarEvent`, `contactInfo`, etc.) are always `null`. It is recommended to use `rawValue` to obtain barcode content universally.

#### 2.2.2 pause Method Behavior Difference

On OHOS, `MobileScannerController.pause()` actually performs **stop + release**, which differs from Android/iOS behavior of "pausing while preserving camera state":

| Platform | pause Behavior | Resume Method |
|----------|---------------|---------------|
| Android | `unbindAll()` preserves surfaceProducer | Call `start()` for quick resume |
| iOS | `captureSession.stopRunning()` | Call `start()` for quick resume |
| OHOS | `customScan.stop() + release()`, releases camera resources | Requires full restart (`stop()` → `start()`) |

> **Impact**: Frequent `pause()`/`start()` calls on OHOS have significant performance overhead. It is recommended to use `stop()`/`start()` for normal scan control, and only call `pause()` when you actually need to release camera resources.

#### 2.2.3 Unsupported Properties

The following properties are **not supported** on OHOS (setting them has no effect):

| Property | Class | Description |
|----------|-------|-------------|
| `facing` | MobileScannerController | Cannot switch front/back camera (see [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)) |
| `detectionSpeed` | MobileScannerController | Detection speed adjustment not supported |
| `detectionTimeoutMs` | MobileScannerController | Detection timeout not supported |
| `useNewCameraSelector` | MobileScannerController | New resolution selector not supported |

#### 2.2.4 Partially Supported Properties

The following properties are **partially supported** on OHOS:

| Property | Support Status | Difference |
|----------|---------------|------------|
| `analyzeImage` | ✅ Supported | Returns only `scanType` and `originalValue`, no structured content fields |
| `returnImage` | ✅ Supported | Behavior consistent with Android/iOS |
| `autoZoom` | ✅ Supported | Behavior consistent with Android |
| `invertImage` | ✅ Supported | Behavior consistent with Android |
| `cameraResolution` | ✅ Supported | Resolution selection logic slightly differs from Android, but works normally |

### 2.3 Permission Requirements

#### 2.3.1 Add permissions to the module.json5 file in the entry directory.

Open  `entry/src/main/module.json5` and add the following information:

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

#### 2.3.2 Add the reason for applying for the preceding permission to the entry directory.

Open  `entry/src/main/resources/base/element/string.json` and add the following information:

```diff
...
{
  "string": [
+    {
+      "name": "camera_reason",
+      "value": "camera_reason"
+    }
  ]
}
```

### 2.4 OHOS Development Environment Setup

#### 2.4.1 DevEco Studio Installation

1. Download the appropriate version of DevEco Studio from the [DevEco Studio website] (version requirements are listed in the [version compatibility table](#11-installation))
2. Install and launch DevEco Studio
3. On the welcome page, select **Customize** → **All settings** → **SDK Manager** to configure the OHOS SDK
   - SDK download path: In SDK Manager, select the **OpenHarmony SDK** tab, check the required API version (e.g., API 21 corresponds to SDK 6.0.1), and click **Apply** to download and install
4. Ensure the SDK version matches the version compatibility table (e.g., API 21 corresponds to SDK 6.0.1)

#### 2.4.2 Building the Project

**Method 1: Build via DevEco Studio**

1. Open the `example/ohos/` directory (or the integrated project's `ohos/` directory)
2. DevEco Studio will automatically detect and sync Gradle dependencies
3. Connect an OHOS device or start an emulator
4. Click the **Run** button to start the project

**Method 2: Build via Command Line**

```bash
# Navigate to the ohos module directory
cd example/ohos

# Build using hvigor (requires hvigor environment configured)
# hvigor environment variable configuration: locate the hvigor path in the DevEco Studio installation directory,
hvigorw assembleHap --mode module -p module=entry@default -p product=default

# Build output is located at entry/build/default/outputs/default/
```

> **Note**:
> - Before building via command line, ensure the hvigor environment variables are configured and the SDK is installed and set up (see [2.4.1 DevEco Studio Installation](#241-deveco-studio-installation))
> - Flutter OHOS environment: Make sure the Flutter SDK has ohos platform support installed. Verify with `flutter doctor`
> - The first build may take longer to download dependencies


## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### MobileScanner Widget

| Parameter | Description | Type | ohos Support |
|-----------|-------------|------|-------------|
| controller | Controller for the camera preview | MobileScannerController? | yes |
| onDetect | Callback when a new barcode is detected | void Function(BarcodeCapture)? | yes |
| onDetectError | Error handler for onDetect | void Function(Object, StackTrace) | yes |
| errorBuilder | Custom widget builder when camera preview fails | Widget Function(BuildContext, MobileScannerException)? | yes |
| fit | BoxFit mode for the camera preview, default cover | BoxFit | yes |
| overlayBuilder | Overlay builder above the camera preview | LayoutWidgetBuilder? | yes |
| placeholderBuilder | Placeholder widget builder during camera initialization | WidgetBuilder? | yes |
| scanWindow | Scan window rectangle (only scans barcodes within this area) | Rect? | yes |
| scanWindowUpdateThreshold | Threshold for scan window updates, default 0.0 | double | yes |
| useAppLifecycleState | Whether to auto pause/resume based on app lifecycle, default true | bool | yes |
| tapToFocus | Whether to enable tap-to-focus, default false | bool | yes |

### MobileScannerController Methods

| Method Name | Description | Type | Input | Output | ohos Support |
|--------------------|--------------------------------------------------------------------------------------------------------------|----------|----------------------------------------------------------------------|-------------------------|--------------|
| start              | Start scanning for barcodes                                                                                  | function | {CameraFacing? cameraDirection}                                      | Future<void>            | yes          |
| toggleTorch        | Switches the torch on or off                                                                                 | function | /                                                                    | Future<void>            | yes          |
| stop               | Stops the camera, but does not dispose this controller                                                       | function | /                                                                    | Future<void>            | yes          |
| pause              | Pauses the camera, releasing resources (⚠️ OHOS: actually performs stop+release, see [2.2.2](#222-pause-method-behavior-difference)) | function | /                                                                    | Future<void>            | yes          |
| dispose            | Disposes of the controller and releases all resources                                                       | function | /                                                                    | Future<void>            | yes          |
| analyzeImage       | Handles a local image file, returns true if a barcode or QR code is found (⚠️ OHOS: returns only scanType and originalValue, no structured content fields) | function | String path, {List<BarcodeFormat> formats = const <BarcodeFormat>[]} | Future<BarcodeCapture?> | yes          |
| setZoomScale       | Set the zoomScale of the camera                                                                              | function | double zoomScale                                                     | Future<void>            | yes          |
| resetZoomScale     | Reset the zoomScale of the camera to use standard scale initialZoom                                          | function | /                                                                    | Future<void>            | yes          |
| updateScanWindow   | updates the native ScanWindow                                                                                | function | Rect? window                                                         | Future<void>            | yes          |
| switchCamera       | Changes the state of the camera (front or back)                                                              | function | /                                                                    | Future<void>            | yes          |
| setFocusPoint       | Set the focus point of the camera                                                                          | function | Offset position                                                    | Future<void>            | yes          |
| barcodes            | Stream of barcode capture results                                                                            | stream   | /                                                                    | Stream<BarcodeCapture>  | yes          |
| buildCameraView     | Builds the camera preview widget                                                                            | function | /                                                                    | Widget                  | yes          |

### Other Core Classes

| Class | Property | Type | Description | ohos Support |
|-------|----------|------|-------------|--------------|
| BarcodeCapture | barcodes | List\<Barcode\> | List of barcodes captured | yes |
| | image | Uint8List? | Input image bytes (only available when returnImage=true) | yes |
| | raw | Object? | Raw scan data | yes |
| | size | Size | Original size of the camera input image | yes |
| MobileScannerState | availableCameras | int? | Number of available cameras | yes |
| | cameraDirection | CameraFacing | Camera direction (OHOS: not supported, see [2.2.3](#223-unsupported-properties)) | no |
| | error | MobileScannerException? | Error during camera setup or use | yes |
| | isInitialized | bool | Whether the scanner is initialized | yes |
| | isStarting | bool | Whether the scanner is starting | yes |
| | isRunning | bool | Whether the scanner is running | yes |
| | size | Size | Camera output size | yes |
| | torchState | TorchState | Current torch state | yes |
| | zoomScale | double | Current zoom scale | yes |
| | deviceOrientation | DeviceOrientation | Current device UI orientation | yes |
| | hasCameraPermission | bool | Whether camera permission is granted (read-only getter) | yes |
| MobileScannerException | errorCode | MobileScannerErrorCode | Error code | yes |
| | errorDetails | MobileScannerErrorDetails? | Additional error details | yes |
| MobileScannerErrorDetails | code | String? | PlatformException error code | yes |
| | details | Object? | PlatformException details | yes |
| | message | String? | PlatformException error message | yes |
| MobileScannerBarcodeException | message | String? | Exception error message | yes |
| MobileScannerPlatform | start | (StartOptions) → Future\<MobileScannerViewAttributes\> | Start scanner and prepare view (abstract platform interface, not called directly) | yes |
| | stop | () → Future\<void\> | Stop camera | yes |
| | pause | () → Future\<void\> | Pause camera | yes |
| | dispose | () → Future\<void\> | Dispose platform instance | yes |
| | toggleTorch | () → Future\<void\> | Toggle torch | yes |
| | analyzeImage | (String, List\<BarcodeFormat\>) → Future\<BarcodeCapture?\> | Analyze local image for barcodes | yes |
| | setZoomScale | (double) → Future\<void\> | Set zoom scale | yes |
| | resetZoomScale | () → Future\<void\> | Reset zoom scale | yes |
| | setFocusPoint | (Offset) → Future\<void\> | Set focus point | yes |
| | updateScanWindow | (Rect?) → Future\<void\> | Update scan window | yes |
| | buildCameraView | () → Widget | Build camera preview Widget | yes |
| | barcodesStream | Stream\<BarcodeCapture?\> | Barcode capture stream | yes |
| | torchStateStream | Stream\<TorchState\> | Torch state change stream | yes |
| | zoomScaleStateStream | Stream\<double\> | Zoom scale change stream | yes |
| | instance | MobileScannerPlatform | Default platform instance (getter/setter) | yes |
| | setBarcodeLibraryScriptUrl | (String) → void | Set barcode library script URL (Web only) | yes |
| MobileScannerViewAttributes | cameraDirection | CameraFacing | Current active camera direction | yes |
| | currentTorchMode | TorchState | Current torch mode | yes |
| | numberOfCameras | int? | Number of available cameras | yes |
| | size | Size | Camera output size | yes |
| | initialDeviceOrientation | DeviceOrientation? | Initial device orientation | yes |
| Barcode | format | BarcodeFormat | Barcode format | yes |
| | rawValue | String? | Raw UTF-8 value of the barcode | yes |
| | rawBytes | Uint8List? | Raw byte data of the barcode | partially |
| | corners | List\<Offset\> | Corner points of the barcode | yes |
| | size | Size | Normalized size of the barcode bounding box | yes |
| | type | BarcodeType | Type of the barcode | yes |
| | displayValue | String? | User-friendly formatted value (OHOS: not supported) | no |
| | calendarEvent | CalendarEvent? | Calendar event (OHOS: not supported) | no |
| | contactInfo | ContactInfo? | Contact info (OHOS: not supported) | no |
| | email | Email? | Email info (OHOS: not supported) | no |
| | phone | Phone? | Phone number (OHOS: not supported) | no |
| | sms | SMS? | SMS info (OHOS: not supported) | no |
| | geoPoint | GeoPoint? | Geographic coordinates (OHOS: not supported) | no |
| | url | UrlBookmark? | URL bookmark (OHOS: not supported) | no |
| | wifi | WiFi? | Wi-Fi info (OHOS: not supported) | no |
| | driverLicense | DriverLicense? | Driver's license info (OHOS: not supported) | no |
| | address | Address? | Address info (OHOS: not supported) | no |
| | personName | PersonName? | Person name info (OHOS: not supported) | no |
| | scaleCorners | (Size) → List\<Offset\> | Scale corner points to target size | yes |
| | fromNative | (Map) → Barcode | Create Barcode from native data | yes |
| StartOptions | cameraDirection | CameraFacing | Camera direction (OHOS: not supported) | no |
| | cameraResolution | Size? | Desired camera resolution | yes |
| | detectionSpeed | DetectionSpeed | Detection speed (OHOS: not supported, see [2.2.3](#223-unsupported-properties)) | no |
| | detectionTimeoutMs | int | Detection timeout (ms, OHOS: not supported) | no |
| | formats | List\<BarcodeFormat\> | Barcode formats to detect | yes |
| | returnImage | bool | Whether to return detected barcode image data | yes |
| | torchEnabled | bool | Whether to enable torch on start | yes |
| | invertImage | bool | Whether to invert image colors | yes |
| | autoZoom | bool | Whether to enable auto zoom | yes |
| | initialZoom | double? | Initial zoom scale | yes |
| | toMap | () → Map\<String, Object?\> | Converts StartOptions to a Map for method channel invocation | yes |
| BarcodeOverlay | boxFit | BoxFit | BoxFit mode for drawing barcode bounding box | yes |
| | controller | MobileScannerController | Controller providing barcode data | yes |
| | color | Color | Barcode box drawing color, default red at 30% opacity | yes |
| | style | PaintingStyle | Barcode box drawing style, default fill | yes |
| BarcodePainter | barcodeCorners | List\<Offset\> | Barcode corner points | yes |
| | barcodeSize | Size | Barcode size | yes |
| | barcodeValue | String | Barcode value | yes |
| | boxFit | BoxFit | BoxFit mode for scaling | yes |
| | cameraPreviewSize | Size | Camera preview size | yes |
| | color | Color | Outline color | yes |
| | style | PaintingStyle | Drawing style | yes |
| | textPainter | TextPainter | Text painter | yes |
| | deviceOrientation | DeviceOrientation | Device orientation | yes |
| | strokeWidth | double | Stroke width, default 4.0 | yes |
| ScanWindowOverlay | controller | MobileScannerController | Controller managing camera preview | yes |
| | scanWindow | Rect | Scan window rectangle | yes |
| | borderColor | Color | Scan window border color, default white | yes |
| | borderRadius | BorderRadius | Scan window border radius, default zero | yes |
| | borderStrokeCap | StrokeCap | Border stroke cap style, default butt | yes |
| | borderStrokeJoin | StrokeJoin | Border stroke join style, default miter | yes |
| | borderStyle | PaintingStyle | Border painting style, default stroke | yes |
| | borderWidth | double | Scan window border width | yes |
| | color | Color | Overlay color outside the scan window cutout | yes |
| ScanWindowPainter | borderColor | Color | Border color | yes |
| | borderRadius | BorderRadius | Border corner radius | yes |
| | borderStrokeCap | StrokeCap | Border stroke cap style | yes |
| | borderStrokeJoin | StrokeJoin | Border stroke join style | yes |
| | borderStyle | PaintingStyle | Border painting style | yes |
| | borderWidth | double | Border width | yes |
| | color | Color | Mask color outside the scan window | yes |
| | scanWindow | Rect | Scan window rectangle | yes |

> Among the classes above, except for fields specifically marked "OHOS: not supported", all are generally supported on OHOS. Structured data classes such as Address, PersonName, CalendarEvent, ContactInfo, Email, Phone, SMS, GeoPoint, UrlBookmark, WiFi, and DriverLicense are **not supported** on OHOS. See [2.2.1 Barcode Content Fields Not Supported](#221-barcode-content-fields-not-supported) for details.

### Enum Types

| Enum | Values | Description | ohos Support |
|------|--------|-------------|--------------|
| CameraFacing | back, front, external, unknown | Camera direction (OHOS only supports default camera, cannot switch) | yes |
| TorchState | on, off, unavailable | Torch state | yes |
| BarcodeFormat | unknown, all, qrCode, code128, code39, code93, ean13, ean8, upcA, upcE, pdf417, aztec, dataMatrix, itf, codabar | Barcode formats | yes |
| BarcodeType | calendarEvent, contactInfo, driverLicense, email, geo, isbn, phone, product, sms, text, url, wifi, unknown | Barcode types (OHOS only recognizes text/unknown) | partially |
| DetectionSpeed | noDuplicates, normal, unrestricted | Detection speed (OHOS: not supported) | no |
| AddressType | home, work, unknown | Address type | yes |
| EmailType | home, work, unknown | Email type | yes |
| PhoneType | fax, home, mobile, work, unknown | Phone type | yes |
| EncryptionType | unknown, open, wpa, wep | Wireless encryption type | yes |
| MobileScannerAuthorizationState | undetermined, authorized, denied | Camera authorization state | yes |
| MobileScannerErrorCode | controllerAlreadyInitialized, controllerDisposed, controllerUninitialized, genericError, permissionDenied, unsupported, controllerInitializing, controllerNotAttached | Scanner error codes from Dart public API | yes |
| | (OHOS native mapping) | cameraError → genericError, permissionError → permissionDenied, unspecified → unsupported | OHOS native error codes are mapped to the Dart API values above |

### Exported Functions

| Function | Signature | Description | ohos Support |
|----------|-----------|-------------|--------------|
| calculateBoxFitRatio | (BoxFit, Size, Size) → {double widthRatio, double heightRatio} | Calculate the scale ratio for a given BoxFit mode and original size, returns a Record with widthRatio and heightRatio | yes |


## 4. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### MobileScannerController

| Name                 | Description                                                               | Type                 |  ohos Support |
|----------------------|---------------------------------------------------------------------------|----------------------|---------------|
| facing               | Select which camera should be used (OHOS: not supported, see [2.2.3](#223-unsupported-properties)) | CameraFacing         |  no           |
| torchEnabled         | Enable or disable the torch (Flash) on start                              | bool                 |  yes          |
| returnImage          | Set to true if you want to return the image buffer with the Barcode event | bool                 |  yes          |
| formats              | If provided, the scanner will only detect those specific formats          | List<BarcodeFormat>? |  yes          |
| detectionTimeoutMs   | Sets the timeout, in milliseconds, of the scanner (OHOS: not supported, see [2.2.3](#223-unsupported-properties)) | int                  |  no           |
| autoStart            | Automatically start the mobileScanner on initialization                   | bool                 |  yes          |
| cameraResolution     | The desired resolution for the camera                                     | Size                 |  yes           |
| useNewCameraSelector | Use the new resolution selector (OHOS: not supported, see [2.2.3](#223-unsupported-properties)) | bool                 |  no           |
| detectionSpeed       | Sets the speed of detections (OHOS: not supported, see [2.2.3](#223-unsupported-properties)) | DetectionSpeed       |  no           |
| invertImage          | Whether to invert the image colors to support white-background black-barcode scanning | bool                 |  yes           |
| autoZoom             | Whether to enable auto zoom when a barcode is detected                  | bool                 |  yes           |
| initialZoom          | The initial zoom scale of the camera, must be within 0.0 and 1.0, where 1.0 is the max zoom, and 0.0 is zoomed out | double?                 | yes           |

### Parameters

| Name      | Description                                                                  | Type    | ohos Support |
|-----------|------------------------------------------------------------------------------|---------|--------------|
| window    | Scan code box size                                                           | Rect?   | yes          |
| zoomScale | must be within 0.0 and 1.0, where 1.0 is the max zoom, and 0.0 is zoomed out | double? | yes          |
| path      | The path of the image on the devices                                         | String? | yes          |


## 5. Known Issues

- [ ] Custom QR code scanning cannot switch to the front camera: [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)

## 6. Directory Structure

```
ohos/                          # OHOS platform adaptation code
├── index.ets                  # Plugin export entry
├── src/main/ets/
│   ├── MobileScannerPlugin.ets # Main orchestrator, manages Flutter Engine & Ability lifecycle
│   ├── MethodHandlers.ets      # Method handler (torch, zoom, scan window, focus, etc.)
│   ├── ScanCameraManager.ets   # Camera scan manager
│   ├── ScanResultProcessor.ets # Scan result processor (filter, deduplicate)
│   ├── ScanImageProcessor.ets  # Image frame processor (PixelMap conversion)
│   ├── ScanOptionsParser.ets   # Startup parameter parser (pure functions)
│   ├── ScanDisplayConfig.ets   # Display configuration calculator (pure functions)
│   ├── DeviceOrientationListener.ets # Device orientation listener
│   ├── CameraUtil.ets          # Camera utility functions
│   ├── CameraPermissions.ets   # Camera permission management
│   ├── Barcode.ets             # Barcode data model and enums
│   └── Types.ets               # Type definitions
example/                       # Example application
├── lib/                       # Example Dart code
└── ohos/                      # Example OHOS project configuration
test/                          # Test directory
```

## 7. License

This project is licensed under [BSD 3-Clause License](/LICENSE).