/*
* Copyright (c) 2023 Shenzhen Kaihong Digital Industry Development Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { AbilityAware, AbilityPluginBinding, ByteBuffer } from '@ohos/flutter_ohos/index';
import { AbilityLifecycleCallback, common, UIAbility } from '@kit.AbilityKit';
import { cameraPermission, checkPermissions, requestPermissions } from './CameraPermissions';
import { customScan, scanBarcode, scanCore, detectBarcode } from '@kit.ScanKit';
import EventChannel, { EventSink, StreamHandler } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { Barcode, BarcodeFormat, BarcodeType } from './Barcode';
import { AsyncCallback, BusinessError, Callback } from '@kit.BasicServicesKit';
import { display, window } from '@kit.ArkUI';
import { Point } from '@ohos.UiTest';
import { image } from '@kit.ImageKit';
import { camera } from '@kit.CameraKit';
import { effectKit } from '@kit.ArkGraphics2D';
import sensor from '@ohos.sensor';

const TAG: string = 'MobileScannerPlugin';

enum TorchState {
  off = 0,
  on = 1
}

enum NativeOrientation {
  portraitUp = 'PORTRAIT_UP',
  portraitDown = 'PORTRAIT_DOWN',
  landscapeLeft = 'LANDSCAPE_LEFT',
  landscapeRight = 'LANDSCAPE_RIGHT',
}

enum Angle {
  ZERO = 0,
  PLUS_45 = 45,
  MINUS_45 = -45,
  PLUS_135 = 135,
  MINUS_135 = -135,
}

// 定义接口（推荐）
interface Size {
  width: number;
  height: number;
}

class DeviceOrientationListener implements StreamHandler {
  private eventSink: EventSink | null = null;
  private lastOrientation: NativeOrientation = NativeOrientation.portraitUp;
  private orientationCallback: Callback<sensor.OrientationResponse> | null = null;
  private X: number = 0;
  private Y: number = 0;
  
  constructor() {
  }
  
  onListen(args: Object, eventSink: EventSink): void {
    this.eventSink = eventSink;
    this.start();
  }
  
  onCancel(args: Object): void {
    this.eventSink = null;
    this.stop();
  }

  calculateSensorOrientation(data: sensor.OrientationResponse): NativeOrientation {
    if (!data) {
      return NativeOrientation.portraitUp;
    }
    this.X = data.beta;
    this.Y = data.gamma;
    if ((this.X > Angle.MINUS_135 && this.X < Angle.ZERO) || (this.X >= Angle.ZERO && this.X < Angle.PLUS_45)) {
      if (this.Y <= Angle.PLUS_45 && this.Y >= Angle.MINUS_45) {
        return NativeOrientation.portraitUp;
      }
      if ((this.Y > Angle.MINUS_135 && this.Y < Angle.ZERO)) {
        return NativeOrientation.landscapeRight;
      } else {
        return NativeOrientation.landscapeLeft;
      }
    } else {
      if (this.Y <= Angle.PLUS_45 && this.Y >= Angle.MINUS_45) {
        return NativeOrientation.portraitDown;
      }
      if ((this.Y > Angle.MINUS_135 && this.Y < Angle.ZERO)) {
        return NativeOrientation.landscapeRight;
      } else {
        return NativeOrientation.landscapeLeft;
      }
    }
  }
  
  start(): void {
    // 监听显示方向变化
    this.orientationCallback = (data: sensor.OrientationResponse) => {
      let newOrientation: NativeOrientation = this.calculateSensorOrientation(data);
      if (newOrientation != this.lastOrientation) {
        this.lastOrientation = newOrientation;
        this.eventSink?.success(newOrientation);
      }
    }
    sensor.on(sensor.SensorId.ORIENTATION, this.orientationCallback);
  }

  stop(): void {
    // 移除显示方向变化监听
    if (this.orientationCallback) {
      try {
        sensor.off(sensor.SensorId.ORIENTATION, this.orientationCallback);
        this.orientationCallback = null;
      } catch (error) {
        Log.e(TAG, 'Failed to unregister callback. Code: ' + JSON.stringify(error));
      }
    }
  }
}

class BarcodeEventStreamHandler implements StreamHandler {
  private plugin: MobileScannerPlugin;

  constructor(plugin: MobileScannerPlugin) {
    this.plugin = plugin;
  }

  onListen(args: Object, eventSink: EventSink): void {
    this.plugin.setEventSink(eventSink);
  }

  onCancel(args: Object): void {
    this.plugin.setEventSink(null);
  }
}

class MobileScannerAbilityLifecycleCallback {
  private plugin: MobileScannerPlugin;

  constructor(plugin: MobileScannerPlugin) {
    this.plugin = plugin;
  }

  onAbilityCreate(_ability: UIAbility): void {}

  onAbilityDestroy(_ability: UIAbility): void {}

  onAbilityForeground(_ability: UIAbility): void {
    this.plugin.handleAbilityForeground();
  }

  onAbilityBackground(_ability: UIAbility): void {
    this.plugin.handleAbilityBackground();
  }

  onAbilityContinue(_ability: UIAbility): void {}

  onWindowStageCreate(_ability: UIAbility, _windowStage: window.WindowStage): void {}

  onWindowStageDestroy(_ability: UIAbility, _windowStage: window.WindowStage): void {}

  onWindowStageActive(_ability: UIAbility, _windowStage: window.WindowStage): void {}

  onWindowStageInactive(_ability: UIAbility, _windowStage: window.WindowStage): void {}

  onNewWant(_ability: UIAbility): void {}
}

export class MobileScannerPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  getUniqueClassName(): string {
    return 'MobileScannerPlugin';
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.i(TAG, 'onAttachedToAbility');
    this.ability = binding.getAbility();
    this.registerAbilityLifecycleCallback();
  }

  onDetachedFromAbility(): void {
    Log.i(TAG, 'onDetachedFromAbility');
    this.unregisterAbilityLifecycleCallback();
    this.releaseScannerResources();
    this.ability = null;
  }

  setEventSink(eventSink: EventSink | null): void {
    this.eventSink = eventSink;
  }

  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null
  private applicationContext: common.ApplicationContext | null = null;
  private ability: UIAbility | null = null;
  private textureId: number | null = null;
  private surfaceId: string | null = null;
  private binding: FlutterPluginBinding | null = null;
  private isStart = false;
  private scanWidth: number = 1080 // 单位px
  private scanHeight: number = 1080 // 单位px
  private returnImage: boolean = false;
  private cameraResolutionValues: number[] | undefined = undefined;
  private resolutionRatio = [16/9,4/3,1];   //分辨率比例
  private torch: boolean = false
  private facing: number = 0
  private formats: number[] | undefined = undefined
  private speed: number = 1
  private timeout: number = 250
  private useNewCameraSelector: boolean = false
  private options: scanBarcode.ScanOptions = {};
  private retryScanTimes: number = 0;
  private invertImage: boolean = false;
  private autoZoom: boolean = false;
  private initialZoom: number  = 1;
  private deviceOrientationChannel: EventChannel | null = null;
  private deviceOrientationListener: DeviceOrientationListener | null = null;

  private scanWindow: Array<number> | null = null; // scanWindow，扫描区域
  private imageBuffer: Uint8Array | null = null;
  private isPaused:boolean = false
  private isDetached: boolean = false;
  private retryTimeoutId: number = -1;
  private rescanTimeoutId: number = -1;
  private barcodeEventStreamHandler: BarcodeEventStreamHandler | null = null;
  private scanCallback: AsyncCallback<scanBarcode.ScanResult[]> | null = null;
  private frameCallback: AsyncCallback<customScan.ScanFrame> | null = null;
  private wasScanningBeforeBackground: boolean = false;
  private isCustomScanActive: boolean = false;
  private lifecycleTaskId: number = -1;
  private abilityLifecycleCallbackId: number = -1;
  private abilityLifecycleCallback: MobileScannerAbilityLifecycleCallback | null = null;

  publishEvent(event: ESObject) {
    if (this.isDetached) {
      return;
    }
    this.eventSink?.success(event)
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.isDetached = false;
    this.binding = binding;
    this.methodChannel =
      new MethodChannel(binding.getBinaryMessenger(), 'dev.steenbakker.mobile_scanner/scanner/method');
    this.methodChannel.setMethodCallHandler(this);
    this.eventChannel = new EventChannel(binding.getBinaryMessenger(), 'dev.steenbakker.mobile_scanner/scanner/event');
    this.barcodeEventStreamHandler = new BarcodeEventStreamHandler(this);
    this.eventChannel.setStreamHandler(this.barcodeEventStreamHandler);
    
    // Initialize device orientation channel
    this.deviceOrientationListener = new DeviceOrientationListener();
    this.deviceOrientationChannel = new EventChannel(binding.getBinaryMessenger(), 'dev.steenbakker.mobile_scanner/scanner/deviceOrientation');
    this.deviceOrientationChannel.setStreamHandler(this.deviceOrientationListener);
    
    // texture
    const textureRegistry = binding.getTextureRegistry();
    this.textureId = textureRegistry.getTextureId();
    const surfaceTextureEntry = textureRegistry.registerTexture(this.textureId);
    this.surfaceId = surfaceTextureEntry.getSurfaceId().toString();
    Log.i(TAG, `surfaceId: ${this.surfaceId}`)
  }

  private registerAbilityLifecycleCallback(): void {
    if (this.abilityLifecycleCallbackId >= 0 || !this.ability) {
      return;
    }
    try {
      this.applicationContext = this.ability.context.getApplicationContext();
      this.abilityLifecycleCallback = new MobileScannerAbilityLifecycleCallback(this);
      this.abilityLifecycleCallbackId =
        this.applicationContext.on('abilityLifecycle',
          this.abilityLifecycleCallback as AbilityLifecycleCallback);
    } catch (e) {
      Log.e(TAG, `Failed to register ability lifecycle callback: ${JSON.stringify(e)}`);
    }
  }

  private unregisterAbilityLifecycleCallback(): void {
    if (this.abilityLifecycleCallbackId < 0 || !this.applicationContext) {
      return;
    }
    try {
      this.applicationContext.off('abilityLifecycle', this.abilityLifecycleCallbackId);
    } catch (e) {
      Log.e(TAG, `Failed to unregister ability lifecycle callback: ${JSON.stringify(e)}`);
    }
    this.abilityLifecycleCallbackId = -1;
    this.abilityLifecycleCallback = null;
  }

  handleAbilityBackground(): void {
    this.scheduleLifecycleTask(() => {
      this.doAbilityBackground();
    });
  }

  handleAbilityForeground(): void {
    this.scheduleLifecycleTask(() => {
      this.doAbilityForeground();
    }, 100);
  }

  private scheduleLifecycleTask(task: () => void, delayMs: number = 0): void {
    if (this.lifecycleTaskId >= 0) {
      clearTimeout(this.lifecycleTaskId);
    }
    this.lifecycleTaskId = setTimeout(() => {
      this.lifecycleTaskId = -1;
      task();
    }, delayMs);
  }

  private doAbilityBackground(): void {
    if (this.isDetached || this.isPaused || !this.isStart) {
      return;
    }
    this.wasScanningBeforeBackground = true;
    this.safeReleaseCustomScan();
  }

  private doAbilityForeground(): void {
    if (this.isDetached) {
      return;
    }
    const shouldResume = this.wasScanningBeforeBackground;
    this.wasScanningBeforeBackground = false;
    if (!shouldResume) {
      return;
    }
    // Camera was already released when entering background; restart only.
    if (this.startCamera()) {
      this.isStart = true;
      this.isPaused = false;
    } else {
      Log.e(TAG, 'Failed to resume scanner on foreground');
      this.isStart = false;
    }
  }

  private safeReleaseCustomScan(): void {
    if (!this.isCustomScanActive) {
      this.isStart = false;
      this.imageBuffer = null;
      return;
    }
    if (this.rescanTimeoutId >= 0) {
      clearTimeout(this.rescanTimeoutId);
      this.rescanTimeoutId = -1;
    }
    try {
      customScan.stop();
    } catch (e) {
      Log.e(TAG, `Failed to stop customScan: ${JSON.stringify(e)}`);
    }
    try {
      customScan.release();
    } catch (e) {
      Log.e(TAG, `Failed to release customScan: ${JSON.stringify(e)}`);
    }
    this.isCustomScanActive = false;
    this.isStart = false;
    this.imageBuffer = null;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.isDetached = true;
    if (this.lifecycleTaskId >= 0) {
      clearTimeout(this.lifecycleTaskId);
      this.lifecycleTaskId = -1;
    }
    this.unregisterAbilityLifecycleCallback();
    this.releaseScannerResources();
    this.eventSink = null;
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
    this.eventChannel?.setStreamHandler(null);
    this.eventChannel = null;
    this.barcodeEventStreamHandler = null;

    this.deviceOrientationChannel?.setStreamHandler(null);
    this.deviceOrientationListener?.stop();
    this.deviceOrientationChannel = null;
    this.deviceOrientationListener = null;

    this.scanWindow = null;
    this.imageBuffer = null;
    this.applicationContext = null;
    this.binding = null;
    if (this.textureId !== null) {
      binding.getTextureRegistry().unregisterTexture(this.textureId);
    }
    this.textureId = null;
    this.surfaceId = null;
  }

  private releaseScannerResources(): void {
    if (this.retryTimeoutId >= 0) {
      clearTimeout(this.retryTimeoutId);
      this.retryTimeoutId = -1;
    }
    if (this.rescanTimeoutId >= 0) {
      clearTimeout(this.rescanTimeoutId);
      this.rescanTimeoutId = -1;
    }
    if (this.isCustomScanActive) {
      try {
        customScan.stop();
      } catch (e) {
        Log.e(TAG, `Failed to stop customScan: ${JSON.stringify(e)}`);
      }
      try {
        customScan.release();
      } catch (e) {
        Log.e(TAG, `Failed to release customScan: ${JSON.stringify(e)}`);
      }
    }
    this.isCustomScanActive = false;
    this.isStart = false;
    this.isPaused = false;
    this.wasScanningBeforeBackground = false;
    this.imageBuffer = null;
    this.clearCallbacks();
  }

  private clearCallbacks(): void {
    this.scanCallback = null;
    this.frameCallback = null;
  }

  private initCallbacks(): void {
    if (this.scanCallback && this.frameCallback) {
      return;
    }
    this.scanCallback = async (error: BusinessError, result: scanBarcode.ScanResult[]) => {
      if (this.isDetached) {
        return;
      }
      if (error && error.code) {
        Log.e(TAG, `Failed to get ScanResult by callback. Code: ${error.code}, message: ${error.message}`);
        this.retryCamera(error);
        return;
      }
      const barcodes: Barcode[] = result.map(item => this.buildBarcodeFromScanResult(item));
      this.callback(barcodes, this.imageBuffer, this.scanWidth, this.scanHeight);
    };
    this.frameCallback = async (error: BusinessError, frameResult: customScan.ScanFrame) => {
      if (this.isDetached) {
        return;
      }
      this.imageBuffer = null;
      if (error) {
        Log.e(TAG, `Failed to get ScanFrame by callback. Code: ${error.code}, message: ${error.message}`);
        return;
      }
      if (frameResult && this.returnImage) {
        let imageResource: image.ImageSource | null = null;
        let pixelMap: image.PixelMap | null = null;
        let packer: image.ImagePacker | null = null;
        try {
          const eventWidth = frameResult.width;
          const eventHeight = frameResult.height;
          let sourcePotions: image.SourceOptions = {
            sourceDensity: 120,
            sourcePixelFormat: image.PixelMapFormat.NV21,
            sourceSize: { height: eventHeight, width: eventWidth }
          }
          imageResource = image.createImageSource(frameResult.byteBuffer, sourcePotions);
          let opts: image.InitializationOptions = {
            editable: true,
            pixelFormat: image.PixelMapFormat.RGBA_8888,
            size: { height: eventHeight, width: eventWidth }
          }
          pixelMap = await imageResource.createPixelMap(opts);
          pixelMap.rotateSync(camera.ImageRotation.ROTATION_90);
          if (this.invertImage) {
            const filter = effectKit.createEffect(pixelMap);
            if (filter) {
              filter.invert();
              const effectPixelMap = await filter.getEffectPixelMap();
              pixelMap.release();
              pixelMap = effectPixelMap;
            }
          }
          packer = image.createImagePacker();
          let packingOpt: image.PackingOption = { format: 'image/jpeg', quality: 100 };
          let imgBuffer = await packer.packing(pixelMap, packingOpt);
          this.imageBuffer = new Uint8Array(imgBuffer);
        } catch (e) {
          Log.e(TAG, `Failed to create imageBuffer: ${JSON.stringify(e)}`);
        } finally {
          packer?.release();
          pixelMap?.release();
          imageResource?.release();
        }
      }
    };
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      if (call.method === 'state') {
        checkPermissions(cameraPermission).then(hasCameraPermission => {
          if (hasCameraPermission) {
            result.success(1)
          } else {
            result.success(2)
          }
        }).catch((error: BusinessError) => {
          result.error(String(error.code), error.message, null);
        });
      } else if (call.method === 'request') {
        if (!this.ability?.context) {
          result.error('MOBILE_SCANNER_GENERIC_ERROR', 'Ability context is not available', null);
          return;
        }
        requestPermissions(this.ability.context, (err, msg) => {
          if (err) {
            result.success(false)
          } else {
            result.success(true)
          }
        });
      } else if (call.method === 'start') {
        this.start(call, result)
      } else if (call.method === 'toggleTorch') {
        this.toggleTorch(call, result)
      } else if (call.method === 'stop') {
        this.stop(call, result)
      } else if (call.method === 'analyzeImage') {
        this.analyzeImage(call, result)
      } else if (call.method === 'setScale') {
        this.setScale(call, result)
      } else if (call.method === 'resetScale') {
        this.resetScale(result)
      } else if (call.method === 'updateScanWindow') {
        this.updateScanWindow(call, result)
      }  else if (call.method === 'pause') {
        this.pause(call, result)
      } else if (call.method === 'setFocus') {
        this.setFocus(call, result)
      } else {
        result.notImplemented()
      }
    } catch (err) {
      result.error('MOBILE_SCANNER_GENERIC_ERROR', err.message, null)
    }
  }

  private validateStartArguments(call: MethodCall, result: MethodResult): boolean {
    this.torch = call.argument('torch') ?? false;
    this.facing = call.argument('facing') ?? 0;
    if (this.facing < 0 || this.facing > 2) {
      result.error('INVALID_ARGUMENT', 'facing must be 0, 1, or 2', null);
      return false;
    }
    this.formats = call.argument('formats');
    this.returnImage = call.argument('returnImage') ?? false;
    this.speed = call.argument('speed') ?? 1;
    if (this.speed < 0 || this.speed > 2) {
      result.error('INVALID_ARGUMENT', 'speed must be between 0 and 2', null);
      return false;
    }
    this.timeout = call.argument('timeout') ?? 250;
    if (this.timeout < 0) {
      result.error('INVALID_ARGUMENT', 'timeout must be greater than or equal to 0', null);
      return false;
    }
    this.cameraResolutionValues = call.argument('cameraResolution');
    this.useNewCameraSelector = call.argument('useNewCameraSelector') ?? false;
    this.autoZoom = call.argument('autoZoom') ?? false;
    this.initialZoom = call.argument('initialZoom') ?? 1;
    if (this.initialZoom < 0 || this.initialZoom > 1) {
      result.error('INVALID_ARGUMENT', 'initialZoom must be between 0.0 and 1.0', null);
      return false;
    }
    this.invertImage = call.argument('invertImage') ?? false;
    return true;
  }

  async start(call: MethodCall, result: MethodResult) {
    if (!this.validateStartArguments(call, result)) {
      return;
    }

    this.scanWindow = null;
    this.retryScanTimes = 0;
    this.isPaused = false;
    let scanTypes = [scanCore.ScanType.ALL]
    if (this.formats) {
      scanTypes = []
      this.formats.forEach((format: number) => {
        let type = Barcode.convertToScanType(format)
        if (type != scanCore.ScanType.FORMAT_UNKNOWN) {
          scanTypes.push(type)
        }
      })
    }
    this.options = {
      scanTypes: scanTypes,
      enableMultiMode: true,
      enableAlbum: true
    }
    try {
      if (!this.startCamera()) {
        this.isStart = false;
        result.error('MOBILE_SCANNER_CAMERA_ERROR', 'Failed to start camera', null);
        return;
      }
      this.isStart = true;
    } catch (e) {
      this.isStart = false;
      result.error('MOBILE_SCANNER_CAMERA_ERROR', `${e.message}`, null);
      return;
    }
    // dart 中接收的 width 和 height 会转换为 double 类型，返回整数会导致异常
    result.success({
      'textureId': this.textureId,
      'size': {
        'width': this.scanWidth,
        'height': this.scanHeight
      },
      'numberOfCameras': 1,
      'currentTorchState': customScan.getFlashLightStatus() ? TorchState.on : TorchState.off,
      'cameraDirection': this.facing,
      'naturalDeviceOrientation': NativeOrientation.portraitUp,
      'sensorOrientation': 90,
      'handlesCropAndRotation': false
    });
  }

  retryCamera(error: BusinessError) {
    if (this.isDetached) {
      return;
    }
    if (this.retryScanTimes < 3 && error.code === scanCore.ScanErrorCode.INTERNAL_ERROR) {
      this.retryScanTimes++;
      if (this.retryTimeoutId >= 0) {
        clearTimeout(this.retryTimeoutId);
      }
      this.retryTimeoutId = setTimeout(async () => {
        this.retryTimeoutId = -1;
        if (this.isDetached) {
          return;
        }
        await this.stop(null, null);
        this.isPaused = false;
        if (this.startCamera()) {
          this.isStart = true;
        } else {
          this.isStart = false;
        }
      }, 100)
    }
  }

  startCamera(): boolean {
    try {
      customScan.init(this.options);
    } catch (e) {
      Log.e(TAG, `Failed to init customScan: ${JSON.stringify(e)}`);
      return false;
    }
    try {
      this.setDisplay();
    } catch (e) {
      Log.e(TAG, `Failed to set display: ${JSON.stringify(e)}`);
      return false;
    }
    if (!this.startScan()) {
      return false;
    }
    try {
      if (this.torch) {
        customScan.openFlashLight();
      } else {
        customScan.closeFlashLight();
      }
      customScan.setZoom(this.initialZoom);
      customScan.setAutoZoomEnabled(this.autoZoom);
    } catch (e) {
      Log.e(TAG, `Failed to configure customScan: ${JSON.stringify(e)}`);
    }
    this.publishEvent({
      name: 'torchState',
      data: customScan.getFlashLightStatus() ? TorchState.on : TorchState.off
    });
    return true;
  }

  startScan(): boolean {
    if (!this.surfaceId) {
      Log.e(TAG, 'surfaceId is null, cannot start scan');
      return false;
    }
    this.initCallbacks();
    if (!this.scanCallback || !this.frameCallback) {
      Log.e(TAG, 'Scan callbacks are not initialized');
      return false;
    }
    try {
      const viewControl: customScan.ViewControl = {
        width: this.scanWidth,
        height: this.scanHeight,
        surfaceId: this.surfaceId,
      };
      customScan.start(viewControl, this.scanCallback, this.frameCallback);
      this.isCustomScanActive = true;
      return true;
    } catch (err) {
      Log.e(TAG, `Failed to start scan: ${err.message}`);
      return false;
    }
  }

  private buildBarcodeFromScanResult(item: scanBarcode.ScanResult, useAnalyzeTransform: boolean = false): Barcode {
    const rect = item.scanCodeRect;
    let size: Size = { width: 0, height: 0 };
    let corners: Point[] = [];
    if (useAnalyzeTransform && item.cornerPoints != undefined && item.cornerPoints != null) {
      const cornerPoints = item.cornerPoints;
      corners = [
        { x: this.ensureDouble(this.scanWidth - cornerPoints[0].y), y: this.ensureDouble(cornerPoints[0].x)},
        { x: this.ensureDouble(this.scanWidth - cornerPoints[1].y), y: this.ensureDouble(cornerPoints[1].x)},
        { x: this.ensureDouble(this.scanWidth - cornerPoints[2].y), y: this.ensureDouble(cornerPoints[2].x)},
        { x: this.ensureDouble(this.scanWidth - cornerPoints[3].y), y: this.ensureDouble(cornerPoints[3].x)},
      ];
    } else if (rect) {
      corners = [
        { x: this.ensureDouble(rect.left), y: this.ensureDouble(rect.top) } as Point,
        { x: this.ensureDouble(rect.right), y: this.ensureDouble(rect.top) } as Point,
        { x: this.ensureDouble(rect.right), y: this.ensureDouble(rect.bottom) } as Point,
        { x: this.ensureDouble(rect.left), y: this.ensureDouble(rect.bottom) } as Point,
      ];
    }
    if (rect) {
      size = {
        width: this.ensureDouble(rect.right - rect.left),
        height: this.ensureDouble(rect.bottom - rect.top)
      };
    }
    return {
      displayValue: item.originalValue,
      rawValue: item.originalValue,
      format: Barcode.convertScanType(item.scanType),
      type: BarcodeType.unknown,
      corners: corners,
      size: size
    } as Barcode;
  }

  // 竖屏时获取屏幕尺寸，设置预览流全屏示例
  setDisplay() {
    // 以手机为例计算宽高
    let displayClass: display.Display | null = null;
    try {
      displayClass = display.getDefaultDisplaySync();
    } catch (e) {
      Log.e(TAG, `Failed to get default display: ${JSON.stringify(e)}`);
      return;
    }
    if (displayClass !== null) {
      let orientation = displayClass.orientation.valueOf()
      if (!!this.cameraResolutionValues && this.cameraResolutionValues.length >= 2) {
        let width = this.cameraResolutionValues[0];
        let height = this.cameraResolutionValues[1];
        if (orientation === 0 || orientation === 2) {
          let radio = height / width;
          this.scanWidth = this.ensureDouble(px2vp(displayClass.width));
          if (radio <= this.resolutionRatio[2]) {
            this.scanHeight = this.scanWidth;
          }else if (radio <= this.resolutionRatio[1]) {
            this.scanHeight = this.scanWidth * this.resolutionRatio[1];
          }else {
            this.scanHeight = this.scanWidth * this.resolutionRatio[0];
          }
        }else {
          let radio = width / height;
          this.scanHeight = this.ensureDouble(px2vp(displayClass.height));
          if (radio <= this.resolutionRatio[2]) {
            this.scanWidth = this.scanHeight;
          }else if (radio <= this.resolutionRatio[1]) {
            this.scanWidth = this.scanHeight * this.resolutionRatio[1];
          }else {
            this.scanWidth = this.scanHeight * this.resolutionRatio[0];
          }
        }
      }else {
        if (orientation === 0 || orientation === 2) {
          this.scanWidth = this.ensureDouble(px2vp(displayClass.width));
          this.scanHeight = this.scanWidth;
        }else {
          this.scanHeight = this.ensureDouble(px2vp(displayClass.height));
          this.scanWidth = this.scanHeight;
        }
      }
    }
  }

  ensureDouble(number: number): number {
    if (Number.isInteger(number)){
      number += 0.00000000001
    }
    return number;
  }

  async pause(call: MethodCall, result: MethodResult) {
    let force: boolean = call.argument('force') ?? false

    if ((this.isStart && this.isCustomScanActive) || force) {
      if (this.isCustomScanActive) {
        try {
          await customScan.stop();
          await customScan.release();
        } catch (e) {
          Log.e(TAG, `Failed to pause scanner: ${JSON.stringify(e)}`);
          try {
            await customScan.release();
          } catch (releaseError) {
            Log.e(TAG, `Failed to release customScan during pause: ${JSON.stringify(releaseError)}`);
          }
        }
        this.isCustomScanActive = false;
      }
      this.isPaused = true;
      this.isStart = false;
      this.wasScanningBeforeBackground = false;
    }

    result?.success(null)
  }

  async stop(call: MethodCall | null, result: MethodResult | null) {
    let force: boolean = false;
    if (call) {
      force = call.argument('force') ?? false;
    }
    if (this.isStart || this.isPaused || force) {
      this.isPaused = false;
      this.isStart = false;
      this.wasScanningBeforeBackground = false;
      this.imageBuffer = null;
      if (this.rescanTimeoutId >= 0) {
        clearTimeout(this.rescanTimeoutId);
        this.rescanTimeoutId = -1;
      }
      if (this.isCustomScanActive) {
        try {
          await customScan.stop();
          await customScan.release();
        } catch (e) {
          Log.e(TAG, `Failed to stop scanner: ${JSON.stringify(e)}`);
          try {
            await customScan.release();
          } catch (releaseError) {
            Log.e(TAG, `Failed to release customScan: ${JSON.stringify(releaseError)}`);
          }
        }
        this.isCustomScanActive = false;
      }
    }
    result?.success(null)
  }

  toggleTorch(call: MethodCall, result: MethodResult) {
    const light = customScan.getFlashLightStatus();
    if (light) {
      customScan.closeFlashLight()
    } else {
      customScan.openFlashLight()
    }
    this.publishEvent({
      name: 'torchState',
      data: customScan.getFlashLightStatus() ? TorchState.on : TorchState.off
    });
    result.success(null)
  }

  analyzeImage(call: MethodCall, result: MethodResult) {
    let filePath: string = call.argument('filePath')
    if (!filePath || filePath.length === 0) {
      result.error('INVALID_ARGUMENT', 'filePath is required', null);
      return;
    }

    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    }
    let inputImage: detectBarcode.InputImage = { uri: filePath }
    detectBarcode.decode(inputImage, options, (error: BusinessError, scanResult: Array<scanBarcode.ScanResult>) => {
      if (error && error.code) {
        result.error('MOBILE_SCANNER_BARCODE_ERROR', JSON.stringify(error) , null)
        return
      }
      if (scanResult.length == 0) {
        result.success({
          name: 'barcode',
          data: []
        })
        return
      }
      const barcodes: Barcode[] = scanResult.map(item => this.buildBarcodeFromScanResult(item, true));
      result.success({
        name: 'barcode',
        data: barcodes
      })
    })
  }

  setScale(call: MethodCall, result: MethodResult) {
    let zoomValue: number = call.args as number;
    if (zoomValue < 0 || zoomValue > 1) {
      result.error('INVALID_ARGUMENT', 'zoomScale must be between 0.0 and 1.0', null);
      return;
    }
    try {
      customScan.setZoom(zoomValue);
      this.publishEvent({
        name: 'zoomScaleState',
        data: zoomValue
      });
      result.success(null);
    } catch (error) {
      result.error('MOBILE_SCANNER_SET_SCALE_WHEN_STOPPED_ERROR',
        'The zoom scale cannot be changed when the camera is stopped.', null);
    }
  }

  resetScale(result: MethodResult) {
    try {
      customScan.setZoom(this.initialZoom);
      this.publishEvent({
        name: 'zoomScaleState',
        data: this.initialZoom
      });
      result.success(null);
    } catch (error) {
      result.error('MOBILE_SCANNER_SET_SCALE_WHEN_STOPPED_ERROR',
        'The zoom scale cannot be changed when the camera is stopped.', null);
    }
  }

  updateScanWindow(call: MethodCall, result: MethodResult) {
    this.scanWindow = call.argument('rect')
    result.success(null)
  }

  callback(barcodes: Barcode[], image: Uint8Array | null, width: number, height: number) {
    if (this.isDetached) {
      return;
    }
    barcodes = barcodes.filter(barcode => {
      if (this.scanWindow) {
        return this.isBarcodeInScanWindow(barcode);
      } else {
        return true;
      }
    });
    if (barcodes.length == 0 && this.isCustomScanActive) {
      customScan.rescan();
    }

    if(!this.returnImage) {
      image = null
    }

    let imageinfo:ESObject = {
      bytes:image,
      width: width,
      height: height
    }

    this.publishEvent({
      'name': 'barcode',
      'data': barcodes,
      'image': imageinfo
    })

    if (this.rescanTimeoutId >= 0) {
      clearTimeout(this.rescanTimeoutId);
    }
    this.rescanTimeoutId = setTimeout(() => {
      this.rescanTimeoutId = -1;
      if (this.isDetached || !this.isStart || this.isPaused || !this.isCustomScanActive) {
        return;
      }
      try {
        customScan.rescan();
      } catch (err) {
        Log.e(TAG, `Failed to rescan: ${err.message}`)
      }
    }, this.returnImage ? 250 : 100);
  }

  private isBarcodeInScanWindow(barcode: Barcode): boolean {
    const corners = barcode.corners;
    const left = Math.round(this.scanWindow![0] * this.scanWidth);
    const top = Math.round(this.scanWindow![1] * this.scanHeight);
    const right = Math.round(this.scanWindow![2] * this.scanWidth);
    const bottom = Math.round(this.scanWindow![3] * this.scanHeight);
    return corners.reduce((r, item) => r && item.x >= left && item.x <= right && item.y >= top && item.y <= bottom,
      true)
  }

  errorCallback(error: string) {
    this.publishEvent({
      'name': 'error',
      'data': error
    })
  }

  torchCallback(error: BusinessError, bool: boolean) {
    if (error) {
      return;
    }
    this.publishEvent({
      name: 'torchState',
      data: customScan.getFlashLightStatus() ? TorchState.on : TorchState.off
    });
  }

  setFocus(call: MethodCall, result: MethodResult) {
    let x: number = call.argument('dx');
    let y: number = call.argument('dy');
    if (x == null || y == null || x < 0 || x > 1 || y < 0 || y > 1) {
      result.error('MOBILE_SCANNER_INVALID_FOCUS_POINT',
        'The focus coordinates are not valid.', null);
      return;
    }
    try {
      customScan.setFocusPoint({x:x, y:y});
      result.success(null);
    } catch (error) {
      result.error('MOBILE_SCANNER_GENERIC_ERROR', error.message, null);
    }
  }
}
