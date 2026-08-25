# mobile_scanner OpenHarmony Changelog

## 6.0.2-ohos-1.0.0

### Bugs Fixed
- Fixed `analyzeImage` returning `Barcode` objects without `corners` — now reuses shared ScanKit result parsing with `scanCodeRect` fallback and includes `size`, matching Android/iOS behavior.
- Fixed privacy compliance issue where the plugin accessed sensor data before user consent to the privacy policy:
  - Removed `display.orientation` usage in `ScanHandler.setDisplay()` — reading screen orientation on ohos may trigger accelerometer access; replaced with portrait detection via display width/height comparison (`height >= width`).
  - Deferred camera preview texture (`registerTexture`) registration from `onAttachedToEngine` to `start()` — plugin attach no longer initializes camera-related hardware resources at app launch before privacy consent.
- Fixed callback event loss when `returnImage=true` and `image` is null — barcode events are now always sent regardless of image availability.
- Fixed `analyzeImage` `formats` parameter being ignored (always used `ScanType.ALL`); now correctly converts and applies the specified barcode formats.
- Fixed `analyzeImage` duplicate event sending — results are now returned exclusively via MethodChannel, eliminating duplicate barcode data on the Dart side.
- Fixed `setScale`/`resetScale` returning boolean instead of `null` and swallowing errors; now returns `null` on success and propagates `PlatformException` on failure.
- Fixed `hasFlashUnit` stub that always returned `true` without actual flash detection; restored the real `photoSession.hasFlash()` call.
- Fixed `start` method error code hardcoded as `"Name not found"`; now returns differentiated error codes (`MOBILE_SCANNER_ALREADY_STARTED_ERROR`, `MOBILE_SCANNER_NO_CAMERA_ERROR`, `MOBILE_SCANNER_CAMERA_ERROR`).
- Fixed `numberOfCameras` hardcoded to `1`; now queries the actual camera count via `cameraManager.getCameraDevices()`.
- Fixed `getFlashLightStatue` typo — renamed to `getFlashLightStatus`.
- Fixed `request` permission method throwing `PlatformException` on denial; now returns `false` to match Android/iOS behavior.
- Fixed `callback` rescan timer using hardcoded timeout values; now uses the `timeout` parameter passed from Dart.
- Fixed `setScale` unsafe type assertion (`call.args as number`); now uses `call.argument("zoom")` with a safe default.
- Fixed `CameraPermissions.checkAccessToken` returning potentially incorrect grant status when `tokenId` is 0 (bundle info fetch failure); now returns `PERMISSION_DENIED` early.
### Improvements
- **Resource lifecycle**: Added proper resource cleanup in `onDetachedFromEngine` — 7-step release flow (timers → scan → channels → state → texture → callbacks → context).
- **Exception handling**: Added try-catch for all async method paths (`start()`, `stop()`, `startCamera()`, `retryCamera()`).
- **Error propagation**: Added error propagation from `scanCallback` and `frameCallback` to the Flutter side via `publishEvent('error')`.
- **Memory leaks**: Added `PixelMap.release()`, `ImageSource.release()`, `ImagePacker.release()` in `frameCallback` finally block with individual try-catch protection.
- **Lifecycle management**: Added scan stop on `onDetachedFromAbility`; comprehensive state reset in `onDetachedFromEngine` (including `cameraResolutionValues`, `formats`, `torch`, `facing`, `speed`, `timeout`).
- **Circular reference protection**: Cleared `scanCallback` and `frameCallback` references in `onDetachedFromEngine` to break the closure capture chain.
- **Timer tracking**: All `setTimeout` IDs are now tracked via `pendingTimers` array and properly cancelled during cleanup.
- **PhotoSession release**: `CameraUtil.hasFlashUnit()` now releases the `photoSession` via `finally` block to prevent camera session resource leaks.
- **Parameter validation**: Added boundary validation for `facing` (0 or 1), `speed` (0-2), and `timeout` (>=0) in the `start()` method.
- **`zoomScaleState` event**: `setScale()` and `resetScale()` now publish `zoomScaleState` events to match Android/iOS behavior.
- **`onAttachedToEngine`**: Wrapped initialization in try-catch for graceful degradation on failure.
- **Code style**: Unified `call.argument()` API usage across all methods; unified publishEvent property naming (no quotes); fixed callback indentation; split long lines (>120 chars); added JSDoc for `BarcodeMap` and `ImageMap` interfaces; unified logging API (`Log.e()` instead of `hilog.error()`); removed unused `hilog` import.
- **Type safety**: Removed `ESObject` usage; replaced with `ScannerEvent` interface. All variables have explicit type annotations.
- **CameraPermissions**: Added `CAMERA_PERMISSION` constant (UPPER_CASE naming); changed error message from Chinese to English.
- **Barcode.ets**: Exported `SizeResult` interface; added type annotations for `let` variables; added JSDoc for `convertScanType()` and `convertToScanType()`.
- **TorchState enum**: Named values `off`/`on` (lowercase) to match Dart `TorchState` naming convention.

## 6.0.2-ohos-1.0.0-beta.1

### OHOS Adaptation Initialization

- Initial OHOS platform adaptation for `mobile_scanner` based on `br_v6.0.2_ohos` branch.
- Integrated ScanKit for barcode scanning on OpenHarmony devices.
- Implemented basic camera lifecycle management (start, stop, switch camera).
- Added camera permission request flow for OpenHarmony.
- Implemented `MobileScanner` widget integration with OHOS texture rendering.
- Added torch (flashlight) control support.
- Implemented `analyzeImage` for local image barcode detection.
- Added zoom scale control support.
- Implemented barcode detection with configurable format support.
- Added event channel for barcode result publishing.
- Configured OHOS plugin class registration in `pubspec.yaml`.