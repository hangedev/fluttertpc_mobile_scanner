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

import common from '@ohos.app.ability.common';
import { camera } from '@kit.CameraKit';

const TAG: string = 'CameraUtil';

function logError(msg: string): void {
  console.error(TAG + ': ' + msg);
}

/**
 * Extract a human-readable error message from an error object.
 * Uses Object.keys()/Object.values() runtime property extraction to safely
 * access the 'message' property across different SDK error types.
 * @param err - The error object to extract message from
 * @returns A human-readable error message string
 */
function getErrMsg(err: Object | null | undefined): string {
  if (err === null || err === undefined) {
    return 'Unknown error';
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
 * Get the camera manager for the given context.
 * @param context - The application context
 * @returns The CameraManager instance, or undefined if unavailable
 */
export function getCameraManager(context: common.BaseContext): camera.CameraManager | undefined {
  if (context === null || context === undefined) {
    return undefined;
  }
  try {
    const mgr: camera.CameraManager = camera.getCameraManager(context);
    if (mgr !== null && mgr !== undefined) {
      return mgr;
    }
    return undefined;
  } catch (error) {
    logError('getCameraManager failed: ' + getErrMsg(error));
    return undefined;
  }
}

/**
 * Get the list of supported camera devices.
 * @param context - The application context
 * @returns Array of CameraDevice, or empty array if unavailable
 */
export function getSupportedCameras(context: common.BaseContext): Array<camera.CameraDevice> {
  try {
    const mgr: camera.CameraManager | undefined = getCameraManager(context);
    if (mgr === undefined) {
      return [];
    }
    return mgr.getSupportedCameras();
  } catch (error) {
    logError('getSupportedCameras failed: ' + getErrMsg(error));
    return [];
  }
}

/**
 * Check if the device has a flash unit (torch) available.
 * First checks if CameraDevice.hasFlash property is exposed,
 * then falls back to checking for a back camera (which typically has flash).
 * @param context - The application context
 * @returns true if a flash unit is available
 */
export function hasFlashUnit(context: common.BaseContext): boolean {
  if (context === null || context === undefined) {
    return false;
  }
  try {
    const cameras: camera.CameraDevice[] = getSupportedCameras(context);
    if (cameras === null || cameras === undefined || cameras.length === 0) {
      return false;
    }
    // 检查第一个后置摄像头是否有闪光灯能力
    // 优先检查后置摄像头（通常后置摄像头才有闪光灯）
    for (let i: number = 0; i < cameras.length; i++) {
      const dev: camera.CameraDevice = cameras[i];
      // 检查 CameraDevice 是否有 hasFlash 属性
      const keys: string[] = Object.keys(dev);
      for (let j: number = 0; j < keys.length; j++) {
        if (keys[j] === 'hasFlash') {
          const values: Object[] = Object.values(dev);
          if (typeof values[j] === 'boolean') {
            return values[j] as boolean;
          }
        }
      }
    }
    // 当 CameraDevice 不暴露 hasFlash 属性时，回退到启发式判断：
    // 检查是否有后置摄像头（通常后置摄像头有闪光灯）
    for (let i: number = 0; i < cameras.length; i++) {
      const dev: camera.CameraDevice = cameras[i];
      const cameraKeys: string[] = Object.keys(dev);
      const cameraValues: Object[] = Object.values(dev);
      for (let j: number = 0; j < cameraKeys.length; j++) {
        if (cameraKeys[j] === 'cameraType') {
          const ct: Object = cameraValues[j];
          if (typeof ct === 'number' && ct === 0) {
            return true;
          }
        }
      }
    }
    return false;
  } catch (error) {
    logError('hasFlashUnit failed: ' + getErrMsg(error));
    return false;
  }
}