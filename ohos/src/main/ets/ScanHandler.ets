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

import { customScan, scanBarcode, scanCore } from '@kit.ScanKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import { camera } from '@kit.CameraKit';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';

import { Barcode, BarcodeFormat } from './Barcode';
import { getCameraManager } from './CameraUtil';
import { BarcodeProcessor } from './BarcodeProcessor';

const SCAN_TAG: string = 'ScanHandler';

/** Torch state enum matching Dart TorchState values (off=0, on=1, unavailable=-1, auto=2). */
enum TorchState {
  off = 0,
  on = 1,
  unavailable = -1,
  auto = 2
}

/** Image data interface for ScannerEvent. */
interface ImageData {
  bytes: Uint8Array | null;
  width: number;
  height: number;
}

/** ScannerEvent interface for type-safe event publishing. */
interface ScannerEvent {
  name: string;
  data: Object | null;
  image?: ImageData | null;
}

/** Configuration interface for ScanHandler initialization. */
interface ScanHandlerConfig {
  torch: boolean;
  returnImage: boolean;
  speed: number;
  timeout: number;
  cameraResolutionValues: number[] | undefined;
  surfaceId: string | null;
  eventSink: EventSink | null;
  appCtx: Context | null;
}

/**
 * ScanHandler - Manages camera scanning lifecycle including callbacks,
 * scan control, and resource cleanup for the OHOS mobile_scanner plugin.
 * Barcode processing logic is delegated to BarcodeProcessor.
 */
export class ScanHandler {
  private barcodeProcessor: BarcodeProcessor = new BarcodeProcessor();
  private scanWidth: number = 1080;
  private scanHeight: number = 1080;
  private returnImage: boolean = false;
  private cameraResolutionValues: number[] | undefined = undefined;
  private resolutionRatio: number[] = [16 / 9, 4 / 3, 1];
  private torch: boolean = false;
  private speed: number = 1;
  private timeout: number = 250;
  private options: scanBarcode.ScanOptions = {};
  private retryScanTimes: number = 0;
  private scanWindow: Array<number> | null = null;
  private imageBuffer: Uint8Array | null = null;
  private pendingTimers: number[] = [];
  private surfaceId: string | null = null;
  private isStart: boolean = false;
  private isScanRegistered: boolean = false;
  private eventSink: EventSink | null = null;
  private applicationContext: Context | null = null;

  /** Callback for custom scan results. Delegates to BarcodeProcessor. */
  private scanCallback: AsyncCallback<scanBarcode.ScanResult[]> | null =
    async (error: BusinessError | null, result: scanBarcode.ScanResult[] | null): Promise<void> => {
      if (!this.isStart) {
        Log.w(SCAN_TAG, 'scanCallback invoked after plugin detachment, ignoring');
        return;
      }
      try {
        if (error && error.code) {
          this.retryCamera(error);
          Log.e(SCAN_TAG, `Scan error: code=${error.code}, message=${error.message}`);
          this.eventSink?.error('MOBILE_SCANNER_BARCODE_ERROR',
            `Scan error: code=${error.code}, message=${error.message}`, null);
          return;
        }
        if (!result) {
          return;
        }
        const barcodes: Barcode[] = this.barcodeProcessor.parseScanResults(result);
        this.barcodeProcessor.processBarcodeResults(barcodes, this.imageBuffer, this.scanWidth, this.scanHeight);
      } catch (e) {
        Log.e(SCAN_TAG, `scanCallback error: ${e.message}`);
        this.publishEvent({ name: 'error', data: `Scan callback failed: ${e.message}` });
      }
    };

  /** Callback for camera frame data. Delegates to BarcodeProcessor. */
  private frameCallback: AsyncCallback<customScan.ScanFrame> | null =
    async (error: BusinessError | null, frameResult: customScan.ScanFrame | null): Promise<void> => {
      if (!this.isStart) {
        Log.w(SCAN_TAG, 'frameCallback invoked after plugin detachment, ignoring');
        return;
      }
      try {
        this.imageBuffer = null;
        if (error) {
          Log.e(SCAN_TAG, `Frame error: code=${error.code}, message=${error.message}`);
          this.eventSink?.error('MOBILE_SCANNER_BARCODE_ERROR',
            `Frame error: code=${error.code}, message=${error.message}`, null);
          return;
        }
        if (frameResult && this.returnImage) {
          this.imageBuffer = await this.barcodeProcessor.processFrame(frameResult);
        }
      } catch (e) {
        Log.e(SCAN_TAG, `frameCallback error: ${e.message}`);
        this.eventSink?.error('MOBILE_SCANNER_BARCODE_ERROR',
          `Frame callback failed: ${e.message}`, null);
      }
    };

