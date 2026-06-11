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

/** Camera permission array constant (UPPER_CASE naming for constants). */
export const CAMERA_PERMISSION: Array<Permissions> = ['ohos.permission.CAMERA'];

/**
 * Checks the access token status for a given permission.
 * @param permission - The permission to check.
 * @returns The grant status of the permission.
 */
async function checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
  const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

  // Get the application's access token ID
  let tokenId: number = 0;
  try {
    const bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    );
    const appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
  }

  // If tokenId is 0 (failed to get bundle info), return DENIED
  if (tokenId === 0) {
    return abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
  }

  // Verify if the app has the required permission
  try {
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
  }

  return grantStatus;
}

/**
 * Checks if the given permissions are granted.
 * @param permissions - The permissions to check.
 * @returns true if all permissions are granted.
 */
export async function checkPermissions(permissions: Array<Permissions>): Promise<boolean> {
  const grantStatus: abilityAccessCtrl.GrantStatus = await checkAccessToken(permissions[0]);
  return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
}

/**
 * Requests camera permission from the user.
 * If already granted, calls the callback immediately.
 * @param context - The application context.
 * @param callback - The callback to invoke with the result.
 */
export async function requestPermissions(
  context: Context,
  callback: ResultCallback
): Promise<void> {
  const hasCameraPermission: boolean = await checkPermissions(CAMERA_PERMISSION);

  if (!hasCameraPermission) {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

    // requestPermissionsFromUser determines whether to show a dialog based on authorization state
    atManager.requestPermissionsFromUser(context, CAMERA_PERMISSION)
      .then((data: PermissionRequestResult): void => {
        const grantStatus: Array<number> = data.authResults;
        const length: number = grantStatus.length;
        for (let i = 0; i < length; i++) {
          if (grantStatus[i] !== 0) {
            // User denied permission
            callback('errCode', 'Camera permission not granted');
            return;
          }
        }
        // User granted permission
        callback(null, null);
      }).catch((err: BusinessError): void => {
        console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
        callback(String(err.code), err.message);
      });
  } else {
    // Permissions already exist. Call the callback with success.
    callback(null, null);
  }
}