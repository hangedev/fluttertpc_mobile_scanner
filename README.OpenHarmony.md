> Template version: v0.0.1

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

This project is based on [mobile_scanner](https://pub.dev/packages/mobile_scanner).


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

...
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

For use cases [example](/example/lib/main.dart)


## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;
2. Flutter: 3.22.1-ohos-1.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

### 2.2 Permission Requirements

####  2.2.1 Add permissions to the module.json5 file in the entry directory.

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

#### 2.2.2 Add the reason for applying for the preceding permission to the entry directory.

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


## 3. API

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name               | Description                                                                                                  | Type     | Input                                                                | Output                  | ohos Support |
|--------------------|--------------------------------------------------------------------------------------------------------------|----------|----------------------------------------------------------------------|-------------------------|--------------|
| start              | Start scanning for barcodes                                                                                  | function | {CameraFacing? cameraDirection}                                      | Future<void>            | yes          |
| toggleTorch        | Switches the torch on or off                                                                                 | function | /                                                                    | Future<void>            | yes          |
| stop               | Stops the camera, but does not dispose this controller                                                       | function | /                                                                    | Future<void>            | yes          |
| analyzeImage       | Handles a local image file, returns true if a barcode or QR code is found, returns false if nothing is found | function | String path, {List<BarcodeFormat> formats = const <BarcodeFormat>[]} | Future<BarcodeCapture?> | yes          |
| setZoomScale       | Set the zoomScale of the camera                                                                              | function | double zoomScale                                                     | Future<void>            | yes          |
| resetZoomScale     | Reset the zoomScale of the camera to use standard scale 1x                                                   | function | /                                                                    | Future<void>            | yes          |
| updateScanWindow   | updates the native ScanWindow                                                                                | function | Rect? window                                                         | Future<void>            | yes          |
| switchCamera       | Changes the state of the camera (front or back)                                                              | function | /                                                                    | Future<void>            | yes          |


## 4. Properties

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### MobileScannerController

| Name                 | Description                                                               | Type                 |  ohos Support |
|----------------------|---------------------------------------------------------------------------|----------------------|---------------|
| facing               | Select which camera should be used                                        | CameraFacing         |  no           |
| torchEnabled         | Enable or disable the torch (Flash) on start                              | bool                 |  yes          |
| returnImage          | Set to true if you want to return the image buffer with the Barcode event | bool                 |  yes          |
| formats              | If provided, the scanner will only detect those specific formats          | List<BarcodeFormat>? |  yes          |
| detectionTimeoutMs   | Sets the timeout, in milliseconds, of the scanner                         | int                  |  no           |
| autoStart            | Automatically start the mobileScanner on initialization                   | bool                 |  yes          |
| cameraResolution     | The desired resolution for the camera                                     | Size                 |  no           |
| useNewCameraSelector | Use the new resolution selector                                           | bool                 |  no           |
| detectionSpeed       | Sets the speed of detections                                              | DetectionSpeed       |  no           |

### Parameters

| Name      | Description                                                                  | Type    | ohos Support |
|-----------|------------------------------------------------------------------------------|---------|--------------|
| window    | Scan code box size                                                           | Rect?   | yes          |
| zoomScale | must be within 0.0 and 1.0, where 1.0 is the max zoom, and 0.0 is zoomed out | double? | yes          |
| path      | The path of the image on the devices                                         | String? | yes          |


## 5. Known Issues

- [ ] Custom QR code scanning cannot switch to the front camera: [issue#57](https://gitcode.com/CPF-Flutter/fluttertpc_mobile_scanner/issues/57)

## 6. Others


## 7. License

This project is licensed under [BSD 3-Clause License](/LICENSE).