  /**
   * Initializes the scan handler with configuration from the plugin.
   * @param config - Configuration object for scan handler setup.
   * @throws Error if config is null or surfaceId is empty.
   */
  init(config: ScanHandlerConfig): void {
    if (!config) {
      throw new Error('ScanHandlerConfig is null');
    }
    if (!config.surfaceId) {
      Log.w(SCAN_TAG, 'init: surfaceId is null or empty, scanner may fail to start');
    }
    if (!config.appCtx) {
      Log.w(SCAN_TAG, 'init: appCtx is null, camera count may be unavailable');
    }
    this.torch = config.torch;
    this.returnImage = config.returnImage;
    this.speed = config.speed;
    this.timeout = config.timeout;
    this.cameraResolutionValues = config.cameraResolutionValues;
    this.surfaceId = config.surfaceId;
    this.eventSink = config.eventSink;
    this.applicationContext = config.appCtx;
    this.scanWindow = null;
    this.retryScanTimes = 0;
    this.isStart = true;
    this.isScanRegistered = false;
    this.updateBarcodeProcessor();
  }

  /**
   * Starts the camera stream: initializes scan, sets display, and starts scanning.
   * @param options - ScanKit scan options.
   */
  startCamera(options: scanBarcode.ScanOptions): void {
    this.options = options;
    try {
      customScan.init(this.options);
      this.setDisplay();
      this.startScan();
      this.isScanRegistered = true;
      // openFlashLight/closeFlashLight are ScanKit API methods; the public
      // MethodChannel interface uses `toggleTorch` for cross-platform consistency.
      if (this.torch) {
        customScan.openFlashLight();
      } else {
        customScan.closeFlashLight();
      }
      this.publishEvent({
        name: 'torchState',
        data: customScan.getFlashLightStatus() ? TorchState.on : TorchState.off
      });
    } catch (e) {
      // Release ScanKit session that was initialized before the failure
      try { customScan.release(); } catch (re) { Log.e(SCAN_TAG, `release after start failure: ${re.message}`); }
      Log.e(SCAN_TAG, `Failed to start camera: ${e.message}`);
      this.publishEvent({ name: 'error', data: `Camera start failed: ${e.message}` });
      throw new Error(e.message);
    }
  }

  /**
   * Builds scan types configuration from the formats list.
   * @param formats - Optional array of format integers.
   * @returns Array of ScanType for ScanKit configuration.
   */
  buildScanTypes(formats: number[] | undefined): scanCore.ScanType[] {
    if (!formats) {
      return [scanCore.ScanType.ALL];
    }
    const scanTypes: scanCore.ScanType[] = [];
    for (let i = 0; i < formats.length; i++) {
      const type: scanCore.ScanType = Barcode.convertToScanType(formats[i]);
      if (type !== scanCore.ScanType.FORMAT_UNKNOWN) {
        scanTypes.push(type);
      }
    }
    return scanTypes.length > 0 ? scanTypes : [scanCore.ScanType.ALL];
  }

  /**
   * Queries the number of available camera devices.
   * @returns The number of available cameras (minimum 1).
   */
  getCameraCount(): number {
    try {
      if (this.applicationContext) {
        const cameraManager: camera.CameraManager | undefined = getCameraManager(this.applicationContext);
        if (cameraManager) {
          const cameraArray: camera.CameraDevice[] = cameraManager.getSupportedCameras();
          if (cameraArray && cameraArray.length > 0) {
            return cameraArray.length;
          }
        }
      }
    } catch (e) {
      Log.e(SCAN_TAG, `Failed to get camera count: ${e.message}`);
    }
    return 1;
  }

  /** Gets the current flash light status. @returns 1 for on, 0 for off, -1 on error. */
  getFlashLightStatus(): number {
    try {
      return customScan.getFlashLightStatus() ? 1 : 0;
    } catch (error) {
      Log.e(SCAN_TAG, `Failed to getFlashLightStatus: ${error.message}`);
      return -1;
    }
  }

  /** Stops the scanner and releases camera resources. */
  async stop(): Promise<void> {
    if (this.isStart) {
      this.isStart = false;
      try {
        await customScan.stop();
        await customScan.release();
      } catch (e) {
        Log.e(SCAN_TAG, `Failed to stop scan: ${e.message}`);
      }
    }
  }

