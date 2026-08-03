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

import { scanBarcode, scanCore, customScan } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { camera } from '@kit.CameraKit';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { EventSink } from '@ohos/flutter_ohos/src/main/ets/plugin/common/EventChannel';
import { Point } from '@ohos.UiTest';

import { Barcode, BarcodeFormat, BarcodeType, SizeResult } from './Barcode';

const PROC_TAG: string = 'BarcodeProcessor';

/** Barcode map used for event data sent to the Flutter side. */
interface BarcodeMap {
  displayValue: string;
  rawValue: string;
  corners: Array<Point>;
  format: BarcodeFormat;
  size: SizeResult;
  type: BarcodeType;
}

/** Image map containing decoded image bytes and dimensions. */
interface ImageMap {
  bytes: Uint8Array | null;
  width: number;
  height: number;
}

/** ScannerEvent interface for type-safe event publishing (replaces ESObject). */
interface ScannerEvent {
  name: string;
  data: Object | null;
  image?: ImageMap;
}

/** Configuration interface for BarcodeProcessor setup. */
interface ProcessorConfig {
  scanWidth: number;
  scanHeight: number;
  scanWindow: Array<number> | null;
  speed: number;
  timeout: number;
  eventSink: EventSink | null;
  isStart: boolean;
}

/**
 * BarcodeProcessor - Handles barcode scan result processing, frame image processing,
 * and event publishing for the OHOS mobile_scanner plugin.
 *
 * Extracted from ScanHandler to reduce class complexity and improve maintainability.
 */
export class BarcodeProcessor {
  private scanWidth: number = 1080;
  private scanHeight: number = 1080;
  private scanWindow: Array<number> | null = null;
  private speed: number = 1;
  private timeout: number = 250;
  private lastBarcodeValues: string[] = [];
  private pendingTimers: number[] = [];
  private eventSink: EventSink | null = null;
  private isStart: boolean = false;

  /**
   * Configures the processor with settings from the scan handler.
   * @param config - Configuration object for processor setup.
   */
  configure(config: ProcessorConfig): void {
    this.scanWidth = config.scanWidth;
    this.scanHeight = config.scanHeight;
    this.scanWindow = config.scanWindow;
    this.speed = config.speed;
    this.timeout = config.timeout;
    this.eventSink = config.eventSink;
    this.isStart = config.isStart;
  }

  /**
   * Sets the event sink for publishing events.
   * @param sink - The event sink.
   */
  setEventSink(sink: EventSink | null): void {
    this.eventSink = sink;
  }

  /**
   * Clears the event sink reference.
   */
  clearEventSink(): void {
    this.eventSink = null;
  }

  /**
   * Clears all stored barcode values to prevent stale data after stop.
   */
  clearLastBarcodeValues(): void {
    this.lastBarcodeValues = [];
  }

  /**
   * Sets whether scanning is active.
   */
  setStartState(started: boolean): void {
    this.isStart = started;
  }

  /**
   * Gets the current scan width.
   */
  getScanWidth(): number {
    return this.scanWidth;
  }

  /**
   * Gets the current scan height.
   */
  getScanHeight(): number {
    return this.scanHeight;
  }

  /**
   * Sets the scan dimensions.
   */
  setScanDimensions(width: number, height: number): void {
    this.scanWidth = width;
    this.scanHeight = height;
  }

  /**
   * Sets the scan window.
   */
  setScanWindow(window: Array<number> | null): void {
    this.scanWindow = window;
  }

  /**
   * Sets the pending timers array reference for cleanup.
   */
  setPendingTimers(timers: number[]): void {
    this.pendingTimers = timers;
  }

  /**
   * Cancels all pending timers and clears the timer array.
   */
  cancelPendingTimers(): void {
    this.pendingTimers.forEach((t: number): void => clearTimeout(t));
    this.pendingTimers = [];
  }

