# CHANGELOG.OpenHarmony.md

## 7.1.4-ohos-1.0.1

### Fixes
- Fixed Advanced Mobile Scanner scan freeze after returning from background (>2s) on OpenHarmony by adding native ability lifecycle handling in MobileScannerPlugin.
- Fixed `start` return value missing `cameraDirection`/`naturalDeviceOrientation`/`handlesCropAndRotation`/`sensorOrientation` fields
- Fixed `hasFlashUnit` stub that always returned `true` — now properly detects flash hardware
- Fixed `setScale` zoom semantics inconsistency (linear scale 0-1 → ratio zoom conversion)
- Fixed `stop` method missing `force` parameter
- Fixed `onDetachedFromEngine` not releasing `customScan` resources
- Fixed memory leak in `frameCallback` where `ImageSource`/`PixelMap`/`ImagePacker` were not released
- Fixed circular reference issue in `scanCallback`/`frameCallback` arrow functions
- Fixed `setFocus` missing parameter range validation
- Fixed async scan errors not propagated to Flutter layer (`errorCallback` not invoked)
- Fixed `Timer` not cancelled in `onDetachedFromEngine`

### Optimizations
- Removed `ESObject` misuse, replaced with concrete type definitions
- Added method return type annotations and variable type annotations
- Fixed naming convention issues (`radio` → `ratio`, `X`/`Y` → `sensorBeta`/`sensorGamma`, etc.)
- Fixed constant naming convention (`cameraPermission` → `CAMERA_PERMISSION`)
- Fixed `TorchState` enum missing `unavailable = -1`
- Removed `useNewCameraSelector` dead code parameter
- Unified void methods to return `null` instead of `true/false`
- Added `setScale`/`setFocus` parameter range validation
- Added null safety checks, reduced `!` force unwrap usage
- Improved `onDetachedFromEngine` resource cleanup (reset all instance variables)

### Documentation
- Created `CHANGELOG.OpenHarmony.md` for OHOS version history
- Updated `README.OpenHarmony_CN.md` version compatibility table (added SDK/IDE/ROM columns)
- Added upgrade migration guide