  /** Toggles the torch on or off. @returns true if torch is now on, false if off. */
  toggleTorch(): boolean {
    try {
      const light: boolean = customScan.getFlashLightStatus();
      if (light) {
        customScan.closeFlashLight();
      } else {
        customScan.openFlashLight();
      }
      const newState: boolean = customScan.getFlashLightStatus();
      this.publishEvent({ name: 'torchState', data: newState ? TorchState.on : TorchState.off });
      return newState;
    } catch (e) {
      Log.e(SCAN_TAG, `Failed to toggle torch: ${e.message}`);
      return false;
    }
  }

  /**
   * Sets the zoom scale. Maps to MethodChannel `setScale` in MobileScannerPlugin.
   * Uses ScanKit `setZoom` API (range 0.0-10.0), while the public MethodChannel
   * interface is named `setScale` for cross-platform consistency with Android/iOS.
   * @param zoomValue - The zoom scale value (0.0-10.0).
   */
  setZoom(zoomValue: number): void {
    try {
      customScan.setZoom(zoomValue);
      this.publishEvent({ name: 'zoomScaleState', data: zoomValue });
    } catch (e) {
      Log.e(SCAN_TAG, `Failed to set zoom: ${e.message}`);
    }
  }

  /**
   * Resets zoom to default (1.0). Maps to MethodChannel `resetScale` in MobileScannerPlugin.
   */
  resetZoom(): void {
    try {
      customScan.setZoom(1);
      this.publishEvent({ name: 'zoomScaleState', data: 1.0 });
    } catch (e) {
      Log.e(SCAN_TAG, `Failed to reset zoom: ${e.message}`);
    }
  }

  /** Updates the scan window. @param rect - The scan window rect [left, top, right, bottom]. */
  updateScanWindow(rect: Array<number> | null): void {
    this.scanWindow = rect;
  }

  /**
   * Retries the camera scan on internal error, up to 3 retries.
   * Performs a full restart: stop → init → setDisplay → startScan.
   * @param error - The business error that triggered the retry.
   */
  retryCamera(error: BusinessError): void {
    if (this.retryScanTimes < 3 && error.code === scanCore.ScanErrorCode.INTERNAL_ERROR) {
      this.retryScanTimes++;
      const timeId: number = setTimeout(async (): Promise<void> => {
        try {
          await this.stop();
          customScan.init(this.options);
          this.setDisplay();
          this.startScan();
          this.isScanRegistered = true;
          this.isStart = true;
          Log.i(SCAN_TAG, `Camera retry succeeded (attempt ${this.retryScanTimes})`);
        } catch (e) {
          this.isStart = false;
          Log.e(SCAN_TAG, `Failed to retry camera: ${e.message}`);
          this.publishEvent({ name: 'error', data: `Retry failed: ${e.message}` });
        }
        clearTimeout(timeId);
        const idx: number = this.pendingTimers.indexOf(timeId);
        if (idx !== -1) {
          this.pendingTimers.splice(idx, 1);
        }
      }, 100);
      this.pendingTimers.push(timeId);
    }
  }

  /** Starts the scan session with the camera. @throws On failure, propagates to caller. */
  private startScan(): void {
    try {
      const viewControl: customScan.ViewControl = {
        width: this.scanWidth,
        height: this.scanHeight,
        surfaceId: this.surfaceId || ''
      };
      customScan.start(viewControl, this.scanCallback, this.frameCallback);
    } catch (err) {
      Log.e(SCAN_TAG, `Failed to start scan: ${err.message}`);
      throw new Error(err.message);
    }
  }

  /**
   * Determines portrait layout from display dimensions.
   * Avoids reading display.orientation, which may access accelerometer data
   * before the user has agreed to the privacy policy.
   */
  private isPortraitDisplay(displayClass: display.Display): boolean {
    return displayClass.height >= displayClass.width;
  }

  /** Sets display dimensions based on screen layout and camera resolution. */
  private setDisplay(): void {
    try {
      const displayClass: display.Display | null = display.getDefaultDisplaySync();
      if (displayClass === null) {
        return;
      }
      const isPortrait: boolean = this.isPortraitDisplay(displayClass);
      const hasResolution: boolean = !!this.cameraResolutionValues && this.cameraResolutionValues.length >= 2;
      if (hasResolution) {
        this.applyResolutionBasedDimensions(displayClass, isPortrait);
      } else {
        this.applyDefaultDimensions(displayClass, isPortrait);
      }
    } catch (e) {
      Log.e(SCAN_TAG, `Failed to set display: ${e.message}`);
    }
  }

