> 模板版本: v0.0.1

<p align="center">
  <h1 align="center"> <code>mobile_scanner</code> </h1>
</p>

本项目基于 [mobile_scanner@6.0.2](https://pub.dev/packages/mobile_scanner/versions/6.0.2) 开发。


## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

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

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例

使用案例详见 [ohos/example](https://gitcode.com/openharmony-sig/fluttertpc_mobile_scanner/blob/br_v6.0.2_ohos/example/lib/main.dart)


## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.7.12-ohos-1.0.6; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;
2. Flutter: 3.22.1-ohos-1.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 5.0.13.200; ROM: 5.1.0.120 SP3;


## 3. 属性

> [!TIP] "Platform"列表示该属性在原三方库上支持的平台。

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标iOS 或 Android 的效果。

### MobileScannerController

| Name                 | Description        | Type                 | Required | Platform | ohos Support |
|----------------------|--------------------|----------------------|----------|----------|--------------|
| facing               | 选择相机               | CameraFacing         | no       | all      | no           |
| torchEnabled         | 开启或者关闭闪光灯          | bool                 | no       | all      | yes          |
| returnImage          | 扫码成功时返回图像缓冲区       | bool                 | no       | all      | yes          |
| formats              | 码制式格式              | List<BarcodeFormat>? | no       | all      | yes          |
| detectionTimeoutMs   | 设置扫码超时时间，单位毫秒      | int                  | no       | all      | no           |
| autoStart            | 初始化时自动启动扫码服务       | bool                 | no       | all      | yes          |
| cameraResolution     | 相机分辨率              | Size                 | no       | android  | no           |
| useNewCameraSelector | 使用新的分辨率选择器         | bool                 | no       | android  | no           |
| detectionSpeed       | 设置扫码检测速度           | DetectionSpeed       | no       | all      | no           |

### Parameters

| Name      | Description                                                        | Type    | Required | Platform | ohos Support |
|-----------|--------------------------------------------------------------------|---------|----------|----------|--------------|
| window    | 扫码框大小                                                           | Rect?   | no       | all      | yes          |
| zoomScale | 相机变焦比必须在 0.0 和 1.0 之间，其中 1.0 为最大缩放，0.0 为缩小           | double? | no       | all      | yes          |
| path      | 本地图像文件路径                                                      | String? | no       | all      | yes          |


## 4. API

> [!TIP] "Platform"列表示该属性在原三方库上支持的平台。

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标iOS 或 Android 的效果。

| Name             | Description | Type     | Required | Platform    | ohos Support |
|------------------|-------------|----------|----------|-------------|--------------|
| start            | 开始扫码服务      | function | no       | ios,android | yes          |
| toggleTorch      | 开启或者关闭相机闪光灯 | function | no     | ios,android | yes          |
| stop             | 停止扫码服务      | function | no       | ios,android | yes          |
| analyzeImage     | 识别本地图像文件    | function | no       | ios,android | yes          |
| setZoomScale     | 设置相机变焦比     | function | no       | ios,android | yes          |
| resetZoomScale   | 重置相机变焦比为1   | function | no       | ios,android | yes          |
| updateScanWindow | 更新扫码框大小     | function | no       | ios,android | yes          |
| switchCamera     | 切换摄像头       | function | no       | ios,android | yes          |


## 5. 遗留问题


## 6. 其他


## 7. 开源协议

本项目基于 [The MIT License (MIT)](https://gitcode.com/openharmony-sig/fluttertpc_mobile_scanner/blob/br_v6.0.2_ohos/LICENSE)，请自由地享受和参与开源。
