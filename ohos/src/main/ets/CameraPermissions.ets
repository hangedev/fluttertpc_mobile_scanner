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

import bundleManager from '@ohos.bundle.bundleManager';
import abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';

type ResultCallback = (errCode: string | null, errDesc: string | null) => void;

export const CAMERA_PERMISSION: Permissions[] = ['ohos.permission.CAMERA'];

/**
 * Extract the error code number from a BusinessError object.
 * Uses Object.keys()/Object.values() runtime property extraction to safely
 * access the 'code' property across different SDK error types.
 * @param err - The error object to extract code from
 * @returns The error code number, or -1 if not found
 */
function getErrorCode(err: Object | null | undefined): number {
  if (err === null || err === undefined) {
    return -1;
  }
  if (typeof err !== 'object') {
    return -1;
  }
  const keys: string[] = Object.keys(err);
  const values: Object[] = Object.values(err);
  for (let i: number = 0; i < keys.length; i++) {
    if (keys[i] === 'code') {
      if (typeof values[i] === 'number') {
        return values[i] as number;
      }
    }
  }
  return -1;
}

/**
 * Extract a human-readable error message from a BusinessError object.
 * Uses Object.keys()/Object.values() runtime property extraction to safely
 * access the 'message' property across different SDK error types.
 * @param err - The error object to extract message from
 * @returns A human-readable error message string
 */
function getErrorMessage(err: Object | null | undefined): string {
  if (err === null || err === undefined) {
    return 'Unknown error';
  }
  if (typeof err !== 'object') {
    return String(err);
  }
  const keys: string[] = Object.keys(err);
  const values: Object[] = Object.values(err);
  for (let i: number = 0; i < keys.length; i++) {
    if (keys[i] === 'message') {
      if (typeof values[i] === 'string') {
        return values[i] as string;
      }
    }
  }
  return String(err);
}

async function checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
  const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let tokenId: number = 0;

  try {
    const bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
    );
    tokenId = bundleInfo.appInfo.accessTokenId;
  } catch (error) {
    console.error('Failed to get bundle info: ' + getErrorMessage(error));
    return abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
  }

  try {
    return await atManager.checkAccessToken(tokenId, permission);
  } catch (error) {
    console.error('Failed to check token: ' + getErrorMessage(error));
    return abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
  }
}

/**
 * Check if the given permissions have been granted.
 * @param permissions - Array of permissions to check
 * @returns true if all permissions are granted
 */
export async function checkPermissions(permissions: Permissions[]): Promise<boolean> {
  if (permissions === null || permissions === undefined || permissions.length === 0) {
    return false;
  }
  const status: abilityAccessCtrl.GrantStatus = await checkAccessToken(permissions[0]);
  return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
}

/**
 * Request camera permissions from the user.
 * @param context - The application context
 * @param callback - Callback with error code and message (null, null on success)
 */
export async function requestPermissions(
  context: Context,
  callback: ResultCallback,
): Promise<void> {
  if (context === null || context === undefined) {
    callback('ERR_NULL_CONTEXT', 'Context is null');
    return;
  }

  const hasCamera: boolean = await checkPermissions(CAMERA_PERMISSION);
  if (hasCamera) {
    callback(null, null);
    return;
  }

  const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  try {
    const data: PermissionRequestResult = await atManager.requestPermissionsFromUser(context, CAMERA_PERMISSION);
    const results: number[] = data.authResults;
    if (results === null || results === undefined) {
      callback('ERR_NO_RESULT', 'No permission result');
      return;
    }
    for (let i: number = 0; i < results.length; i++) {
      if (results[i] !== 0) {
        callback('ERR_PERMISSION_DENIED', 'Camera permission denied');
        return;
      }
    }
    callback(null, null);
  } catch (err) {
    const code: string = String(getErrorCode(err));
    const msg: string = getErrorMessage(err);
    console.error('Failed to request permissions. code: ' + code + ', msg: ' + msg);
    callback(code, msg);
  }
}