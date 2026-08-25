# Changelog - OpenHarmony

## 6.0.10-ohos-1.0.0 - 2026.8

### Bug Fixes
- Fixed `analyzeImage` barcode results missing `corners` on OpenHarmony — barcodes are now serialized via `Barcode.toMap()` before MethodChannel/EventChannel transmission (matching Android/iOS); `_convertResult()` prefers ScanKit `cornerPoints` when available and falls back to `scanCodeRect`
- Fixed privacy compliance issue where the plugin accessed sensor data before user consent to the privacy policy.
- Fixed `onDetachedFromAbility` not cleaning up `scanResultCallback` and `frameResultCallback` references — now sets them to null to prevent closure leaks
- Fixed `processFrame()` not awaited in `onFrameResult_` — now properly awaits the async method to ensure image buffer is ready before scan result callback
- Fixed `setDisplay()` error swallowed — now throws error to propagate display configuration failure to caller
- Fixed `retryHandler_` field not declared/initialized — now properly initialized with lifecycle-safe try-catch guards in both `onDetachedFromAbility` and `onDetachedFromEngine`
- Fixed shared state (`isStart_`, `isPaused_`, `isScanReg_`) thread model documentation — added ArkTS single-thread model annotation in class header
- Removed dead code: `processFrame_()` and `releaseImageResources_()` duplicate methods that shadowed `ImageProcessor` class functionality
- Fixed `CameraUtil.getErrMsg()` and `CameraPermissions.getErrorCode()` parameter types — now accept `Object | null | undefined` to match actual usage
- Fixed type assertion in `getNumberArray()` — replaced unsafe `val as number[]` with safe explicit array construction

### Code Quality
- Renamed all private members from `_` suffix to `_` prefix (`methodChannel_` → `_methodChannel`) per ArkTS coding convention
- Renamed all private methods from `_` suffix to `_` prefix (`handleState_` → `_handleState`) per ArkTS coding convention
- Added JSDoc `@param` and `@returns` annotations to `makePoint()` function
- Added `_isDetached` flag to protect callbacks from processing after plugin detach
- Added complete type annotations for `retryTimes_`, `retryTimer_`, `retryHandler_` fields in both `RetryHandler` and `MobileScannerPlugin` classes

### Documentation
- Fixed table headers in README.OpenHarmony_CN.md — replaced mixed Chinese/English headers ("名称/Name") with pure Chinese ("名称")
- Added missing `StartOptions` property descriptions (cameraResolution, detectionSpeed, detectionTimeoutMs, formats, returnImage, torchEnabled, useNewCameraSelector)
- Added missing `MobileScannerViewAttributes` class documentation (currentTorchMode, numberOfCameras, size)
- Added missing `ScannerErrorWidget` class documentation (error property)
- Added `cameraDirection` field to `MobileScannerViewAttributes` documentation
- Fixed `BarcodeCapture.size` type in English README from `Size?` to `Size`
- Fixed `errorBuilder` signature in Chinese README to match actual type `Widget Function(BuildContext, MobileScannerException, Widget?)`

### Test Coverage
- Added `scanner_error_widget_test.dart` with 6 test cases covering ScannerErrorWidget construction, error display, error details, background color, error property access, and debug/release mode rendering
- Added timeout scenario tests: delayed platform response test and barcode stream detectionTimeoutMs test
- Removed unused `dart:ui` import, redundant `mobile_scanner_error_code.dart` and `mobile_scanner_exception.dart` imports, and unused `eventChannel` variable in `mobile_scanner_test.dart`
- Added `EventChannel` mock setup in `mobile_scanner_test.dart`

## 6.0.10-ohos-1.0.0-beta.1

### ohos Adaptation Initialization
- First completed OpenHarmony platform adaptation, based on `mobile_scanner` 6.0.10
- Integrated `@kit.CameraKit` camera capabilities for camera preview, scanning, and flashlight control
- Integrated `@kit.ScanKit` scanning capabilities supporting multi-format barcode scanning (QR Code, EAN-13, Code 128, etc.)
- Implemented Flutter MethodChannel/EventChannel bidirectional communication, bridging Dart and ArkTS native layers
- Support for camera lifecycle management (start/stop/pause/resume)
- Support for front/rear camera switching, zoom control, and torch control
- Support for scan window (ScanWindow) cropping functionality
- Support for image analysis (analyzeImage) functionality
- Support for multi-camera detection and automatic selection