  /** Applies resolution-based dimensions based on layout orientation. */
  private applyResolutionBasedDimensions(displayClass: display.Display, isPortrait: boolean): void {
    if (!this.cameraResolutionValues || this.cameraResolutionValues.length < 2) {
      this.applyDefaultDimensions(displayClass, isPortrait);
      return;
    }
    const width: number = this.cameraResolutionValues[0];
    const height: number = this.cameraResolutionValues[1];

    if (isPortrait) {
      const radio: number = height / width;
      this.scanWidth = this.ensureDoublePrecision(px2vp(displayClass.width));
      this.scanHeight = this.calculateScaledDimension(radio, this.scanWidth);
    } else {
      const radio: number = width / height;
      this.scanHeight = this.ensureDoublePrecision(px2vp(displayClass.height));
      this.scanWidth = this.calculateScaledDimension(radio, this.scanHeight);
    }
  }

  /** Applies default square dimensions when no resolution is specified. */
  private applyDefaultDimensions(displayClass: display.Display, isPortrait: boolean): void {
    if (isPortrait) {
      this.scanWidth = this.ensureDoublePrecision(px2vp(displayClass.width));
      this.scanHeight = this.scanWidth;
    } else {
      this.scanHeight = this.ensureDoublePrecision(px2vp(displayClass.height));
      this.scanWidth = this.scanHeight;
    }
  }

  /** Calculates the scaled dimension based on the aspect ratio. */
  private calculateScaledDimension(ratio: number, baseDimension: number): number {
    if (ratio <= this.resolutionRatio[2]) {
      return baseDimension;
    }
    if (ratio <= this.resolutionRatio[1]) {
      return baseDimension * this.resolutionRatio[1];
    }
    return baseDimension * this.resolutionRatio[0];
  }

  /** Publishes an error event to the Flutter side. */
  errorCallback(error: string): void {
    this.publishEvent({ name: 'error', data: error });
  }

  /** Callback for torch state changes from the system. */
  torchCallback(error: BusinessError | null, bool: boolean | null): void {
    if (error) {
      return;
    }
    this.publishEvent({
      name: 'torchState',
      data: customScan.getFlashLightStatus() ? TorchState.on : TorchState.off
    });
  }

  /** Converts integer to double by adding epsilon. Required by ArkTS for coordinate precision. */
  private ensureDoublePrecision(number: number): number {
    if (Number.isInteger(number)) {
      number += 0.00000000001;
    }
    return number;
  }

  /** Publishes an event via EventChannel. */
  private publishEvent(event: ScannerEvent): void {
    this.eventSink?.success(event);
  }

  /** Cancels all pending timers in handler and processor. */
  cancelPendingTimers(): void {
    this.pendingTimers.forEach((t: number): void => clearTimeout(t));
    this.pendingTimers = [];
    this.barcodeProcessor.cancelPendingTimers();
  }

  /** Clears the event sink. */
  clearEventSink(): void {
    this.eventSink = null;
  }

  /** Gets the current scan width. */
  getScanWidth(): number {
    return this.scanWidth;
  }

  /** Gets the current scan height. */
  getScanHeight(): number {
    return this.scanHeight;
  }

  /** Gets whether the scanner is currently running. */
  getIsStart(): boolean {
    return this.isStart;
  }

  /** Sets the scan dimensions. */
  setScanDimensions(width: number, height: number): void {
    this.scanWidth = width;
    this.scanHeight = height;
  }

  /** Sets the event sink. */
  setEventSink(sink: EventSink | null): void {
    this.eventSink = sink;
    this.updateBarcodeProcessor();
  }

  /** setSurfaceId. */
  setSurfaceId(id: string | null): void {
    this.surfaceId = id;
  }

  /** Sets the application context. */
  setApplicationContext(ctx: Context | null): void {
    this.applicationContext = ctx;
  }

  /** Marks the scanner as stopped, releases resources, and breaks closure cycles. */
  markStopped(): void {
    this.isStart = false;
    this.scanCallback = null;
    this.frameCallback = null;
    this.barcodeProcessor.setStartState(false);
    this.barcodeProcessor.clearEventSink();
    this.barcodeProcessor.clearLastBarcodeValues();
    try {
      customScan.stop();
    } catch (e) {
      Log.e(SCAN_TAG, `Failed to stop scan in markStopped: ${e.message}`);
    }
    try {
      customScan.release();
    } catch (e) {
      Log.e(SCAN_TAG, `Failed to release scan in markStopped: ${e.message}`);
    }
  }

  /** Syncs barcode processor state with current handler settings. */
  private updateBarcodeProcessor(): void {
    this.barcodeProcessor.configure({
      scanWidth: this.scanWidth,
      scanHeight: this.scanHeight,
      scanWindow: this.scanWindow,
      speed: this.speed,
      timeout: this.timeout,
      eventSink: this.eventSink,
      isStart: this.isStart
    });
  }
}