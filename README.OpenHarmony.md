> Template version: v0.0.1

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

This project is based on [mobile_scanner](https://pub.dev/packages/mobile_scanner).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependency in `pubspec.yaml`:

```yaml
dependencies:
  fluttertpc_mobile_scanner:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
      # ref: Select the TAG version that matches your Flutter framework version from the table below
      ref: TAG  # Select a TAG from the TAG version mapping table below
```

Run:

```bash
flutter pub get
```

### 1.2 TAG Version Mapping

| Flutter framework version | TAG name | Branch |
|---|---|---|
| 3.7 | 3.5.6-ohos-1.0.0-beta.1 | master |
| 3.22 | 6.0.2-ohos-1.0.0 | br_v6.0.2_ohos |
| 3.27 | 6.0.10-ohos-1.0.0 | br_v6.0.10_ohos |
| 3.35 | 7.1.4-ohos-1.0.0 | br_v7.1.4_ohos |

Tested on the following versions:

| Library Version | Flutter (OHOS) | SDK | DevEco Studio | ROM |
|-----------------|----------------|-----|---------------|-----|
| 6.0.2 | 3.22.1-ohos-1.0.1 | 5.0.0(17) | 6.1.1.290 | 6.1.0.135.SP8 |

### 1.3 Complete Usage Flow

Import and use the library in Dart code:

```dart
// 1. Import the library
import 'package:mobile_scanner/mobile_scanner.dart';

// 2. Create a controller (optional — omitting uses default configuration)
final controller = MobileScannerController(
  autoStart: true,       // Start scanning automatically on init
  returnImage: false,    // Return image buffer with barcode event
  torchEnabled: false,   // Enable flashlight on start
  formats: const [],     // Empty list means detect all barcode formats
);

// 3. Use the MobileScanner widget for the camera preview
MobileScanner(
  controller: controller,
  onDetect: (BarcodeCapture capture) {
    // Handle scan results
    for (final barcode in capture.barcodes) {
      print('Barcode: ${barcode.rawValue}');
    }
  },
);

// 4. Release resources (call in State.dispose())
controller.dispose();
```

### 1.4 Usage Example

See [example](/example/lib/main.dart) for a complete usage example.

## 2. Constraints

### 2.1 Compatibility

This library has been verified on the following versions:

| Library Version | Flutter (OHOS) | SDK | DevEco Studio | ROM |
|-----------------|----------------|-----|---------------|-----|
| 6.0.2 | 3.22.1-ohos-1.0.1 | 5.0.0(12) | 5.0.13.200 | 5.1.0.120 SP3 |

**Incompatibility Notes:**
- Flutter versions below 3.22.1-ohos-1.0.1 are not supported
- SDK versions below 5.0.0(12) are not supported
- OHOS 3.x and below are not compatible

**Upgrade/Migration Guide:**
- From 5.x to 6.0.2: `MobileScannerState` renamed to `MobileScannerAuthorizationState`, controller now uses `ChangeNotifier`
- From 6.0.0 to 6.0.2: `analyzeImage` format support fixed, iOS arm64 excluded for Simulators

### 2.2 Permissions and Development Environment Setup

#### Permission Configuration

**(1) Add camera permission to `entry/src/main/module.json5`:**

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

**(2) Add the permission reason to `entry/src/main/resources/base/element/string.json`:**

```diff
{
  "string": [
+    {
+      "name": "camera_reason",
+      "value": "Use camera"
+    }
  ]
}
```

#### Development Environment Setup

1. Install DevEco Studio (matching your Flutter SDK version)
2. Install OHOS SDK (matching your Flutter SDK version)
3. Configure `oh-package.json5` dependencies
4. Run `flutter pub get` to fetch dependencies
5. Open the `ohos/` directory in DevEco Studio for building

## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means the ohos platform supports this API; **no** means the opposite; **partially** means some capabilities are supported. The usage is consistent across platforms with behavior equivalent to iOS or Android.

### 3.1 MobileScannerController Methods

| Name | Description | Type | Input | Output | ohos Support |
|------|-------------|------|-------|--------|--------------|
| start | Start scanning for barcodes | function | {CameraFacing? cameraDirection} | Future\<void\> | yes |
| stop | Stop the camera without disposing the controller | function | / | Future\<void\> | yes |
| toggleTorch | Switch the torch on or off | function | / | Future\<void\> | yes |
| analyzeImage | Analyze a local image file for barcodes | function | String path, {List\<BarcodeFormat\> formats = const \<BarcodeFormat\>[]} | Future\<BarcodeCapture?\> | yes |
| setZoomScale | Set the camera zoom scale (OHOS range 0.0-10.0) | function | double zoomScale | Future\<void\> | yes |
| resetZoomScale | Reset zoom scale to default 1x | function | / | Future\<void\> | yes |
| updateScanWindow | Update the scan window area | function | Rect? window | Future\<void\> | yes |
| switchCamera | Switch between front and back camera | function | / | Future\<void\> | yes |
| dispose | Release controller resources | function | / | Future\<void\> | yes |
| barcodes | Barcode scan result event stream | Stream | / | Stream\<BarcodeCapture?\> | yes |

### 3.2 MobileScanner Widget

| Name | Description | Type | Input | ohos Support |
|------|-------------|------|-------|--------------|
| MobileScanner | Core scanning UI widget | Widget | controller, onDetect, onDetectError, errorBuilder, placeholderBuilder, overlayBuilder, fit, scanWindow, scanWindowUpdateThreshold | yes |

### 3.3 BarcodeCapture Result Types

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| BarcodeCapture | Scan result containing barcode list and optional image | class | yes |
| BarcodeCapture.barcodes | List of detected barcodes | List\<Barcode\> | yes |
| BarcodeCapture.image | Image buffer from scan (requires returnImage) | Uint8List? | yes |
| BarcodeCapture.raw | Raw scan data (includes input image and size) | Object? | yes |
| BarcodeCapture.size | Camera input image size | Size | yes |

### 3.4 Barcode Data

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| Barcode | Individual barcode data | class | yes |
| Barcode.rawValue | Raw UTF-8 encoded barcode value | String? | yes |
| Barcode.displayValue | User-friendly barcode value | String? | yes |
| Barcode.format | Barcode format (e.g. QRCode, EAN13) | BarcodeFormat | yes |
| Barcode.type | Barcode context type (e.g. TEXT, URL, PRODUCT) | BarcodeType | yes |
| Barcode.corners | Four corner coordinates of the barcode (clockwise, top-left first) | List\<Offset\> | yes |
| Barcode.size | Normalized size of the barcode bounding box | Size | yes |
| Barcode.rawBytes | Raw byte data of the barcode | Uint8List? | no |

## 4. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities are supported. The usage is consistent across platforms with behavior equivalent to iOS or Android.

### 4.1 MobileScannerController Properties

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| facing | Select front or back camera | CameraFacing | no |
| torchEnabled | Enable the torch (flash) on start | bool | yes |
| returnImage | Return image buffer with the barcode event | bool | yes |
| formats | Restrict detection to specific formats (empty list = all formats) | List\<BarcodeFormat\> | yes |
| detectionTimeoutMs | Scan timeout in milliseconds | int | no |
| autoStart | Automatically start scanning on initialization | bool | yes |
| cameraResolution | Desired camera resolution | Size | no |
| useNewCameraSelector | Use the new resolution selector | bool | no |
| detectionSpeed | Detection speed setting | DetectionSpeed | no |

### 4.2 Parameters

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| window | Scan window area | Rect? | yes |
| zoomScale | OHOS zoom scale must be between 0.0 and 10.0, where 1.0 is default, 0.0 is min, 10.0 is max | double? | yes |
| path | Local image file path | String? | yes |

### 4.3 StartOptions

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| cameraDirection | Camera direction | CameraFacing | yes |
| cameraResolution | Desired camera resolution | Size? | no |
| detectionSpeed | Detection speed | DetectionSpeed | no |
| detectionTimeoutMs | Detection timeout (milliseconds) | int | no |
| formats | Barcode formats to detect | List\<BarcodeFormat\> | yes |
| returnImage | Whether to return image data | bool | yes |
| torchEnabled | Enable torch on start | bool | yes |
| useNewCameraSelector | Use new resolution selector (Android only) | bool | yes |

## 5. Types and State

### 5.1 MobileScannerState

`MobileScannerController` exposes its current state via the `value` property. The state object contains the following fields:

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| availableCameras | Number of available cameras (null if unknown) | int? | yes |
| cameraDirection | Current camera direction | CameraFacing | yes |
| isInitialized | Whether the scanner has been initialized | bool | yes |
| isRunning | Whether the scanner is currently running | bool | yes |
| size | Camera output size | Size | yes |
| torchState | Current torch state | TorchState | yes |
| zoomScale | Current zoom scale | double | yes |
| error | Current exception (null if no error) | MobileScannerException? | yes |
| hasCameraPermission | Whether camera permission has been granted (computed) | bool | yes |

**Usage example:**

```dart
// Listen to controller state changes
controller.addListener(() {
  final state = controller.value;
  print('Initialized: ${state.isInitialized}');
  print('Running: ${state.isRunning}');
  print('Torch state: ${state.torchState}');
  print('Zoom scale: ${state.zoomScale}');
  print('Camera direction: ${state.cameraDirection}');
  print('Available cameras: ${state.availableCameras}');
  print('Camera size: ${state.size}');
  print('Has permission: ${state.hasCameraPermission}');
  if (state.error != null) {
    print('Error: ${state.error!.errorCode}');
  }
});
```

## 6. Exception Handling

### 6.1 MobileScannerException

The scanner controller throws `MobileScannerException` when an error occurs. Access the current error via `controller.value.error`, or receive error notifications through the `MobileScanner` widget's `onDetectError` callback.

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| MobileScannerException | Scanner controller exception | class | yes |
| errorCode | Error code | MobileScannerErrorCode | yes |
| errorDetails | Detailed error information | MobileScannerErrorDetails? | yes |

### 6.2 MobileScannerErrorDetails

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| MobileScannerErrorDetails | Error details | class | yes |
| code | Error code from PlatformException | String? | yes |
| details | Details from PlatformException | Object? | yes |
| message | Error message from PlatformException | String? | yes |

### 6.3 MobileScannerBarcodeException

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| MobileScannerBarcodeException | Exception during barcode scanning | class | yes |
| message | Error message | String? | yes |

**Error handling example:**

```dart
// Handle errors via onDetectError callback
MobileScanner(
  controller: controller,
  onDetect: (capture) { /* handle scan results */ },
  onDetectError: (error, details) {
    // OHOS: Handle scanning errors
    if (error == MobileScannerErrorCode.permissionDenied) {
      print('Camera permission denied');
    } else {
      print('Scan error: ${details?.message}');
    }
  },
);

// Or monitor errors via the controller state
controller.addListener(() {
  final error = controller.value.error;
  if (error != null) {
    // OHOS: Handle different exceptions based on error code
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        // Handle permission denied
        break;
      case MobileScannerErrorCode.genericError:
        // Handle generic error (includes barcode recognition errors)
        break;
      case MobileScannerErrorCode.unsupported:
        // Handle unsupported device
        break;
    }
  }
});
```

## 7. Code Examples

### 7.1 Basic Scanner Example

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  // OHOS: Create controller with autoStart enabled
  MobileScannerController controller = MobileScannerController(
    autoStart: true,
    returnImage: false,
    formats: const [], // Empty list means detect all formats
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          // OHOS: Iterate through scan results
          for (final barcode in capture.barcodes) {
            print('Barcode: ${barcode.rawValue}');
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // OHOS: Release controller resources to prevent memory leaks
    controller.dispose();
    super.dispose();
  }
}
```

### 7.2 Torch Control Example

```dart
// OHOS: Toggle flashlight
await controller.toggleTorch();

// OHOS: Listen to barcode event stream
controller.barcodes.listen((BarcodeCapture capture) {
  for (final barcode in capture.barcodes) {
    print('Result: ${barcode.rawValue}');
  }
});
```

### 7.3 Local Image Analysis Example

```dart
// OHOS: Analyze a local image file for barcodes
final BarcodeCapture? result = await controller.analyzeImage(
  '/path/to/image.jpg',
  formats: [BarcodeFormat.qrCode], // Only detect QR codes
);

if (result != null) {
  // OHOS: Iterate through recognition results
  for (final barcode in result.barcodes) {
    print('Result: ${barcode.rawValue}');
    print('Format: ${barcode.format}');
  }
}
```

### 7.4 Scan Window and Zoom Control Example

```dart
// OHOS: Set scan window to center area of the screen
final screenSize = MediaQuery.of(context).size;
final scanWindow = Rect.fromCenter(
  center: Offset(screenSize.width / 2, screenSize.height / 2),
  width: screenSize.width * 0.8,
  height: screenSize.width * 0.8,
);
await controller.updateScanWindow(scanWindow);

// OHOS: Set zoom scale (OHOS supports 0.0-10.0)
await controller.setZoomScale(2.0); // 2x zoom

// OHOS: Reset zoom scale to 1.0
await controller.resetZoomScale();
```

## 8. Known Issues

- [ ] Custom QR code scanning cannot switch to the front camera: [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)
- [ ] OHOS platform does not support detection speed/timeout configuration (ScanKit limitation)
- [ ] OHOS platform does not support structured barcode content parsing (ScanKit only returns raw value)
- [ ] OHOS platform does not support `rawBytes` field

## 9. License

This project is licensed under [BSD 3-Clause License](LICENSE).