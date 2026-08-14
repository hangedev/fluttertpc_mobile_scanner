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

// 1. Flutter OHOS framework imports
import {
  FlutterPlugin,
  FlutterPluginBinding,
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, {
  MethodCallHandler,
  MethodResult,
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { AbilityAware, AbilityPluginBinding } from '@ohos/flutter_ohos/index';
import EventChannel, {
  EventSink,
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';

// 2. Kit imports
import { UIAbility } from '@kit.AbilityKit';
import { customScan, scanBarcode, scanCore, detectBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { camera } from '@kit.CameraKit';

// 3. module imports
import common from '@ohos.app.ability.common';

// 4. Local module imports
import {
  CAMERA_PERMISSION,
  checkPermissions,
  requestPermissions,
} from './CameraPermissions';
import { Barcode, BarcodeFormat, BarcodeType, ScanSize, CornerPoint } from './Barcode';
import { hasFlashUnit } from './CameraUtil';

const TAG: string = 'MobileScannerPlugin';

const MAX_RETRY_TIMES: number = 3;
const DEFAULT_SCAN_SIZE: number = 1080;
const DEFAULT_TIMEOUT: number = 250;
const TORCH_UNAVAILABLE: number = -1;
const ZOOM_MIN: number = 0.0;
const ZOOM_MAX: number = 10.0;
const RESOLUTION_RATIOS: number[] = [16 / 9, 4 / 3, 1];
const RETRY_DELAY_MS: number = 100;
const ERROR_ALREADY_STARTED: string = 'MOBILE_SCANNER_ALREADY_STARTED_ERROR';
const ERROR_SET_SCALE_WHEN_STOPPED: string = 'MOBILE_SCANNER_SET_SCALE_WHEN_STOPPED_ERROR';
const ERROR_GENERIC: string = 'MOBILE_SCANNER_GENERIC_ERROR';
const ERROR_BARCODE: string = 'MOBILE_SCANNER_BARCODE_ERROR';
const MAX_RECT_LENGTH: number = 4;

/**
 * Processes camera frames and manages image buffer resources.
 */
class ImageProcessor {
  private _imageBuf: Uint8Array | null = null;

  get imageBuf(): Uint8Array | null {
    return this._imageBuf;
  }

  /**
   * Processes a camera frame to create an image buffer.
   * @param frame - The camera frame to process
   * @returns The image buffer as Uint8Array, or null on failure
   */
  async processFrame(frame: customScan.ScanFrame): Promise<Uint8Array | null> {
    let imgSrc: image.ImageSource | null = null;
    let pixMap: image.PixelMap | null = null;
    let packer: image.ImagePacker | null = null;

    try {
      const fw: number = frame.width;
      const fh: number = frame.height;

      const srcOpts: image.SourceOptions = {
        sourceDensity: 120,
        sourcePixelFormat: image.PixelMapFormat.NV21,
        sourceSize: { height: fh, width: fw },
      };
      imgSrc = image.createImageSource(frame.byteBuffer, srcOpts);

      const initOpts: image.InitializationOptions = {
        editable: true,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        size: { height: fh, width: fw },
      };
      pixMap = await imgSrc.createPixelMap(initOpts);
      pixMap.rotateSync(camera.ImageRotation.ROTATION_90);

      packer = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 100 };
      const buf: ArrayBuffer = await packer.packing(pixMap, packOpts);
      this._imageBuf = new Uint8Array(buf);
      return this._imageBuf;
    } catch (e) {
      Log.e(TAG, 'Failed to create imageBuffer');
      return null;
    } finally {
      this.releaseImageResources(pixMap, packer, imgSrc);
    }
  }

  /**
   * Releases image resources (PixelMap, ImagePacker, ImageSource) in finally block.
   * @param pixMap - The PixelMap to release
   * @param packer - The ImagePacker to release
   * @param imgSrc - The ImageSource to release
   */
  releaseImageResources(
    pixMap: image.PixelMap | null,
    packer: image.ImagePacker | null,
    imgSrc: image.ImageSource | null): void {
    if (pixMap !== null) {
      try { pixMap.release(); } catch (e) { Log.e(TAG, 'Failed to release pixMap: ' + safeString(e)); }
    }
    if (packer !== null) {
      try { packer.release(); } catch (e) { Log.e(TAG, 'Failed to release packer: ' + safeString(e)); }
    }
    if (imgSrc !== null) {
      try { imgSrc.release(); } catch (e) { Log.e(TAG, 'Failed to release imgSrc: ' + safeString(e)); }
    }
  }

  /**
   * Clears the image buffer.
   */
  clearImageBuf(): void {
    this._imageBuf = null;
  }
}

/**
 * Handles camera retry logic with configurable retry limits and timer management.
 */
class RetryHandler {
  private onRetryFn: () => void;
  private onPublishErrorFn: (code: string, message: string) => void;
  private _retryTimes: number = 0;
  private _retryTimer: number | null = null;

  constructor(onRetry: () => void, onPublishError: (code: string, message: string) => void) {
    this.onRetryFn = onRetry;
    this.onPublishErrorFn = onPublishError;
  }

  get retryTimes(): number {
    return this._retryTimes;
  }

  set retryTimes(value: number) {
    this._retryTimes = value;
  }

  /**
   * Retries the camera on internal error, up to MAX_RETRY_TIMES attempts.
   * @param error - The business error that triggered the retry
   */
  retryCamera(error: BusinessError): void {
    if (this._retryTimes >= MAX_RETRY_TIMES) {
      this.onPublishErrorFn(ERROR_BARCODE,
        'Scan failed after ' + MAX_RETRY_TIMES + ' retries: ' + error.message);
      return;
    }
    if (error === null || error === undefined) {
      return;
    }
    if (error.code !== scanCore.ScanErrorCode.INTERNAL_ERROR) {
      this.onPublishErrorFn(ERROR_BARCODE,
        'Scan error (code: ' + error.code + '): ' + error.message);
      return;
    }
    this._retryTimes++;
    Log.i(TAG, 'Retrying camera, attempt ' + this._retryTimes + '/' + MAX_RETRY_TIMES);
    this.cancelRetryTimer();
    this._retryTimer = setTimeout(() => {
      this._retryTimer = null;
      this.onRetryFn();
    }, RETRY_DELAY_MS);
  }

  /**
   * Cancels the retry timer to prevent callback after detach.
   */
  cancelRetryTimer(): void {
    if (this._retryTimer !== null) {
      clearTimeout(this._retryTimer);
      this._retryTimer = null;
    }
  }

  /**
   * Resets the retry state (counter and timer).
   */
  reset(): void {
    this._retryTimes = 0;
    this.cancelRetryTimer();
  }
}

enum TorchState {
  off = 0,
  on = 1,
}

interface EventData {
  name: string;
  data?: Object;
  image?: ImageInfo;
}

interface ImageInfo {
  bytes: Uint8Array | null;
  width: number;
  height: number;
}

interface StartResult {
  textureId: number | null;
  size: ScanSize;
  torchable: boolean;
  numberOfCameras: number;
  currentTorchState: number;
  cameraDirection: number;
}

/**
 * Safely parse a boolean value from an argument.
 * @param val - The value to parse
 * @param def - Default value if parsing fails
 * @returns The parsed boolean or default
 */
function getBoolean(val: Object | null | undefined, def: boolean): boolean {
  if (val === null || val === undefined) {
    return def;
  }
  if (val === true) {
    return true;
  }
  if (val === false) {
    return false;
  }
  return def;
}

/**
 * Safely parse a number value from an argument.
 * @param val - The value to parse
 * @param def - Default value if parsing fails
 * @returns The parsed number or default
 */
function getNumber(val: Object | null | undefined, def: number): number {
  if (val === null || val === undefined) {
    return def;
  }
  const num: number = Number(val);
  if (isNaN(num)) {
    return def;
  }
  return num;
}

/**
 * Safely parse a number array from an argument.
 * @param val - The value to parse
 * @returns The number array or null if parsing fails
 */
function getNumberArray(val: Object | null | undefined): number[] | null {
  if (val === null || val === undefined) {
    return null;
  }
  if (val instanceof Array === false) {
    return null;
  }
  const arr: Object[] = val as Object[];
  const result: number[] = [];
  for (let i: number = 0; i < arr.length; i++) {
    const n: number = Number(arr[i]);
    if (isNaN(n)) {
      return null;
    }
    result.push(n);
  }
  return result;
}

/**
 * Extract a meaningful error message string from any error object.
 * @param err - The error object
 * @returns A human-readable error string
 */
function safeString(err: Object | null | undefined): string {
  if (err === null || err === undefined) {
    return 'Unknown error';
  }
  if (err instanceof Object === false) {
    return String(err);
  }
  const keys: string[] = Object.keys(err);
  const values: Object[] = Object.values(err);
  for (let i: number = 0; i < keys.length; i++) {
    if (keys[i] === 'message') {
      const msg: Object = values[i];
      if (typeof msg === 'string') {
        return msg;
      }
    }
  }
  return String(err);
}

/**
 * Create a CornerPoint from x, y coordinates.
 * @param x - The x coordinate
 * @param y - The y coordinate
 * @returns The CornerPoint object
 */
function makePoint(x: number, y: number): CornerPoint {
  return { x: x, y: y };
}

export class MobileScannerPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  /**
   * Thread model: This plugin runs on the ArkTS UI main thread.
   * ScanKit callbacks (onScanResult_, onFrameResult_) are invoked on the
   * same main thread per ArkTS single-threaded model, so shared state fields
   * (isStart_, isPaused_, isScanReg_) do not require explicit locking.
   * However, the MethodChannel handler and lifecycle callbacks also run on
   * the main thread, so all state access is effectively serialized.
   * If ScanKit behavior changes in future SDK versions, add @Concurrent
   * decorator or atomic operations to protect shared state.
   *
   * Returns the unique class name for this plugin.
   * @returns The class name string
   */
  getUniqueClassName(): string {
    return 'MobileScannerPlugin';
  }

  /**
   * Called when the plugin is attached to an ability.
   * @param binding - The ability plugin binding
   */
  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.i(TAG, 'onAttachedToAbility');
    this._ability = binding.getAbility();
  }

  /**
   * Called when the plugin is detached from an ability.
   * Stops the scan and releases all resources.
   */
  onDetachedFromAbility(): void {
    Log.i(TAG, 'onDetachedFromAbility');
    this._isDetached = true;
    this._cancelRescan();
    try {
      this._retryHandler?.reset();
    } catch (e) {
      Log.e(TAG, 'Failed to reset retryHandler on ability detach: ' + safeString(e));
    }
    if (this._isStart || this._isPaused) {
      try {
        customScan.stop();
      } catch (e) {
        Log.e(TAG, 'Failed to stop on ability detach: ' + safeString(e));
      }
      try {
        customScan.release();
      } catch (e) {
        Log.e(TAG, 'Failed to release on ability detach: ' + safeString(e));
      }
    }
    this._isStart = false;
    this._isPaused = false;
    this._isScanReg = false;
    this._scanResultCallback = null;
    this._frameResultCallback = null;
    this._ability = null;
  }

  private _methodChannel: MethodChannel | null = null;
  private _eventChannel: EventChannel | null = null;
  private _eventSink: EventSink | null = null;
  private _appContext: Context | null = null;
  private _ability: UIAbility | null = null;
  private _textureId: number | null = null;
  private _surfaceId: string | null = null;
  private _binding: FlutterPluginBinding | null = null;
  private _isStart: boolean = false;
  private _scanWidth: number = DEFAULT_SCAN_SIZE;
  private _scanHeight: number = DEFAULT_SCAN_SIZE;
  private _returnImage: boolean = false;
  private _cameraResValues: number[] | null = null;
  private _torch: boolean = false;
  private _formats: number[] | null = null;
  private _timeout: number = DEFAULT_TIMEOUT;
  private _scanOptions: scanBarcode.ScanOptions | null = null;
  private _scanWindow: Array<number> | null = null;
  private _imageProcessor: ImageProcessor = new ImageProcessor();
  private _isPaused: boolean = false;
  private _isScanReg: boolean = false;
  private _isDetached: boolean = false;
  private _rescanTimer: number | null = null;
  private _scanResultCallback: ((error: BusinessError, result: scanBarcode.ScanResult[]) => void) | null = null;
  private _frameResultCallback: ((error: BusinessError, frame: customScan.ScanFrame) => void) | null = null;
  private _retryHandler: RetryHandler | null = new RetryHandler(
    (): void => { this.startCamera(); },
    (code: string, message: string): void => { this.publishError(code, message); }
  );

  /**
   * Publishes an event to the Flutter side via the event channel.
   * For error events, use publishError() to send via EventSink.error().
   * @param event - The event data to publish
   */
  publishEvent(event: EventData): void {
    const sink: EventSink | null = this._eventSink;
    if (sink !== null) {
      try {
        sink.success(event);
      } catch (e) {
        Log.e(TAG, 'Failed to publish event: ' + safeString(e));
      }
    }
  }

  /**
   * Publishes an error event to the Flutter side via EventSink.error().
   * This ensures the Dart side can receive and distinguish error events.
   * @param code - The error code
   * @param message - The error message
   */
  private publishError(code: string, message: string): void {
    const sink: EventSink | null = this._eventSink;
    if (sink !== null) {
      try {
        sink.error(code, message, null);
      } catch (e) {
        Log.e(TAG, 'Failed to publish error: ' + safeString(e));
      }
    }
  }

  /**
   * Registers the camera preview texture lazily when scanning starts.
   * Avoids native initialization during engine attach before user consent.
   * @returns true when the texture is available, false on failure (logged, no throw).
   */
  private _registerTexture(): boolean {
    if (this._textureId !== null) {
      Log.d(TAG, 'Texture already registered, textureId: ' + this._textureId);
      return true;
    }
    if (this._binding === null) {
      Log.e(TAG, 'Failed to register texture: binding is null');
      return false;
    }
    try {
      const registry = this._binding.getTextureRegistry();
      this._textureId = registry.getTextureId();
      const entry = registry.registerTexture(this._textureId);
      this._surfaceId = entry.getSurfaceId().toString();
      Log.i(TAG, 'surfaceId: ' + this._surfaceId);
      return true;
    } catch (err) {
      Log.e(TAG, 'Failed to register texture: ' + safeString(err));
      this._textureId = null;
      this._surfaceId = null;
      return false;
    }
  }

  /**
   * Called when the plugin is attached to the Flutter engine.
   * Initializes method channel and event channel only.
   * Texture registration is deferred until start() is called.
   * @param binding - The Flutter plugin binding
   */
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this._binding = binding;
    this._appContext = binding.getApplicationContext();

    this._methodChannel = new MethodChannel(
      binding.getBinaryMessenger(),
      'dev.steenbakker.mobile_scanner/scanner/method',
    );
    this._methodChannel.setMethodCallHandler(this);

    this._eventChannel = new EventChannel(
      binding.getBinaryMessenger(),
      'dev.steenbakker.mobile_scanner/scanner/event',
    );
    this._eventChannel.setStreamHandler({
      onListen: (args: Object, sink: EventSink) => {
        this._eventSink = sink;
      },
      onCancel: () => {
        this._eventSink = null;
      },
    });
  }

  /**
   * Called when the plugin is detached from the Flutter engine.
   * Releases all resources and cleans up references.
   * @param binding - The Flutter plugin binding
   */
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    // Set the detached flag to prevent processing after detach
    this._isDetached = true;

    // Stop the scan service with fallback
    if (this._isStart || this._isPaused) {
      try {
        customScan.stop();
      } catch (e) {
        Log.e(TAG, 'Failed to stop scan on detach: ' + safeString(e));
      }
      try {
        customScan.release();
      } catch (e) {
        Log.e(TAG, 'Failed to release scan on detach: ' + safeString(e));
      }
    }

    // Cancel the rescan and retry timers
    this._cancelRescan();
    try {
      this._retryHandler?.reset();
    } catch (e) {
      Log.e(TAG, 'Failed to reset retryHandler on engine detach: ' + safeString(e));
    }

    // Clear all references
    this._eventSink = null;
    this._appContext = null;
    if (this._methodChannel !== null) {
      this._methodChannel.setMethodCallHandler(null);
      this._methodChannel = null;
    }
    if (this._eventChannel !== null) {
      this._eventChannel.setStreamHandler(null);
      this._eventChannel = null;
    }
    this._isStart = false;
    this._isPaused = false;
    this._isScanReg = false;
    this._scanWindow = null;
    this._imageProcessor.clearImageBuf();

    // Unregister the texture
    if (this._textureId !== null) {
      binding.getTextureRegistry().unregisterTexture(this._textureId);
    }
    this._textureId = null;
    this._surfaceId = null;
    this._binding = null;
    this._ability = null;
    this._formats = null;
    this._scanResultCallback = null;
    this._frameResultCallback = null;
    this._cameraResValues = null;
    this._scanOptions = null;
    this._retryHandler = null;
  }

  /**
   * Handles incoming method calls from the Flutter side.
   * @param call - The method call
   * @param result - The method result callback
   */
  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      switch (call.method) {
        case 'state':
          this._handleState(result);
          break;
        case 'request':
          this._handleRequest(result);
          break;
        case 'start':
          await this.start(call, result);
          break;
        case 'toggleTorch':
          this.toggleTorch(result);
          break;
        case 'stop':
          await this.stop(call, result);
          break;
        case 'analyzeImage':
          this.analyzeImage(call, result);
          break;
        case 'setScale':
          this.setScale(call, result);
          break;
        case 'resetScale':
          this.resetScale(result);
          break;
        case 'updateScanWindow':
          this.updateScanWindow(call, result);
          break;
        case 'pause':
          await this.pause(call, result);
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (err) {
      result.error(ERROR_GENERIC, safeString(err), null);
    }
  }

  /**
   * Handles the 'state' method call - checks camera permission state.
   * @param result - The method result callback
   */
  private _handleState(result: MethodResult): void {
    checkPermissions(CAMERA_PERMISSION)
      .then((granted: boolean) => {
        result.success(granted ? 1 : 2);
      })
      .catch((error: BusinessError) => {
        result.error(ERROR_GENERIC, error.message, null);
      });
  }

  /**
   * Handles the 'request' method call - requests camera permission.
   * @param result - The method result callback
   */
  private _handleRequest(result: MethodResult): void {
    const ability: UIAbility | null = this._ability;
    if (ability === null) {
      result.error(ERROR_GENERIC, 'Ability is null, cannot request permissions', null);
      return;
    }
    requestPermissions(ability.context, (errCode: string | null, errDesc: string | null) => {
      if (errCode === null) {
        result.success(true);
      } else if (errCode === 'ERR_PERMISSION_DENIED') {
        result.success(false);
      } else {
        result.error(ERROR_GENERIC, errDesc ?? errCode, null);
      }
    });
  }

  /**
   * Starts the camera and barcode scanning service.
   * @param call - The method call containing start parameters
   * @param result - The method result callback
   * @returns Promise that resolves when the camera starts.
   * On success, result.success() returns a StartResult object with
   * textureId, size, torchable, numberOfCameras, and currentTorchState.
   */
  async start(call: MethodCall, result: MethodResult): Promise<void> {
    if (this._binding === null) {
      result.error(ERROR_GENERIC, 'Plugin not attached to engine', null);
      return;
    }

    if (this._isStart) {
      result.error(ERROR_ALREADY_STARTED,
        'The scanner was already started.', null);
      return;
    }

    try {
      this._parseStartOptions(call);
      const textureRegistered: boolean = this._registerTexture();
      if (!textureRegistered) {
        Log.w(TAG, 'Texture registration failed, camera preview will be unavailable');
      }
      this.startCamera();
      this._isStart = true;
      result.success(this._buildStartResult());
    } catch (err) {
      this._isStart = false;
      this._releaseOnError();
      Log.e(TAG, 'Failed to start scan: ' + safeString(err));
      result.error(ERROR_GENERIC, safeString(err), null);
    }
  }

  /**
   * Parses start options from the method call arguments.
   * @param call - The method call containing start parameters
   */
  private _parseStartOptions(call: MethodCall): void {
    this._torch = getBoolean(call.argument('torch'), false);
    this._formats = getNumberArray(call.argument('formats'));
    this._returnImage = getBoolean(call.argument('returnImage'), false);
    const facing: number = getNumber(call.argument('facing'), 1);
    if (facing === 0) {
      Log.w(TAG, 'Front camera is not supported on OHOS, using back camera');
    }
    this._timeout = getNumber(call.argument('timeout'), DEFAULT_TIMEOUT);
    this._cameraResValues = getNumberArray(call.argument('cameraResolution'));
    this._scanWindow = null;
    this._retryHandler?.reset();

    this._scanOptions = {
      scanTypes: this._buildScanTypes(this._formats),
      enableMultiMode: true,
      enableAlbum: true,
    };
  }

  /**
   * Builds the start result object for the Flutter layer.
   * textureId may be null when texture registration failed; Dart side renders an empty preview.
   * @returns The result map with texture and camera info
   */
  private _buildStartResult(): StartResult {
    const ctx: common.BaseContext | null = this._appContext;
    const hasTorch: boolean = ctx !== null ? hasFlashUnit(ctx) : false;
    return {
      'textureId': this._textureId,
      'size': {
        'width': this._scanWidth,
        'height': this._scanHeight,
      },
      'torchable': hasTorch,
      'numberOfCameras': 1,
      'currentTorchState': hasTorch
        ? (customScan.getFlashLightStatus() ? TorchState.on : TorchState.off)
        : TORCH_UNAVAILABLE,
      'cameraDirection': 1, // OHOS only supports back camera (1 = CameraFacing.back)
    };
  }

  /**
   * Releases customScan resources on start error.
   * Prevents resource leak when isStart_=false but customScan is still running.
   */
  private _releaseOnError(): void {
    if (this._isScanReg) {
      try {
        customScan.stop();
        customScan.release();
      } catch (releaseErr) {
        Log.e(TAG, 'Failed to release on start error: ' + safeString(releaseErr));
      }
      this._isScanReg = false;
    }
  }

  /**
   * Builds a list of ScanKit ScanType values from BarcodeFormat numbers.
   * @param formats - The barcode format numbers
   * @returns Array of ScanType values
   */
  private _buildScanTypes(formats: number[] | null): Array<scanCore.ScanType> {
    if (formats === null || formats.length === 0) {
      return [scanCore.ScanType.ALL];
    }
    const types: scanCore.ScanType[] = [];
    for (let i: number = 0; i < formats.length; i++) {
      const t: scanCore.ScanType = Barcode.convertToScanType(formats[i]);
      if (t !== scanCore.ScanType.FORMAT_UNKNOWN) {
        types.push(t);
      }
    }
    if (types.length === 0) {
      return [scanCore.ScanType.ALL];
    }
    return types;
  }

  /**
   * Retries the camera on internal error, delegating to the RetryHandler.
   * @param error - The business error that triggered the retry
   */
  retryCamera(error: BusinessError): void {
    this._retryHandler?.retryCamera(error);
  }

  /**
   * Initializes and starts the camera stream.
   * Sets up the display, registers callbacks, and configures the torch.
   */
  startCamera(): void {
    try {
      this._releaseExistingScan();
      if (this._scanOptions === null) {
        Log.e(TAG, 'ScanOptions is null, cannot start camera');
        throw new Error('ScanOptions is null, cannot start camera');
      }
      customScan.init(this._scanOptions);
      this._isScanReg = true;
      this._setDisplay();
      this.startScan();
      this._configureTorch();
    } catch (err) {
      Log.e(TAG, 'Failed to start camera: ' + safeString(err));
      this._releaseScanReg();
      throw new Error(safeString(err));
    }
  }

  /**
   * Releases any existing scan registration before re-initializing.
   */
  private _releaseExistingScan(): void {
    if (this._isScanReg) {
      try {
        customScan.release();
      } catch (e) {
        Log.e(TAG, 'Failed to release existing scan: ' + safeString(e));
      }
      this._isScanReg = false;
    }
  }

  /**
   * Releases the scan registration and logs any error.
   */
  private _releaseScanReg(): void {
    if (this._isScanReg) {
      try {
        customScan.release();
      } catch (releaseErr) {
        Log.e(TAG, 'Failed to release on startCamera error: ' + safeString(releaseErr));
      }
    }
    this._isScanReg = false;
  }

  /**
   * Configures the torch (flashlight) based on current settings.
   */
  private _configureTorch(): void {
    if (this._torch) {
      customScan.openFlashLight();
    } else {
      customScan.closeFlashLight();
    }
    this.publishEvent({
      name: 'torchState',
      data: customScan.getFlashLightStatus() ? TorchState.on : TorchState.off,
    });
  }

  /**
   * Converts a ScanKit ScanResult to a Barcode object.
   * @param item - The ScanKit scan result
   * @returns The converted Barcode object
   */
  private _convertResult(item: scanBarcode.ScanResult): Barcode {
    const rect = item.scanCodeRect;
    let w: number = 0;
    let h: number = 0;
    const corners: CornerPoint[] = [];

    if (rect !== null && rect !== undefined) {
      w = this.toDouble(rect.right - rect.left);
      h = this.toDouble(rect.bottom - rect.top);
      corners.push(makePoint(this.toDouble(rect.left), this.toDouble(rect.top)));
      corners.push(makePoint(this.toDouble(rect.right), this.toDouble(rect.top)));
      corners.push(makePoint(this.toDouble(rect.right), this.toDouble(rect.bottom)));
      corners.push(makePoint(this.toDouble(rect.left), this.toDouble(rect.bottom)));
    }

    const bc: Barcode = new Barcode();
    bc.displayValue = item.originalValue;
    bc.rawValue = item.originalValue;
    bc.format = Barcode.convertScanType(item.scanType);
    bc.type = BarcodeType.unknown;
    bc.corners = corners;
    bc.size = { width: w, height: h };
    return bc;
  }

  /**
   * Callback for scan results from ScanKit.
   * @param error - Business error if any
   * @param result - Array of scan results
   */
  private _onScanResult(error: BusinessError, result: scanBarcode.ScanResult[]): void {
    try {
      // Skip processing if the plugin has been detached
      if (this._isDetached) {
        return;
      }
      if (error !== null && error !== undefined) {
        Log.e(TAG, 'ScanResult error. Code: ' + error.code + ', message: ' + error.message);
        this.retryCamera(error);
        return;
      }
      if (result === null || result === undefined) {
        return;
      }
      const barcodes: Barcode[] = [];
      for (let i: number = 0; i < result.length; i++) {
        barcodes.push(this._convertResult(result[i]));
      }
      this.callback(barcodes, this._imageProcessor.imageBuf, this._scanWidth, this._scanHeight);
    } catch (e) {
      Log.e(TAG, 'Unhandled exception in onScanResult_: ' + safeString(e));
      this.publishError(ERROR_BARCODE, 'Scan result processing failed: ' + safeString(e));
    }
  }

  /**
   * Callback for camera frame results from ScanKit.
   * @param error - Business error if any
   * @param frame - The camera frame data
   */
  private async _onFrameResult(error: BusinessError, frame: customScan.ScanFrame): Promise<void> {
    try {
      // Skip frame processing if the plugin has been detached
      if (this._isDetached) {
        return;
      }
      this._imageProcessor.clearImageBuf();
      if (error !== null && error !== undefined) {
        Log.e(TAG, 'Frame error. Code: ' + error.code + ', message: ' + error.message);
        this.publishError(ERROR_GENERIC, 'Frame processing error: ' + error.message);
        return;
      }
      if (frame !== null && frame !== undefined && this._returnImage) {
        await this._imageProcessor.processFrame(frame);
      }
    } catch (e) {
      Log.e(TAG, 'Unhandled exception in onFrameResult_: ' + safeString(e));
      this.publishError(ERROR_GENERIC, 'Frame processing failed: ' + safeString(e));
    }
  }

  /**
   * Starts the barcode scanning with the registered callbacks.
   */
  startScan(): void {
    if (this._surfaceId === null) {
      Log.e(TAG, 'Failed to start scan: surfaceId is null');
      throw new Error('Camera preview is unavailable');
    }
    try {
      const vc: customScan.ViewControl = {
        width: this._scanWidth,
        height: this._scanHeight,
        surfaceId: this._surfaceId,
      };
      // 清除旧回调引用，再创建新回调，避免闭包累积
      this._scanResultCallback = null;
      this._frameResultCallback = null;
      this._scanResultCallback = this._onScanResult.bind(this);
      this._frameResultCallback = this._onFrameResult.bind(this);
      customScan.start(vc, this._scanResultCallback, this._frameResultCallback);
      this._isScanReg = true;
    } catch (err) {
      Log.e(TAG, 'Failed to start scan: ' + safeString(err));
      throw new Error(safeString(err));
    }
  }

  /**
   * Sets the display size based on screen dimensions and resolution.
   * Uses width/height comparison instead of display orientation API
   * to avoid accessing sensor-related orientation data.
   */
  private _setDisplay(): void {
    try {
      const dc: display.Display = display.getDefaultDisplaySync();
      if (dc === null) {
        return;
      }

      const portrait: boolean = dc.width < dc.height;

      if (this._cameraResValues !== null && this._cameraResValues.length >= 2) {
        const rw: number = this._cameraResValues[0];
        const rh: number = this._cameraResValues[1];
        const ratio: number = portrait ? (rh / rw) : (rw / rh);
        const scale: number = this._pickScale(ratio);

        if (portrait) {
          this._scanWidth = this.toDouble(px2vp(dc.width));
          this._scanHeight = this._scanWidth * scale;
        } else {
          this._scanHeight = this.toDouble(px2vp(dc.height));
          this._scanWidth = this._scanHeight * scale;
        }
      } else {
        if (portrait) {
          this._scanWidth = this.toDouble(px2vp(dc.width));
          this._scanHeight = this._scanWidth;
        } else {
          this._scanHeight = this.toDouble(px2vp(dc.height));
          this._scanWidth = this._scanHeight;
        }
      }
    } catch (err) {
      Log.e(TAG, 'Failed to set display: ' + safeString(err));
      throw new Error('Failed to configure display size: ' + safeString(err));
    }
  }

  /**
   * Picks the resolution scale factor based on aspect ratio.
   * @param ratio - The aspect ratio
   * @returns The scale factor
   */
  private _pickScale(ratio: number): number {
    if (ratio <= RESOLUTION_RATIOS[2]) {
      return 1;
    }
    if (ratio <= RESOLUTION_RATIOS[1]) {
      return RESOLUTION_RATIOS[1];
    }
    return RESOLUTION_RATIOS[0];
  }

  /**
   * Converts a number to a non-integer double value.
   * Dart expects double values for width/height, integers cause exceptions.
   * @param value - The input number
   * @returns A non-integer double value
   */
  toDouble(value: number): number {
    if (Number.isInteger(value)) {
      return value + 1e-11;
    }
    return value;
  }

  /**
   * Pauses the barcode scanning (lightweight, keeps resources).
   * @param call - The method call
   * @param result - The method result callback
   */
  async pause(call: MethodCall, result: MethodResult): Promise<void> {
    const force: boolean = getBoolean(call.argument('force'), false);

    if (this._isStart || force) {
      try {
        await customScan.stop();
        this._isPaused = true;
        result.success(null);
      } catch (e) {
        Log.e(TAG, 'Failed to pause scan: ' + safeString(e));
        result.error(ERROR_GENERIC, safeString(e), null);
      }
    } else {
      result.success(null);
    }
  }

  /**
   * Stops the barcode scanning and releases resources.
   * @param call - The method call
   * @param result - The method result callback
   */
  async stop(call: MethodCall, result: MethodResult): Promise<void> {
    const force: boolean = getBoolean(call.argument('force'), false);

    if (this._isStart || this._isPaused || force) {
      this._isPaused = false;
      this._isStart = false;
      this._isScanReg = false;
      this._scanResultCallback = null;
      this._frameResultCallback = null;

      try {
        await customScan.stop();
        await customScan.release();
        result.success(null);
      } catch (e) {
        try {
          await customScan.release();
        } catch (inner) {
          Log.e(TAG, 'Failed to release after stop: ' + safeString(inner));
        }
        result.error(ERROR_GENERIC, safeString(e), null);
      }
    } else {
      result.success(null);
    }
  }

  /**
   * Toggles the torch (flashlight) on or off.
   * @param result - The method result callback
   */
  toggleTorch(result: MethodResult): void {
    try {
      const on: boolean = customScan.getFlashLightStatus();
      if (on) {
        customScan.closeFlashLight();
      } else {
        customScan.openFlashLight();
      }
      this.publishEvent({
        name: 'torchState',
        data: customScan.getFlashLightStatus() ? TorchState.on : TorchState.off,
      });
      result.success(null);
    } catch (err) {
      Log.e(TAG, 'Failed to toggle torch: ' + safeString(err));
      result.error(ERROR_GENERIC, safeString(err), null);
    }
  }

  /**
   * Analyzes a local image file for barcodes.
   * @param call - The method call containing filePath and formats
   * @param result - The method result callback
   */
  analyzeImage(call: MethodCall, result: MethodResult): void {
    const filePath: string = call.argument('filePath');

    if (filePath === null || filePath === undefined || filePath.trim() === '') {
      result.error(ERROR_BARCODE, 'filePath must not be empty', null);
      return;
    }

    const formats: number[] = getNumberArray(call.argument('formats')) || [];
    const scanTypes: Array<scanCore.ScanType> = this._buildScanTypes(formats);
    const opts: scanBarcode.ScanOptions = {
      scanTypes: scanTypes,
      enableMultiMode: true,
      enableAlbum: true,
    };

    const input: detectBarcode.InputImage = { uri: filePath };
    detectBarcode.decode(input, opts, (error: BusinessError, scanResult: Array<scanBarcode.ScanResult>) => {
      this._handleDecodeResult(error, scanResult, result);
    });
  }

  /**
   * Handles the barcode decode result from analyzeImage.
   * @param error - The decode error if any
   * @param scanResult - The decoded scan results
   * @param result - The method result callback
   */
  private _handleDecodeResult(
    error: BusinessError,
    scanResult: Array<scanBarcode.ScanResult>,
    result: MethodResult): void {
    if (error !== null && error !== undefined) {
      result.error(ERROR_BARCODE, JSON.stringify(error), null);
      return;
    }
    if (scanResult === null || scanResult === undefined || scanResult.length === 0) {
      result.success(null);
      return;
    }
    const barcodes: Barcode[] = [];
    for (let i: number = 0; i < scanResult.length; i++) {
      barcodes.push(this._convertResult(scanResult[i]));
    }
    result.success({ name: 'barcode', data: barcodes });
  }

  /**
   * Sets the camera zoom scale.
   * @param call - The method call containing zoom value
   * @param result - The method result callback
   */
  setScale(call: MethodCall, result: MethodResult): void {
    const raw: Object | null | undefined = call.args;
    const zoom: number = getNumber(raw, -1);

    if (!this._isStart && !this._isPaused) {
      result.error(ERROR_SET_SCALE_WHEN_STOPPED,
        'The zoom cannot be changed when the scanner is stopped.', null);
      return;
    }
    if (zoom < ZOOM_MIN || zoom > ZOOM_MAX) {
      result.error(ERROR_GENERIC, 'zoomScale must be between 0.0 and 10.0', null);
      return;
    }
    try {
      customScan.setZoom(zoom);
      this.publishEvent({ name: 'zoomScaleState', data: zoom });
      result.success(null);
    } catch (err) {
      result.error(ERROR_GENERIC, safeString(err), null);
    }
  }

  /**
   * Resets the camera zoom scale to 1x.
   * @param result - The method result callback
   */
  resetScale(result: MethodResult): void {
    if (!this._isStart && !this._isPaused) {
      result.error(ERROR_SET_SCALE_WHEN_STOPPED,
        'The zoom cannot be changed when the camera is stopped.', null);
      return;
    }
    try {
      customScan.setZoom(1);
      this.publishEvent({ name: 'zoomScaleState', data: 1.0 });
      result.success(null);
    } catch (err) {
      result.error(ERROR_GENERIC, safeString(err), null);
    }
  }

  /**
   * Updates the scan window (region of interest) for barcode detection.
   * @param call - The method call containing the rect parameter
   * @param result - The method result callback
   */
  updateScanWindow(call: MethodCall, result: MethodResult): void {
    const rect: Array<number> | null = getNumberArray(call.argument('rect'));

    if (rect !== null) {
      if (rect.length !== MAX_RECT_LENGTH) {
        result.error(ERROR_GENERIC, 'rect must be an array of 4 numbers', null);
        return;
      }
      for (let i: number = 0; i < rect.length; i++) {
        if (rect[i] < 0 || rect[i] > 1) {
          result.error(ERROR_GENERIC, 'rect values must be between 0 and 1', null);
          return;
        }
      }
    }
    this._scanWindow = rect;
    result.success(null);
  }

  /**
   * Processes barcode detection results and publishes them to Flutter.
   * @param barcodes - The detected barcodes
   * @param image - The image buffer
   * @param width - The image width
   * @param height - The image height
   */
  callback(
    barcodes: Barcode[],
    image: Uint8Array | null,
    width: number,
    height: number,
  ): void {
    let filtered: Barcode[];
    if (this._scanWindow !== null) {
      filtered = [];
      for (let i: number = 0; i < barcodes.length; i++) {
        if (this._inWindow(barcodes[i])) {
          filtered.push(barcodes[i]);
        }
      }
    } else {
      filtered = barcodes;
    }

    if (filtered.length === 0) {
      try {
        customScan.rescan();
      } catch (err) {
        Log.e(TAG, 'Failed to rescan: ' + safeString(err));
      }
      return;
    }

    this._cancelRescan();

    const info: ImageInfo = {
      bytes: this._returnImage ? image : null,
      width: width,
      height: height,
    };

    this.publishEvent({ name: 'barcode', data: filtered, image: info });

    this._rescanTimer = setTimeout(() => {
      this._rescanTimer = null;
      if (this._isStart && !this._isPaused) {
        try {
          customScan.rescan();
        } catch (err) {
          Log.e(TAG, 'Failed to rescan: ' + safeString(err));
        }
      }
    }, this._timeout);
  }

  /**
   * Cancels the rescan timer to prevent memory leaks.
   */
  private _cancelRescan(): void {
    if (this._rescanTimer !== null) {
      clearTimeout(this._rescanTimer);
      this._rescanTimer = null;
    }
  }

  /**
   * Checks if a barcode is within the configured scan window.
   * @param barcode - The barcode to check
   * @returns Whether the barcode is in the scan window
   */
  private _inWindow(barcode: Barcode): boolean {
    if (this._scanWindow === null || this._scanWindow.length < 4) {
      return true;
    }
    const corners: CornerPoint[] = barcode.corners;
    if (corners === null || corners === undefined || corners.length === 0) {
      return false;
    }
    const left: number = Math.round(this._scanWindow[0] * this._scanWidth);
    const top: number = Math.round(this._scanWindow[1] * this._scanHeight);
    const right: number = Math.round(this._scanWindow[2] * this._scanWidth);
    const bottom: number = Math.round(this._scanWindow[3] * this._scanHeight);

    for (let i: number = 0; i < corners.length; i++) {
      const c: CornerPoint = corners[i];
      if (c.x < left || c.x > right || c.y < top || c.y > bottom) {
        return false;
      }
    }
    return true;
  }

  /**
   * Publishes an error event to the Flutter layer via EventSink.error().
   * @param error - The error message string
   */
  errorCallback(error: string): void {
    this.publishError(ERROR_GENERIC, error);
  }

  /**
   * Callback for torch state changes.
   * @param error - Business error if any
   * @param state - The torch state
   */
  torchCallback(error: BusinessError, state: boolean): void {
    if (error !== null && error !== undefined) {
      return;
    }
    try {
      this.publishEvent({
        name: 'torchState',
        data: customScan.getFlashLightStatus() ? TorchState.on : TorchState.off,
      });
    } catch (err) {
      Log.e(TAG, 'Failed to publish torch state: ' + safeString(err));
    }
  }
}