> Template version: v0.0.1

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

This project is based on [mobile_scanner@6.0.2](https://pub.dev/packages/mobile_scanner/versions/6.0.2).

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
      url: https://gitcode.com/openharmony-sig/fluttertpc_mobile_scanner.git
      ref: "br_v6.0.2_ohos"
      
...
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

For use cases [ohos/example](https://gitcode.com/openharmony-sig/fluttertpc_mobile_scanner/blob/br_v6.0.2_ohos/example/lib/main.dart)

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;
2. Flutter: 3.22.1-ohos-1.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;

## 3. Properties

> [!TIP] The **Platform** column indicates the platform where the properties are supported in the original third-party library.

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### MobileScannerController

| Name                 | Description                                                               | Type                 | Required | Platform | ohos Support |
|----------------------|---------------------------------------------------------------------------|----------------------|----------|----------|--------------|
| facing               | Select which camera should be used                                        | CameraFacing         | no       | all      | no           |
| torchEnabled         | Enable or disable the torch (Flash) on start                              | bool                 | no       | all      | yes          |
| returnImage          | Set to true if you want to return the image buffer with the Barcode event | bool                 | no       | all      | yes          |
| formats              | If provided, the scanner will only detect those specific formats          | List<BarcodeFormat>? | no       | all      | yes          |
| detectionTimeoutMs   | Sets the timeout, in milliseconds, of the scanner                         | int                  | no       | all      | no           |
| autoStart            | Automatically start the mobileScanner on initialization                   | bool                 | no       | all      | yes          |
| cameraResolution     | The desired resolution for the camera                                     | Size                 | no       | android  | no           |
| useNewCameraSelector | Use the new resolution selector                                           | bool                 | no       | android  | no           |
| detectionSpeed       | Sets the speed of detections                                              | DetectionSpeed       | no       | all      | no           |

### Parameters

| Name      | Description                                                                  | Type    | Required | Platform | ohos Support |
|-----------|------------------------------------------------------------------------------|---------|----------|----------|--------------|
| window    | Scan code box size                                                           | Rect?   | no       | all      | yes          |
| zoomScale | must be within 0.0 and 1.0, where 1.0 is the max zoom, and 0.0 is zoomed out | double? | no       | all      | yes           |
| path      | The path of the image on the devices                                         | String? | no       | all      | yes           |

## 4. API

> [!TIP] The **Platform** column indicates the platform where the properties are supported in the original third-party library.

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

| Name             | Description                                                                                                  | Type     | Required | Platform    | ohos Support |
|------------------|--------------------------------------------------------------------------------------------------------------|----------|----------|-------------|--------------|
| start            | Start scanning for barcodes                                                                                  | function | no       | ios,android | yes          |
| toggleTorch      | Switches the torch on or off                                                                                 | function | no       | ios,android | yes          |
| stop             | Stops the camera, but does not dispose this controller                                                       | function | no       | ios,android | yes          |
| analyzeImage     | Handles a local image file, returns true if a barcode or QR code is found, returns false if nothing is found | function | no       | ios,android | yes          |
| setScale         | Set the zoomScale of the camera                                                                              | function | no       | ios,android | yes          |
| resetScale       | Reset the zoomScale of the camera to use standard scale 1x                                                   | function | no       | ios,android | yes          |
| updateScanWindow | updates the native ScanWindow                                                                                | function | no       | ios,android | yes          |
| switchCamera     | Changes the state of the camera (front or back)                                                              | function | no       | ios,android | yes          |

## 5. Known Issues

## 6. Others

## 7. License

This project is licensed under [The MIT License (MIT)](https://gitcode.com/openharmony-sig/fluttertpc_mobile_scanner/blob/br_v6.0.2_ohos/LICENSE).
