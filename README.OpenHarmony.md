> Template version: v0.1.0

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

This project is based on [mobile_scanner](https://pub.dev/packages/mobile_scanner).

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Constraints](#constraints)
- [Usage Notes](#usage-notes)
- [API Reference](#api-reference)
- [New Features](#new-features)
- [Known Issues](#known-issues)
- [FAQ](#faq)
- [Directory Structure](#directory-structure)
- [Contributing](#contributing)
- [License](#license)

## Introduction

mobile_scanner is a universal barcode and QR code scanner for Flutter. On OpenHarmony, it leverages ScanKit for barcode detection, supporting real-time camera preview scanning, local image barcode analysis, torch control, and zoom control.

## Installation

### Dependency Configuration

Add the following dependency to `pubspec.yaml`:

```yaml
dependencies:
  mobile_scanner:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner.git
      ref: 6.0.10-ohos-1.0.0-beta.2
```

Run:

```bash
flutter pub get
```

### TAG Version Mapping

| Flutter (OHOS) | TAG |
|----------------|-----|
| 3.22.1-ohos-1.0.1 | 6.0.10-ohos-1.0.0-beta.2 |
| 3.27.4-ohos-1.0.0 | 6.0.10-ohos-1.0.0-beta.2 |

## Usage

### Simple Scanner Example

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// 1. Create a scanner page
class BarcodeScannerSimple extends StatefulWidget {
  const BarcodeScannerSimple({super.key});

  @override
  State<BarcodeScannerSimple> createState() => _BarcodeScannerSimpleState();
}

class _BarcodeScannerSimpleState extends State<BarcodeScannerSimple> {
  Barcode? _barcode;

  // 2. Handle barcode detection results
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
      appBar: AppBar(title: const Text('Simple scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 3. Use MobileScanner Widget for camera preview
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          // 4. Display scan results
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
                    _barcode?.displayValue ?? 'Scanning...',
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

### Complete Usage Flow

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

// 1. Create a controller
// Note: OHOS only supports back camera (facing is ignored)
final MobileScannerController controller = MobileScannerController(
  autoStart: false,
  torchEnabled: false,
  returnImage: false,
  formats: [BarcodeFormat.qrCode], // OHOS supports all formats listed in BarcodeFormat
);

// 2. Listen to barcode stream
controller.barcodes.listen((BarcodeCapture capture) {
  for (final Barcode barcode in capture.barcodes) {
    // Note: On OHOS, barcode.rawBytes is null (not supported by ScanKit)
    // Note: On OHOS, barcode.type always returns BarcodeType.unknown for structured content
    print('Barcode found: ${barcode.displayValue}');
  }
});

// 3. Start scanning
await controller.start();

// 4. Widget usage
MobileScanner(
  controller: controller,
  onDetect: (BarcodeCapture capture) {
    // Handle barcode detection
  },
  errorBuilder: (context, error, child) {
    return Text('Scanner error: $error');
  },
);

// 5. Pause/Resume (lightweight)
await controller.pause();
await controller.start();

// 6. Stop and dispose
await controller.stop();
await controller.dispose();
```

### Standalone API Examples

**toggleTorch:**
```dart
// Toggle flashlight on/off
// Note: TorchState.auto is not supported on OHOS
await controller.toggleTorch();
```

**setZoomScale / resetZoomScale:**
```dart
// Set camera zoom level
// Note: OHOS zoom range is 0.0 ~ 10.0 (other platforms: 0.0 ~ 1.0)
await controller.setZoomScale(2.0); // 2x zoom on OHOS
// Reset zoom to 1x
await controller.resetZoomScale();
```

**analyzeImage:**
```dart
// Analyze a local image file for barcode detection (supported on OHOS via ScanKit)
final BarcodeCapture? result = await controller.analyzeImage(
  '/path/to/image.jpg',
  formats: [BarcodeFormat.qrCode, BarcodeFormat.code128],
);
if (result != null) {
  for (final Barcode barcode in result.barcodes) {
    print('Detected: ${barcode.displayValue}');
  }
}
```

**updateScanWindow:**
```dart
import 'dart:ui';

// Update the scan window region (scans only within this area)
controller.updateScanWindow(
  Rect.fromLTWH(50, 100, 300, 300),
);
```

**pause / resume:**
```dart
// Pause camera (lightweight, keeps resources)
await controller.pause();
// Resume scanning
await controller.start();
```

**switchCamera:**
```dart
// Note: Not supported on OHOS (only back camera is available)
await controller.switchCamera();
```

## Constraints

### Compatibility

| Library Version | Flutter (OHOS) | DevEco Studio | SDK | ROM |
|----------------|----------------|---------------|-----|-----|
| 6.0.10 | 3.22.1-ohos-1.0.1 | 5.0.13.200 | 5.0.0(12) | 5.1.0.120 SP3 |
| 6.0.10 | 3.27.4-ohos-1.0.0 | 5.0.13.200 | 5.0.0(12) | 5.1.0.120 SP3 |

> **Known incompatibilities:**
> - Front camera switching is not supported on OHOS
> - `detectionSpeed`, `detectionTimeoutMs`, `cameraResolution`, `useNewCameraSelector` are not supported on OHOS
> - Structured barcode content parsing (calendarEvent, contactInfo, etc.) returns `type: unknown` on OHOS
> - `zoomScaleState` event is not available on OHOS (zoom state is returned synchronously)
> - `TorchState.auto` is not supported on OHOS

### Permission Requirements

Add the camera permission to `module.json5` in the entry directory:

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

Add the permission reason to `entry/src/main/resources/base/element/string.json`:

```diff
...
{
  "string": [
+    {
+      "name": "camera_reason",
+      "value": "Use camera"
+    }
  ]
}
```

### Environment Setup

**Prerequisites:**
- DevEco Studio 5.0.13.200 or later
- OHOS SDK 5.0.0(12) or later
- Flutter OHOS plugin 3.7.12-ohos-1.0.6 / 3.22.1-ohos-1.0.1 / 3.27.4-ohos-1.0.0

**Build Steps:**
1. Install DevEco Studio from the official website
2. Configure OHOS SDK in DevEco Studio (Settings → SDK Manager → ohos)
3. Clone the project and run `flutter pub get`
4. Open the `ohos/` directory in DevEco Studio for OHOS-specific build configuration
5. Build and run using DevEco Studio or CLI

## Usage Notes

> **MobileScannerController** is the core controller that manages the scan lifecycle (start, pause, stop, dispose).
> Receive barcode detection results via the `barcodes` stream, and display the camera preview via the `MobileScanner` Widget.

### Typical Usage Flow

1. Create a `MobileScannerController` instance with desired scan parameters
2. Listen to `controller.barcodes` stream for detection results
3. Use the `MobileScanner` Widget to display the camera preview
4. Call `controller.start()` to begin scanning
5. Call `controller.dispose()` to release resources when done

## API Reference

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### Methods

| Name | Description | Type | Input | Output | ohos Support |
|------|-------------|------|-------|--------|--------------|
| start | Start scanning for barcodes | function | {CameraFacing? cameraDirection} | Future\<void\> | yes |
| stop | Stops the camera, but does not dispose this controller | function | {bool? force} | Future\<void\> | yes |
| pause | Pauses the camera (lightweight, keeps resources) | function | {bool? force} | Future\<void\> | yes |
| toggleTorch | Switches the torch on or off | function | / | Future\<void\> | yes |
| analyzeImage | Handles a local image file for barcode detection | function | String path, {List\<BarcodeFormat\> formats = const \<BarcodeFormat\>[]} | Future\<BarcodeCapture?\> | yes |
| setZoomScale | Set the zoomScale of the camera | function | double zoomScale | Future\<void\> | yes |
| resetZoomScale | Reset the zoomScale of the camera to use standard scale 1x | function | / | Future\<void\> | yes |
| updateScanWindow | Updates the native ScanWindow | function | Rect? window | Future\<void\> | yes |
| switchCamera | Changes the state of the camera (front or back) | function | / | Future\<void\> | yes |
| dispose | Releases all resources held by the controller | function | / | Future\<void\> | yes |

**Additional Streams:**

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| barcodes | Stream of barcode detection results | Stream\<BarcodeCapture\> | yes |
| zoomScaleState | Stream of zoom scale changes | Stream\<double\> | no |

### Properties

#### MobileScannerController

| Name | Description | Type | ohos Support |
|------|-------------|------|-------------|
| facing | Select which camera should be used | CameraFacing | no |
| torchEnabled | Enable or disable the torch (Flash) on start | bool | yes |
| returnImage | Set to true if you want to return the image buffer with the Barcode event | bool | yes |
| formats | If provided, the scanner will only detect those specific formats | List\<BarcodeFormat\> | yes |
| detectionTimeoutMs | Sets the timeout, in milliseconds, of the scanner | int | no |
| autoStart | Automatically start the mobileScanner on initialization | bool | yes |
| cameraResolution | The desired resolution for the camera | Size | no |
| useNewCameraSelector | Use the new resolution selector | bool | no |
| detectionSpeed | Sets the speed of detections | DetectionSpeed | no |

### Additional Parameters

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| window | Scan code box size | Rect? | yes |
| zoomScale | Camera zoom scale (OHOS: 0.0~10.0, other platforms: 0.0~1.0, where max is the furthest zoom) | double? | yes (OHOS range: 0.0~10.0) |
| path | The path of the image on the devices | String? | yes |

### Data Classes

#### BarcodeCapture

The result container returned on barcode detection. It wraps the detected barcodes along with the frame image.

| Property | Type | Description | OHOS Support |
|----------|------|-------------|-------------|
| barcodes | List\<Barcode\> | List of detected barcodes in the frame | yes |
| image | Uint8List? | The raw image data when `returnImage` is enabled | yes |
| raw | Object? | The raw data of the barcode scan (input image, barcodes, and size) | yes |
| size | Size | The size of the captured image | yes |

#### Barcode

Represents a single detected barcode.

| Property | Type | Description | OHOS Support |
|----------|------|-------------|-------------|
| displayValue | String? | Human-readable decoded content | yes |
| rawValue | String? | Raw decoded content as a string | yes |
| format | BarcodeFormat | The detected barcode format (e.g., qrCode, code128) | yes |
| type | BarcodeType | Structured content type (calendarEvent, contactInfo, email, geoPoint, isbn, phone, product, sms, text, url, wifi, driverLicense, unknown) | partially (all structured types return `type: unknown` on OHOS) |
| rawBytes | Uint8List? | Raw bytes of the barcode | no (ScanKit does not provide raw byte data) |
| corners | List\<Offset\> | Four corner points of the barcode (clockwise, starting from top-left) | yes |
| size | Size | The normalized size of the barcode bounding box | yes |
| calendarEvent | CalendarEvent? | Calendar event embedded in the barcode | partially (all return `type: unknown` on OHOS) |
| contactInfo | ContactInfo? | Contact information embedded in the barcode (e.g., vCard) | partially (all return `type: unknown` on OHOS) |
| driverLicense | DriverLicense? | Driver's license information embedded in the barcode | partially (all return `type: unknown` on OHOS) |
| email | Email? | Email information embedded in the barcode | partially (all return `type: unknown` on OHOS) |
| geoPoint | GeoPoint? | Geographic coordinates embedded in the barcode | partially (all return `type: unknown` on OHOS) |
| phone | Phone? | Phone number embedded in the barcode | partially (all return `type: unknown` on OHOS) |
| sms | SMS? | SMS message embedded in the barcode | partially (all return `type: unknown` on OHOS) |
| url | UrlBookmark? | URL bookmark embedded in the barcode | partially (all return `type: unknown` on OHOS) |
| wifi | WiFi? | WiFi configuration embedded in the barcode | partially (all return `type: unknown` on OHOS) |

#### BarcodeType

An enum representing the structured content type extracted from a barcode.

| Enum Value | Description |
|------------|-------------|
| unknown | Unrecognized or unsupported type |
| contactInfo | Contact information (e.g., vCard) |
| email | Email address |
| isbn | ISBN |
| phone | Phone number |
| product | Product code |
| sms | SMS message |
| text | Plain text |
| url | URL |
| wifi | WiFi configuration |
| geo | Geographic coordinates |
| calendarEvent | Calendar event (e.g., vEvent) |
| driverLicense | Driver's license information |

#### BarcodeFormat

An enum specifying the barcode symbology to scan for.

| Enum Value | Description | OHOS Support |
|------------|-------------|-------------|
| unknown | Unknown format | yes |
| all | All supported formats | yes |
| code128 | Code 128 | yes |
| code39 | Code 39 | yes |
| code93 | Code 93 | yes |
| codabar | Codabar | yes |
| dataMatrix | Data Matrix | yes |
| ean13 | EAN-13 | yes |
| ean8 | EAN-8 | yes |
| itf | ITF (Interleaved Two-of-Five) | yes |
| qrCode | QR Code | yes |
| upcA | UPC-A | yes |
| upcE | UPC-E | yes |
| pdf417 | PDF417 | yes |
| aztec | Aztec Code | yes |

#### MobileScannerState

Provides the current state of the scanner controller.

| Property | Type | Description | OHOS Support |
|----------|------|-------------|-------------|
| availableCameras | int? | The number of available cameras (null if unknown) | yes |
| cameraDirection | CameraFacing | The current facing direction of the camera | yes |
| isInitialized | bool | Whether the scanner has been initialized | yes |
| isRunning | bool | Whether the scanner is currently running | yes |
| torchState | TorchState | The current torch/flash state | yes |
| zoomScale | double | The current zoom scale value | yes |
| size | Size | The camera preview size | yes |
| error | MobileScannerException? | The error that occurred while setting up or using the camera | yes |
| hasCameraPermission | bool | Whether camera permission was granted (getter) | yes |

#### MobileScannerException

Represents an exception thrown by the `MobileScannerController`, propagated through `onDetectError` callback or the error stream.

| Property | Type | Description |
|----------|------|-------------|
| errorCode | MobileScannerErrorCode | The error code of the exception (e.g., controllerDisposed, permissionDenied) |
| errorDetails | MobileScannerErrorDetails? | Additional error details from the platform |

#### StartOptions

Configuration options for the `start()` method.

| Property | Type | Description | OHOS Support |
|----------|------|-------------|-------------|
| cameraDirection | CameraFacing | The camera direction to use on start | no (scan starts with the default back camera) |
| cameraResolution | Size? | The desired camera resolution | no |
| detectionSpeed | DetectionSpeed | The detection speed mode | no |
| detectionTimeoutMs | int | The detection timeout in milliseconds | no |
| formats | List\<BarcodeFormat\> | The barcode formats to detect | yes |
| returnImage | bool | Whether to return the scanned image data | yes |
| torchEnabled | bool | Whether to enable the torch on start | yes |
| useNewCameraSelector | bool | Whether to use the new camera selector | no |

#### CameraFacing

An enum specifying the camera direction.

| Enum Value | Description | OHOS Support |
|------------|-------------|-------------|
| back | Back-facing camera | yes |
| front | Front-facing camera | no (ScanKit does not support front camera selection) |

#### TorchState

An enum specifying the torch/flash state.

| Enum Value | Description | OHOS Support |
|------------|-------------|-------------|
| unavailable | Torch is unavailable (no flash unit) | yes |
| off | Torch is off | yes |
| on | Torch is on | yes |
| auto | Torch is set to auto mode | no (iOS-only feature) |

#### DetectionSpeed

An enum controlling the detection frequency.

| Enum Value | Description | OHOS Support |
|------------|-------------|-------------|
| noDuplicates | Scans barcodes once, never again until another barcode is scanned | no |
| normal | Normal detection speed, respects the configured timeout | no |
| unrestricted | Unrestricted detection speed (max throughput) | no |

#### MobileScannerErrorCode

An enum defining the error codes for the mobile scanner.

| Enum Value | Description |
|------------|-------------|
| controllerAlreadyInitialized | The controller was already started; stop it before starting again |
| controllerDisposed | The controller was used after being disposed |
| controllerUninitialized | The controller was used before calling `start()` |
| genericError | A generic error occurred |
| permissionDenied | Camera permission was denied |
| unsupported | Scanning is not supported on the current device |

#### MobileScannerAuthorizationState

An enum representing the authorization state of the scanner.

| Enum Value | Description |
|------------|-------------|
| undetermined | The scanner has not yet requested the required permissions |
| authorized | The scanner has the required permissions |
| denied | The user denied the required permissions |

#### MobileScannerViewAttributes

The view attributes returned by `start()`.

| Property | Type | Description | OHOS Support |
|----------|------|-------------|-------------|
| currentTorchMode | TorchState | The current torch state | yes |
| numberOfCameras | int? | The number of available cameras | yes |
| size | Size | The camera output size | yes |
| cameraDirection | CameraFacing? | The actual camera direction used by the platform | yes |

#### ScannerErrorWidget

A widget that displays an error when the scanner fails to initialize.

| Property | Type | Description | OHOS Support |
|----------|------|-------------|-------------|
| error | MobileScannerException | The error to display | yes |

#### MobileScannerErrorDetails

The raw error details for a `MobileScannerException`.

| Property | Type | Description |
|----------|------|-------------|
| code | String? | The error code from the `PlatformException` |
| details | Object? | The details from the `PlatformException` |
| message | String? | The error message from the `PlatformException` |

#### MobileScannerBarcodeException

An exception thrown when a barcode scanning error occurs when processing an input frame.

| Property | Type | Description |
|----------|------|-------------|
| message | String? | The error message of the exception |

#### Address

Represents an address extracted from a barcode.

| Property | Type | Description |
|----------|------|-------------|
| addressLines | List\<String\> | The address lines |
| type | AddressType | The address type (work, home, unknown) |

#### PersonName

A person's name, split into individual components.

| Property | Type | Description |
|----------|------|-------------|
| first | String? | First name |
| middle | String? | Middle name |
| last | String? | Last name |
| prefix | String? | Name prefix |
| suffix | String? | Name suffix |
| formattedName | String? | Formatted full name |
| pronunciation | String? | Name pronunciation (Japanese phonebook furigana) |

#### UrlBookmark

A URL and title from a barcode (e.g., MEBKM).

| Property | Type | Description |
|----------|------|-------------|
| url | String | The URL of the bookmark |
| title | String? | The title of the bookmark |

#### AddressType

An enum for address types.

| Enum Value | Description |
|------------|-------------|
| unknown | Unknown address type |
| work | Work address |
| home | Home address |

#### EmailType

An enum for email types.

| Enum Value | Description |
|------------|-------------|
| unknown | Unknown email type |
| work | Work email |
| home | Home email |

#### EncryptionType

An enum for WiFi encryption types.

| Enum Value | Description |
|------------|-------------|
| unknown | Unknown encryption type |
| open | No encryption |
| wpa | WPA encryption |
| wep | WEP encryption |

#### PhoneType

An enum for phone types.

| Enum Value | Description |
|------------|-------------|
| unknown | Unknown phone type |
| work | Work phone |
| home | Home phone |
| fax | Fax number |
| mobile | Mobile phone number |

### MobileScanner Widget

| Name | Description | Type | ohos Support |
|------|-------------|------|--------------|
| constructor | Creates a MobileScanner widget | Widget | yes |
| controller | MobileScannerController instance | MobileScannerController | yes |
| onDetect | Callback when barcode is detected | void Function(BarcodeCapture) | yes |
| onDetectError | Callback when detection error occurs | void Function(Object,StackTrace?) | yes |
| errorBuilder | Custom error widget builder | Widget Function(BuildContext,Object,StackTrace?) | yes |
| placeholderBuilder | Placeholder widget while initializing | Widget Function(BuildContext,Object?) | yes |
| fit | How to inscribe the scanner into the widget | BoxFit | yes |
| scanWindow | The area in which to scan for barcodes | Rect? | yes |
| overlayBuilder | Builds a widget on top of the scanner | Widget Function(BuildContext,Rect?) | yes |
| scanWindowUpdateThreshold | The threshold for updating the scan window | double | yes |

## New Features

None.

## Known Issues

- [ ] Custom QR code scanning cannot switch to the front camera: [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)
- [ ] `hasFlashUnit` detection may return false on some devices (using CameraKit API)
- [ ] `analyzeImage` format filtering is limited by ScanKit capabilities

## FAQ

### Platform Limitations

The following features are limited or not available on OHOS due to ScanKit API constraints:

| Feature | Status | Notes |
|---------|--------|-------|
| Front camera switching | Not supported | ScanKit customScan does not support camera position selection |
| Detection speed configuration | Not supported | ScanKit customScan has no speed configuration API |
| Detection timeout | Not supported | Uses custom setTimeout workaround (250ms/100ms) |
| Camera resolution control | Not supported | ScanKit manages resolution internally |
| useNewCameraSelector | Not supported | Android-only feature |
| Structured barcode content parsing | Not supported | CalendarEvent, ContactInfo, Email, GeoPoint, Phone, SMS, URL, WiFi, DriverLicense all return type: unknown |
| rawBytes field | Not supported | ScanKit ScanResult does not provide raw byte data |
| TorchState.auto | Not supported | iOS-only feature |
| zoomScaleState event | Not available | Zoom state is returned synchronously on setScale/resetScale |

### Migration Guide

#### Upgrading from 6.0.10-ohos-1 to 6.0.10-ohos-2

No breaking API changes. The following improvements are transparent to users:

- **Memory leak fixes**: All system resources (PixelMap, ImagePacker, ImageSource) are now properly released
- **Better error handling**: Exceptions are now properly propagated to the Flutter layer
- **Improved consistency**: `setScale`/`resetScale` now return `null` (void) as expected
- **Enhanced stability**: Engine detachment now properly cleans up all resources

#### General upgrade steps

1. Update the dependency version in pubspec.yaml
2. Run `flutter pub get`
3. Check the [CHANGELOG.OpenHarmony.md](./CHANGELOG.OpenHarmony.md) for detailed changes

## Directory Structure

```
├── lib/                         # Core library code
│   ├── mobile_scanner.dart      # Entry point
│   ├── src/
│   │   ├── mobile_scanner.dart           # MobileScanner Widget
│   │   ├── mobile_scanner_controller.dart # Scanner controller
│   │   ├── mobile_scanner_exception.dart  # Exception definitions
│   │   ├── mobile_scanner_platform_interface.dart # Platform interface
│   │   ├── mobile_scanner_view_attributes.dart    # View attributes
│   │   ├── enums/                 # Enum definitions
│   │   └── objects/               # Data models
│   └── ...
├── ohos/                        # OpenHarmony native code
│   └── src/main/ets/
│       ├── MobileScannerPlugin.ets  # Plugin main implementation
│       ├── Barcode.ets              # Barcode data model & conversion
│       ├── CameraUtil.ets           # Camera utility functions
│       └── CameraPermissions.ets    # Permission management
├── example/                      # Example project
├── test/                         # Unit tests
├── README.OpenHarmony.md         # English documentation
├── README.OpenHarmony_CN.md      # Chinese documentation
└── CHANGELOG.OpenHarmony.md      # Changelog
```

## Contributing

Contributions via Issues or Pull Requests are welcome. Please ensure:

1. Code style follows project conventions
2. New features include unit tests
3. Documentation is kept in sync

## License

This project is licensed under [BSD 3-Clause License](/LICENSE).