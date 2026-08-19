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

import { scanCore } from '@kit.ScanKit';

/**
 * Represents the size (width and height) of a barcode detection area.
 */
export interface ScanSize {
  width: number;
  height: number;
}

/**
 * Represents a 2D corner point coordinate for barcode bounding box.
 */
export interface CornerPoint {
  x: number;
  y: number;
}

/**
 * Barcode format enumeration mapping to ScanKit ScanType values.
 * Each value corresponds to a specific barcode symbology (e.g., QR Code, Code 128, EAN-13).
 */
export enum BarcodeFormat {
  unknown = -1,
  all = 0,
  code128 = 1,
  code39 = 2,
  code93 = 4,
  codabar = 8,
  dataMatrix = 16,
  ean13 = 32,
  ean8 = 64,
  itf = 128,
  qrCode = 256,
  upcA = 512,
  upcE = 1024,
  pdf417 = 2048,
  aztec = 4096,
}

/**
 * Barcode content type enumeration.
 * Indicates the type of structured data encoded in a barcode
 * (e.g., contact info, email, URL, WiFi credentials).
 * Note: OHOS ScanKit does not support structured content parsing,
 * so all barcodes return BarcodeType.unknown on OHOS.
 */
export enum BarcodeType {
  unknown = 0,
  contactInfo = 1,
  email = 2,
  isbn = 3,
  phone = 4,
  product = 5,
  sms = 6,
  text = 7,
  url = 8,
  wifi = 9,
  geo = 10,
  calendarEvent = 11,
  driverLicense = 12,
}

/**
 * Plain barcode map sent to Flutter via MethodChannel/EventChannel.
 * Matches the structure expected by Barcode.fromNative() on the Dart side.
 */
export interface BarcodeMap {
  calendarEvent: null;
  contactInfo: null;
  corners: CornerPoint[] | null;
  displayValue: string;
  driverLicense: null;
  email: null;
  format: BarcodeFormat;
  geoPoint: null;
  phone: null;
  rawBytes: null;
  rawValue: string;
  size: ScanSize | null;
  sms: null;
  type: BarcodeType;
  url: null;
  wifi: null;
}

/**
 * Represents a decoded barcode result from ScanKit.
 * Contains the raw and display values, format type, corner points, and size.
 * Note: Structured content fields (calendarEvent, contactInfo, etc.) and rawBytes
 * are not supported by OHOS ScanKit and will always be null/unknown.
 */
export class Barcode {
  displayValue: string = '';
  rawValue: string = '';
  format: BarcodeFormat = BarcodeFormat.unknown;
  type: BarcodeType = BarcodeType.unknown;
  corners: CornerPoint[] = [];
  size: ScanSize | null = null;

  /**
   * Convert a ScanKit ScanType to the local BarcodeFormat enum.
   * @param value - The ScanKit ScanType value
   * @returns The corresponding BarcodeFormat, or BarcodeFormat.unknown if not recognized
   */
  static convertScanType(value: scanCore.ScanType): BarcodeFormat {
    if (value === scanCore.ScanType.AZTEC_CODE) {
      return BarcodeFormat.aztec;
    }
    if (value === scanCore.ScanType.CODABAR_CODE) {
      return BarcodeFormat.codabar;
    }
    if (value === scanCore.ScanType.CODE39_CODE) {
      return BarcodeFormat.code39;
    }
    if (value === scanCore.ScanType.CODE93_CODE) {
      return BarcodeFormat.code93;
    }
    if (value === scanCore.ScanType.CODE128_CODE) {
      return BarcodeFormat.code128;
    }
    if (value === scanCore.ScanType.DATAMATRIX_CODE) {
      return BarcodeFormat.dataMatrix;
    }
    if (value === scanCore.ScanType.EAN8_CODE) {
      return BarcodeFormat.ean8;
    }
    if (value === scanCore.ScanType.EAN13_CODE) {
      return BarcodeFormat.ean13;
    }
    if (value === scanCore.ScanType.ITF14_CODE) {
      return BarcodeFormat.itf;
    }
    if (value === scanCore.ScanType.PDF417_CODE) {
      return BarcodeFormat.pdf417;
    }
    if (value === scanCore.ScanType.QR_CODE) {
      return BarcodeFormat.qrCode;
    }
    if (value === scanCore.ScanType.UPC_A_CODE) {
      return BarcodeFormat.upcA;
    }
    if (value === scanCore.ScanType.UPC_E_CODE) {
      return BarcodeFormat.upcE;
    }
    return BarcodeFormat.unknown;
  }