  /**
   * Processes detected barcodes: filters by scan window, applies speed mode, and publishes events.
   * @param barcodes - The detected barcodes.
   * @param image - Optional image buffer.
   * @param width - The scan width.
   * @param height - The scan height.
   */
  processBarcodeResults(barcodes: Barcode[], image: Uint8Array | null, width: number, height: number): void {
    try {
      barcodes = barcodes.filter((barcode: Barcode): boolean => {
        if (this.scanWindow) {
          return this.isBarcodeInScanWindow(barcode);
        }
        return true;
      });
      if (barcodes.length === 0) {
        try {
          customScan.rescan();
        } catch (err) {
          Log.e(PROC_TAG, `Failed to rescan: ${err.message}`);
        }
      } else {
        // noDuplicates mode: skip if same barcodes as last scan
        if (this.speed === 0) {
          const currentValues: string = barcodes.map((b: Barcode): string => b.rawValue).sort().join(',');
          const lastValues: string = this.lastBarcodeValues.sort().join(',');
          if (currentValues === lastValues) {
            this.scheduleRescan();
            return;
          }
          this.lastBarcodeValues = barcodes.map((b: Barcode): string => b.rawValue);
        }

        const barcodeList: BarcodeMap[] = this.buildBarcodeEventData(barcodes);

        if (image) {
          const imageMap: ImageMap = { bytes: image, width: width, height: height };
          this.publishEvent({ name: 'barcode', data: barcodeList, image: imageMap });
        } else {
          this.publishEvent({ name: 'barcode', data: barcodeList });
        }

        // Schedule rescan based on speed mode
        if (this.speed === 2) {
          try { customScan.rescan(); } catch (err) { Log.e(PROC_TAG, `Failed to rescan: ${err.message}`); }
        } else {
          this.scheduleRescan();
        }
      }
    } catch (e) {
      Log.e(PROC_TAG, `Failed to process barcode callback: ${e.message}`);
    }
  }

  /**
   * Processes a camera frame to create image buffer when returnImage is enabled.
   * @param frameResult - The camera frame data from ScanKit.
   * @returns The image buffer as Uint8Array, or null on failure.
   */
  async processFrame(frameResult: customScan.ScanFrame): Promise<Uint8Array | null> {
    const eventWidth: number = frameResult.width;
    const eventHeight: number = frameResult.height;

    let imageResource: image.ImageSource | null = null;
    let pixelMap: image.PixelMap | null = null;
    let packer: image.ImagePacker | null = null;
    try {
      const sourceOptions: image.SourceOptions = {
        sourceDensity: 120,
        sourcePixelFormat: image.PixelMapFormat.NV21,
        sourceSize: { height: eventHeight, width: eventWidth }
      };
      imageResource = image.createImageSource(frameResult.byteBuffer, sourceOptions);
      const opts: image.InitializationOptions = {
        editable: true,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        size: { height: eventHeight, width: eventWidth }
      };
      pixelMap = await imageResource.createPixelMap(opts);
      pixelMap.rotateSync(camera.ImageRotation.ROTATION_90);
      packer = image.createImagePacker();
      const packingOpt: image.PackingOption = { format: 'image/jpeg', quality: 100 };
      const imgBuffer: ArrayBuffer = await packer.packing(pixelMap, packingOpt);
      return new Uint8Array(imgBuffer);
    } catch (e) {
      Log.e(PROC_TAG, `Failed to create imageBuffer: ${e.message}`);
      return null;
    } finally {
      if (pixelMap) {
        try { pixelMap.release(); } catch (e) { Log.e(PROC_TAG, `pixelMap release failed: ${e}`); }
      }
      if (imageResource) {
        try { imageResource.release(); } catch (e) { Log.e(PROC_TAG, `imageResource release failed: ${e}`); }
      }
      if (packer) {
        try { packer.release(); } catch (e) { Log.e(PROC_TAG, `packer release failed: ${e}`); }
      }
    }
  }

