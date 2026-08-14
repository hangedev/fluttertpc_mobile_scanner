/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
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
import { AbilityAware, AbilityPluginBinding, TextureRegistry, SurfaceTextureEntry } from '@ohos/flutter_ohos/index';
import EventChannel, { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';

import { UIAbility } from '@kit.AbilityKit';
import { customScan, scanBarcode, scanCore, detectBarcode } from '@kit.ScanKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

import { Barcode, BarcodeFormat, BarcodeType, SizeResult } from './Barcode';
import { Point } from '@ohos.UiTest';
import { CAMERA_PERMISSION, checkPermissions, requestPermissions } from './CameraPermissions';
import { ScanHandler } from './ScanHandler';

const TAG: string = 'MobileScannerPlugin';

/** Start parameters interface for type-safe parameter passing. */
interface StartParams {
  torch: boolean;
  returnImage: boolean;
  speed: number;
  timeout: number;
  cameraResolutionValues: number[] | undefined;
}

/**
 * MobileScannerPlugin - OHOS implementation of the mobile_scanner Flutter plugin.
 *
 * Provides barcode scanning functionality using ScanKit on OpenHarmony.
 * Implements FlutterPlugin, MethodCallHandler, and AbilityAware lifecycle interfaces.
 */
export class MobileScannerPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  getUniqueClassName(): string {
    return 'MobileScannerPlugin';
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    Log.i(TAG, 'onAttachedToAbility');
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(): void {
    Log.i(TAG, 'onDetachedFromAbility');
    try {
      if (this.scanHandler) {
        this.scanHandler.cancelPendingTimers();
        // Cancel pending timers to prevent stale callbacks, but do NOT call
        // markStopped() here — that would fully release the ScanKit session.
        // During configuration changes (e.g. screen rotation), the ability is
        // recreated and re-attached; full cleanup happens in onDetachedFromEngine.
      }
    } catch (e) {
      Log.e(TAG, `onDetachedFromAbility cancelTimers error: ${e.message}`);
    } finally {
      this.ability = null;
    }
  }

  private methodChannel: MethodChannel | null = null;
  private eventChannel: EventChannel | null = null;
  private eventSink: EventSink | null = null;
  private applicationContext: Context | null = null;
  private ability: UIAbility | null = null;
  private textureId: number | null = null;
  private surfaceId: string | null = null;
  private binding: FlutterPluginBinding | null = null;
  private scanHandler: ScanHandler | null = null;
  private isStart: boolean = false;
  private facing: number = 0;
  private formats: number[] | undefined = undefined;
  private useNewCameraSelector: boolean = false;

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    try {
      this.binding = binding;
      this.applicationContext = binding.getApplicationContext();
      this.methodChannel =
        new MethodChannel(binding.getBinaryMessenger(), 'dev.steenbakker.mobile_scanner/scanner/method');
      this.methodChannel.setMethodCallHandler(this);
      this.eventChannel = new EventChannel(binding.getBinaryMessenger(), 'dev.steenbakker.mobile_scanner/scanner/event');
      this.eventChannel.setStreamHandler({
        onListen: (args: Object | null, eventSink: EventSink): void => {
          this.eventSink = eventSink;
          this.scanHandler?.setEventSink(eventSink);
        },
        onCancel: (): void => {
          this.eventSink = null;
          this.scanHandler?.clearEventSink();
        }
      });
    } catch (e) {
      Log.e(TAG, `Failed to attach to engine: ${e.message}`);
    }
  }

  /**
   * Registers the camera preview texture lazily when scanning starts.
   * Defers creation until after the user initiates the scanner,
   * avoiding early hardware-related initialization before privacy consent.
   */
  private ensureTextureRegistered(): void {
    if (this.textureId !== null && this.surfaceId !== null) {
      return;
    }
    if (!this.binding) {
      throw new Error('Flutter binding is null');
    }
    const textureRegistry: TextureRegistry = this.binding.getTextureRegistry();
    this.textureId = textureRegistry.getTextureId();
    const surfaceTextureEntry: SurfaceTextureEntry = textureRegistry.registerTexture(this.textureId);
    this.surfaceId = surfaceTextureEntry.getSurfaceId().toString();
    Log.i(TAG, `surfaceId: ${this.surfaceId}`);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    try {
      this.scanHandler?.cancelPendingTimers();
      this.scanHandler?.markStopped();
    } catch (e) {
      Log.e(TAG, `onDetachedFromEngine cleanup error: ${e.message}`);
    } finally {
      this.methodChannel?.setMethodCallHandler(null);
      this.methodChannel = null;
      this.eventChannel?.setStreamHandler(null);
      this.eventChannel = null;
      this.eventSink = null;
      this.isStart = false;
      this.formats = undefined;
      this.facing = 0;
      this.useNewCameraSelector = false;
      if (this.textureId !== null) {
        binding.getTextureRegistry().unregisterTexture(this.textureId);
      }
      this.textureId = null;
      this.surfaceId = null;
      this.scanHandler = null;
      this.applicationContext = null;
      this.binding = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      if (call.method === 'state') {
        checkPermissions(CAMERA_PERMISSION).then((hasCameraPermission: boolean): void => {
          if (hasCameraPermission) {
            result.success(1);
          } else {
            result.success(2);
          }
        }).catch((): void => {
          result.success(0);
        });
      } else if (call.method === 'request') {
        const ctx: Context | undefined = this.ability?.context;
        if (!ctx) {
          result.success(false);
          return;
        }
        requestPermissions(ctx, (err: string | null, msg: string | null): void => {
          result.success(err === null);
        });
      } else if (call.method === 'start') {
        this.start(call, result);
      } else if (call.method === 'toggleTorch') {
        this.toggleTorch(call, result);
      } else if (call.method === 'stop') {
        this.stop(result);
      } else if (call.method === 'analyzeImage') {
        this.analyzeImage(call, result);
      } else if (call.method === 'setScale') {
        this.setScale(call, result);
      } else if (call.method === 'resetScale') {
        this.resetScale(result);
      } else if (call.method === 'updateScanWindow') {
        this.updateScanWindow(call, result);
      } else {
        result.notImplemented();
      }
    } catch (err) {
      result.error('MOBILE_SCANNER_GENERIC_ERROR', err.message, null);
    }
  }

  /**
   * Handles the 'start' method call from Flutter.
   * Validates parameters, initializes ScanHandler, and starts the camera scan.
   * @param call - The method call with start parameters (facing, formats, torch, etc.).
   * @param result - The method result callback to return scan dimensions/state to Flutter.
   */
  async start(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      if (this.isStart) {
        result.error('MOBILE_SCANNER_ALREADY_STARTED_ERROR',
          'The scanner was already started.', null);
        return;
      }
      const params: StartParams | null = this.validateStartParams(call, result);
      if (!params) {
        return;
      }
      this.isStart = true;
      this.startScanHandler(params, result);
    } catch (e) {
      this.isStart = false;
      this.scanHandler?.markStopped();
      const businessErr: BusinessError = e as BusinessError;
      const errMsg: string = `Failed to start scanner: ${businessErr.message}`;
      if (businessErr.code !== undefined) {
        result.error('MOBILE_SCANNER_CAMERA_ERROR', `code=${businessErr.code}: ${businessErr.message}`, null);
      } else if (errMsg.includes('already started')) {
        result.error('MOBILE_SCANNER_ALREADY_STARTED_ERROR', errMsg, null);
      } else if (errMsg.includes('no camera') || errMsg.includes('No camera')) {
        result.error('MOBILE_SCANNER_NO_CAMERA_ERROR', errMsg, null);
      } else {
        result.error('MOBILE_SCANNER_CAMERA_ERROR', errMsg, null);
      }
    }
  }

  private validateStartParams(call: MethodCall, result: MethodResult): StartParams | null {
    this.facing = call.argument('facing') ?? 0;
    if (this.facing !== 0 && this.facing !== 1) {
      result.error('MOBILE_SCANNER_INVALID_PARAM', 'facing must be 0 (back) or 1 (front)', null);
      return null;
    }
    this.formats = call.argument('formats');
    this.useNewCameraSelector = call.argument('useNewCameraSelector') ?? false;

    const torch: boolean = call.argument('torch') ?? false;
    const returnImage: boolean = call.argument('returnImage') ?? false;
    const speed: number = call.argument('speed') ?? 1;
    if (speed < 0 || speed > 2) {
      result.error('MOBILE_SCANNER_INVALID_PARAM', 'speed must be 0-2', null);
      return null;
    }
    const timeout: number = call.argument('timeout') ?? 250;
    if (timeout < 0) {
      result.error('MOBILE_SCANNER_INVALID_PARAM', 'timeout must be a positive number', null);
      return null;
    }
    const cameraResolutionValues: number[] | undefined = call.argument('cameraResolution');
    if (cameraResolutionValues !== undefined) {
      if (cameraResolutionValues.length < 2 || cameraResolutionValues[0] <= 0 || cameraResolutionValues[1] <= 0) {
        result.error('MOBILE_SCANNER_INVALID_PARAM', 'cameraResolution must be [width, height]', null);
        return null;
      }
    }
    return { torch, returnImage, speed, timeout, cameraResolutionValues };
  }

  private startScanHandler(params: StartParams, result: MethodResult): void {
    this.ensureTextureRegistered();
    if (!this.scanHandler) {
      this.scanHandler = new ScanHandler();
    }
    this.scanHandler.init({
      torch: params.torch,
      returnImage: params.returnImage,
      speed: params.speed,
      timeout: params.timeout,
      cameraResolutionValues: params.cameraResolutionValues,
      surfaceId: this.surfaceId,
      eventSink: this.eventSink,
      appCtx: this.applicationContext
    });

    const scanTypes: scanCore.ScanType[] = this.scanHandler.buildScanTypes(this.formats);
    const options: scanBarcode.ScanOptions = {
      scanTypes: scanTypes,
      enableMultiMode: true,
      enableAlbum: true
    };

    this.scanHandler.startCamera(options);
    result.success({
      textureId: this.textureId,
      size: {
        width: this.scanHandler.getScanWidth(),
        height: this.scanHandler.getScanHeight()
      },
      currentTorchState: this.scanHandler.getFlashLightStatus(),
      numberOfCameras: this.scanHandler.getCameraCount()
    });
  }

  /**
   * Handles the 'stop' method call from Flutter.
   * Stops the scanner and releases scan resources.
   * @param result - The method result callback (nullable for internal calls).
   */
  async stop(result: MethodResult | null): Promise<void> {
    if (this.isStart) {
      this.isStart = false;
      try {
        await this.scanHandler?.stop();
        result?.success(null);
      } catch (e) {
        const errMsg: string = `Failed to stop scanner: ${e.message}`;
        Log.e(TAG, errMsg);
        result?.error('MOBILE_SCANNER_GENERIC_ERROR', errMsg, null);
      }
    } else {
      result?.success(null);
    }
  }

  /**
   * Handles the 'toggleTorch' method call from Flutter.
   * Toggles the flash light on/off via ScanHandler.
   * @param call - The method call (unused, torch state is toggled internally).
   * @param result - The method result callback.
   */
  toggleTorch(call: MethodCall, result: MethodResult): void {
    try {
      this.scanHandler?.toggleTorch();
      result.success(null);
    } catch (e) {
      result.error('MOBILE_SCANNER_GENERIC_ERROR', `Failed to toggle torch: ${e.message}`, null);
    }
  }

  /**
   * Handles the 'analyzeImage' method call from Flutter.
   * Decodes barcodes from a local image file using ScanKit detectBarcode.
   * @param call - The method call with filePath and optional formats.
   * @param result - The method result callback returning barcode data or null.
   */
  async analyzeImage(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      const filePath: string | undefined = call.argument('filePath');
      if (!filePath || filePath.length === 0) {
        result.error('MOBILE_SCANNER_BARCODE_ERROR', 'filePath is empty or null', null);
        return;
      }

      const formatValues: number[] | undefined = call.argument('formats');
      let scanTypes: scanCore.ScanType[] = [scanCore.ScanType.ALL];
      if (formatValues && formatValues.length > 0) {
        scanTypes = [];
        formatValues.forEach((format: number): void => {
          const type: scanCore.ScanType = Barcode.convertToScanType(format);
          if (type !== scanCore.ScanType.FORMAT_UNKNOWN) {
            scanTypes.push(type);
          }
        });
      }

      const options: scanBarcode.ScanOptions = {
        scanTypes: scanTypes,
        enableMultiMode: true,
        enableAlbum: true
      };

      const imageWidth: number = await this.getImageWidth(filePath);
      const inputImage: detectBarcode.InputImage = { uri: filePath };
      const decodeCallback: (
        err: BusinessError | null,
        scanResult: Array<scanBarcode.ScanResult> | null
      ) => void = this.buildAnalyzeCallback(result, imageWidth);
      detectBarcode.decode(inputImage, options, decodeCallback);
    } catch (e) {
      result.error('MOBILE_SCANNER_BARCODE_ERROR', `Failed to analyze image: ${e.message}`, null);
    }
  }

  private async getImageWidth(filePath: string): Promise<number> {
    const defaultWidth: number = this.scanHandler?.getScanWidth() ?? 1080;
    const imgSource: image.ImageSource = image.createImageSource(filePath);
    try {
      const imgInfo: image.ImageInfo = await imgSource.getImageInfo(0);
      return imgInfo && imgInfo.size ? imgInfo.size.width : defaultWidth;
    } catch (e) {
      Log.e(TAG, `Failed to get image dimensions: ${e.message}`);
      return defaultWidth;
    } finally {
      try { imgSource.release(); } catch (e) { Log.e(TAG, `imgSource release failed: ${e.message}`); }
    }
  }

  private buildAnalyzeCallback(result: MethodResult, imageWidth: number): (
    error: BusinessError | null,
    scanResult: Array<scanBarcode.ScanResult> | null
  ) => void {
    return (error: BusinessError | null, scanResult: Array<scanBarcode.ScanResult> | null): void => {
      if (error && error.code) {
        result.error('MOBILE_SCANNER_BARCODE_ERROR', JSON.stringify(error), null);
        return;
      }
      if (!scanResult || scanResult.length === 0) {
        result.success(null);
        return;
      }
      const barcodes: Barcode[] = scanResult.map((item: scanBarcode.ScanResult): Barcode => {
        const cornerPoints = item.cornerPoints;
        let corners: Point[] = [];
        if (cornerPoints !== undefined && cornerPoints !== null) {
          corners = [
            {
                x: this.ensureDoublePrecision(imageWidth - cornerPoints[0].y),
                y: this.ensureDoublePrecision(cornerPoints[0].x)
            },
            {
                x: this.ensureDoublePrecision(imageWidth - cornerPoints[1].y),
                y: this.ensureDoublePrecision(cornerPoints[1].x)
            },
            {
                x: this.ensureDoublePrecision(imageWidth - cornerPoints[2].y),
                y: this.ensureDoublePrecision(cornerPoints[2].x)
            },
            {
                x: this.ensureDoublePrecision(imageWidth - cornerPoints[3].y),
                y: this.ensureDoublePrecision(cornerPoints[3].x)
            },
          ];
        }
        return {
          displayValue: item.originalValue,
          rawValue: item.originalValue,
          format: Barcode.convertScanType(item.scanType),
          type: BarcodeType.unknown,
          corners: corners
        } as Barcode;
      });
      result.success({ name: 'barcode', data: barcodes });
    };
  }

  /**
   * Handles the 'setScale' method call from Flutter.
   * Sets the camera zoom scale (OHOS range 0.0-10.0).
   * Maps to ScanHandler.setZoom() internally.
   * @param call - The method call with zoom scale value as args.
   * @param result - The method result callback.
   */
  setScale(call: MethodCall, result: MethodResult): void {
    try {
      if (!this.isStart) {
        result.error('MOBILE_SCANNER_SET_SCALE_WHEN_STOPPED_ERROR',
          'The zoom scale cannot be changed when the camera is stopped.', null);
        return;
      }
      const zoomValue: number = call.args as number;
      if (zoomValue < 0 || zoomValue > 10) {
        result.error('MOBILE_SCANNER_GENERIC_ERROR',
          `Zoom scale must be between 0.0 and 10.0, got ${zoomValue}`, null);
        return;
      }
      this.scanHandler?.setZoom(zoomValue);
      result.success(null);
    } catch (error) {
      result.error('MOBILE_SCANNER_GENERIC_ERROR',
        `Failed to set zoom scale: ${error.message}`, null);
    }
  }

  /**
   * Handles the 'resetScale' method call from Flutter.
   * Resets the camera zoom scale to 1.0.
   * Maps to ScanHandler.resetZoom() internally.
   * @param result - The method result callback.
   */
  resetScale(result: MethodResult): void {
    try {
      if (!this.isStart) {
        result.error('MOBILE_SCANNER_SET_SCALE_WHEN_STOPPED_ERROR',
          'The zoom scale cannot be changed when the camera is stopped.', null);
        return;
      }
      this.scanHandler?.resetZoom();
      result.success(null);
    } catch (error) {
      result.error('MOBILE_SCANNER_GENERIC_ERROR',
        `Failed to reset zoom scale: ${error.message}`, null);
    }
  }

  /**
   * Handles the 'updateScanWindow' method call from Flutter.
   * Updates the scan window area for filtering barcode results.
   * @param call - The method call with rect array [left, top, right, bottom].
   * @param result - The method result callback.
   */
  updateScanWindow(call: MethodCall, result: MethodResult): void {
    try {
      const rect: Array<number> | null = call.argument('rect');
      if (rect !== null && rect !== undefined) {
        if (rect.length < 4) {
          result.error('MOBILE_SCANNER_INVALID_PARAM',
            'Scan window rect must have 4 values [left, top, right, bottom]', null);
          return;
        }
        for (const val of rect) {
          if (val < 0 || val > 1) {
            result.error('MOBILE_SCANNER_INVALID_PARAM',
              'Scan window rect values must be between 0 and 1', null);
            return;
          }
        }
      }
      this.scanHandler?.updateScanWindow(rect);
      result.success(null);
    } catch (e) {
      result.error('MOBILE_SCANNER_GENERIC_ERROR',
        `Failed to update scan window: ${e.message}`, null);
    }
  }

  private ensureDoublePrecision(number: number): number {
    if (Number.isInteger(number)) {
      number += 0.00000000001;
    }
    return number;
  }
}