  /**
   * Convert a local BarcodeFormat enum to a ScanKit ScanType.
   * @param value - The BarcodeFormat value to convert
   * @returns The corresponding ScanKit ScanType, or FORMAT_UNKNOWN if not recognized
   */
  static convertToScanType(value: BarcodeFormat): scanCore.ScanType {
    if (value === BarcodeFormat.aztec) {
      return scanCore.ScanType.AZTEC_CODE;
    }
    if (value === BarcodeFormat.codabar) {
      return scanCore.ScanType.CODABAR_CODE;
    }
    if (value === BarcodeFormat.code39) {
      return scanCore.ScanType.CODE39_CODE;
    }
    if (value === BarcodeFormat.code93) {
      return scanCore.ScanType.CODE93_CODE;
    }
    if (value === BarcodeFormat.code128) {
      return scanCore.ScanType.CODE128_CODE;
    }
    if (value === BarcodeFormat.dataMatrix) {
      return scanCore.ScanType.DATAMATRIX_CODE;
    }
    if (value === BarcodeFormat.ean8) {
      return scanCore.ScanType.EAN8_CODE;
    }
    if (value === BarcodeFormat.ean13) {
      return scanCore.ScanType.EAN13_CODE;
    }
    if (value === BarcodeFormat.itf) {
      return scanCore.ScanType.ITF14_CODE;
    }
    if (value === BarcodeFormat.pdf417) {
      return scanCore.ScanType.PDF417_CODE;
    }
    if (value === BarcodeFormat.qrCode) {
      return scanCore.ScanType.QR_CODE;
    }
    if (value === BarcodeFormat.upcA) {
      return scanCore.ScanType.UPC_A_CODE;
    }
    if (value === BarcodeFormat.upcE) {
      return scanCore.ScanType.UPC_E_CODE;
    }
    if (value === BarcodeFormat.all) {
      return scanCore.ScanType.ALL;
    }
    return scanCore.ScanType.FORMAT_UNKNOWN;
  }

  /**
   * Converts this barcode to a plain map for Flutter MethodChannel/EventChannel.
   * Matches the Android/iOS barcode map structure expected by Barcode.fromNative().
   */
  toMap(): BarcodeMap {
    const cornerMaps: CornerPoint[] = [];
    for (let i: number = 0; i < this.corners.length; i++) {
      const point: CornerPoint = {
        x: this.corners[i].x,
        y: this.corners[i].y,
      };
      cornerMaps.push(point);
    }

    let sizeMap: ScanSize | null = null;
    if (this.size !== null && this.size !== undefined) {
      const size: ScanSize = {
        width: this.size.width,
        height: this.size.height,
      };
      sizeMap = size;
    }

    const map: BarcodeMap = {
      calendarEvent: null,
      contactInfo: null,
      corners: cornerMaps.length > 0 ? cornerMaps : null,
      displayValue: this.displayValue,
      driverLicense: null,
      email: null,
      format: this.format,
      geoPoint: null,
      phone: null,
      rawBytes: null,
      rawValue: this.rawValue,
      size: sizeMap,
      sms: null,
      type: this.type,
      url: null,
      wifi: null,
    };
    return map;
  }

  /**
   * Converts a list of barcodes to plain maps for Flutter channel communication.
   */
  static toMapList(barcodes: Barcode[]): BarcodeMap[] {
    const result: BarcodeMap[] = [];
    for (let i: number = 0; i < barcodes.length; i++) {
      result.push(barcodes[i].toMap());
    }
    return result;
  }
}