  /**
   * Parses scan results into Barcode array.
   * Prefers cornerPoints for quadrilateral support (consistent with analyzeImage),
   * falls back to scanCodeRect for rectangular bounds.
   * @param result - The raw scan results from ScanKit.
   * @returns Array of parsed Barcode objects.
   */
  parseScanResults(result: scanBarcode.ScanResult[]): Barcode[] {
    return result.map((item: scanBarcode.ScanResult): Barcode => {
      const cornerPoints = item.cornerPoints;
      let width: number = 0;
      let height: number = 0;
      let corners: Point[] = [];
      if (cornerPoints && cornerPoints.length >= 4) {
        // Use cornerPoints for quadrilateral support (consistent with analyzeImage)
        corners = [
          {
              x: this.ensureDoublePrecision(cornerPoints[0].x),
              y: this.ensureDoublePrecision(cornerPoints[0].y)
          } as Point,
          {
              x: this.ensureDoublePrecision(cornerPoints[1].x),
              y: this.ensureDoublePrecision(cornerPoints[1].y)
          } as Point,
          {
              x: this.ensureDoublePrecision(cornerPoints[2].x),
              y: this.ensureDoublePrecision(cornerPoints[2].y)
          } as Point,
          {
              x: this.ensureDoublePrecision(cornerPoints[3].x),
              y: this.ensureDoublePrecision(cornerPoints[3].y)
          } as Point,
        ];
        width = this.ensureDoublePrecision(Math.abs(cornerPoints[2].x - cornerPoints[0].x));
        height = this.ensureDoublePrecision(Math.abs(cornerPoints[2].y - cornerPoints[0].y));
      } else {
        // Fallback to scanCodeRect when cornerPoints not available
        const rect = item.scanCodeRect;
        if (rect) {
          width = this.ensureDoublePrecision(rect.right - rect.left);
          height = this.ensureDoublePrecision(rect.bottom - rect.top);
          corners = [
            { x: this.ensureDoublePrecision(rect.left), y: this.ensureDoublePrecision(rect.top) } as Point,
            { x: this.ensureDoublePrecision(rect.right), y: this.ensureDoublePrecision(rect.top) } as Point,
            { x: this.ensureDoublePrecision(rect.right), y: this.ensureDoublePrecision(rect.bottom) } as Point,
            { x: this.ensureDoublePrecision(rect.left), y: this.ensureDoublePrecision(rect.bottom) } as Point,
          ];
        }
      }
      return {
        displayValue: item.originalValue,
        rawValue: item.originalValue,
        format: Barcode.convertScanType(item.scanType),
        type: BarcodeType.unknown,
        size: { width: width, height: height },
        corners: corners
      } as Barcode;
    });
  }

  /**
   * Converts Barcode array to BarcodeMap array for event data.
   * @param barcodes - The detected barcodes to convert.
   * @returns Array of BarcodeMap for event publishing.
   */
  private buildBarcodeEventData(barcodes: Barcode[]): BarcodeMap[] {
    const barcodeList: BarcodeMap[] = [];
    for (let i = 0; i < barcodes.length; i++) {
      const item: Barcode = barcodes[i];
      barcodeList.push({
        displayValue: item.displayValue,
        rawValue: item.rawValue,
        corners: item.corners,
        format: item.format,
        type: item.type,
        size: item.size
      });
    }
    return barcodeList;
  }

  /**
   * Checks if a barcode is within the scan window.
   * @param barcode - The barcode to check.
   * @returns true if the barcode is within the scan window.
   */
  private isBarcodeInScanWindow(barcode: Barcode): boolean {
    const corners: Point[] = barcode.corners;
    if (!this.scanWindow || corners.length === 0) {
      return true;
    }
    const left: number = Math.round(this.scanWindow[0] * this.scanWidth);
    const top: number = Math.round(this.scanWindow[1] * this.scanHeight);
    const right: number = Math.round(this.scanWindow[2] * this.scanWidth);
    const bottom: number = Math.round(this.scanWindow[3] * this.scanHeight);
    return corners.every((item: Point): boolean =>
      item.x >= left && item.x <= right && item.y >= top && item.y <= bottom);
  }

  /**
   * Schedules a rescan after the configured timeout period.
   */
  private scheduleRescan(): void {
    const timerId: number = setTimeout((): void => {
      if (this.isStart) {
        try {
          customScan.rescan();
        } catch (err) {
          Log.e(PROC_TAG, `Failed to rescan: ${err.message}`);
        }
      }
      const idx: number = this.pendingTimers.indexOf(timerId);
      if (idx !== -1) {
        this.pendingTimers.splice(idx, 1);
      }
    }, this.timeout);
    this.pendingTimers.push(timerId);
  }

  /**
   * Converts integer values to double by adding a small epsilon.
   * Required by ArkTS to ensure floating-point precision for barcode coordinates.
   * @param number - The input number.
   * @returns A double representation of the input.
   */
  private ensureDoublePrecision(number: number): number {
    if (Number.isInteger(number)) {
      number += 0.00000000001;
    }
    return number;
  }

  /**
   * Publishes an event to the Flutter side via EventChannel.
   * @param event - The event data to publish.
   */
  private publishEvent(event: ScannerEvent): void {
    this.eventSink?.success(event);
  }
}