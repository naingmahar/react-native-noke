package com.nmhnoke

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import android.util.Log

object NokeEvents {
  const val CONNECTING = "connecting"
  const val CONNECTED = "connected"
  const val UNLOCKED = "unlocked"
  const val DISCONNECTED = "disconnected"
  const val ERROR = "error"
  const val SHUTDOWN = "shutdown"
  const val SYNCING = "syncing"
  const val DISCOVERED = "discovered"
  const val BLUETOOTH_OFF = "bluetooth_off"
}

@ReactModule(name = NokeModule.NAME)
class NokeModule(reactContext: ReactApplicationContext) :
  NativeNokeSpec(reactContext) {

//  private var currentConnectedDevice: NokeDevice? = null
  private val TAG = "NativeNoke"

  override fun getName(): String {
    return NAME
  }

  override fun initNoke(apiKey: String?, productionBundleName: String?) {
//    val nokeManager = NokeDeviceManagerService.getInstance(reactApplicationContext)
//
//    // Match your iOS logic for API Key and Library Mode
//    nokeManager.setApiKey("dba1586f-2992-442d-a4e7-970b43ee420d")
//
//    val bundleId = reactApplicationContext.packageName
//    if (bundleId == "com.extraspaceasia.loyalty") {
//      nokeManager.setLibraryMode(NokeLibraryMode.PRODUCTION)
//    } else {
//      nokeManager.setLibraryMode(NokeLibraryMode.SANDBOX)
//    }
//
//    nokeManager.registerNokeServiceListener(this)
  }

  override fun addDevices(devices: ReadableArray?) {
//    val nokeManager = NokeDeviceManagerService.getInstance(reactApplicationContext)
//    nokeManager.removeAllNoke()
//
//    for (i in 0 until devices.size()) {
//      val dict = devices.getMap(i)
//      val name = dict.getString("name")
//      val mac = dict.getString("mac")
//
//      if (name != null && mac != null) {
//        val noke = NokeDevice(name, mac)
//        nokeManager.addNokeDevice(noke)
//        Log.d(TAG, "✅ Added Noke device: $name $mac")
//      }
//    }
  }

  override fun startScan() {
    Log.d(TAG, "ESNOKE Starting scan")
//    NokeDeviceManagerService.getInstance(reactApplicationContext).startScanning()
  }

  override fun stopScan() {
    Log.d(TAG, "ESNOKE Stopping scan")
//    NokeDeviceManagerService.getInstance(reactApplicationContext).stopScanning()
  }

  override fun unlockDevice(command: String?) {
//    currentConnectedDevice?.let {
//      it.sendCommands(command)
//      Log.d(TAG, "ESNOKE Unlock command sent")
//    }
  }

  override fun offlineUnlockDevice(key: String?, cmd: String?) {
//    currentConnectedDevice?.let {
//      it.offlineUnlock(key, cmd)
//      Log.d(TAG, "ESNOKE Offline unlock command sent")
//    }
  }

  override fun connectDevice(mac: String?) {
//    val nokeManager = NokeDeviceManagerService.getInstance(reactApplicationContext)
//    val device = nokeManager.nokeDevices[mac]
//    device?.let {
//      nokeManager.connectToNokeDevice(it)
//    }
  }

  override fun disconnectDevice(deviceName: String?, deviceMac: String?) {
//    val noke = NokeDevice(deviceName, deviceMac)
//    NokeDeviceManagerService.getInstance(reactApplicationContext).disconnectNokeDevice(noke)
  }

  override fun clearDevices() {
//    NokeDeviceManagerService.getInstance(reactApplicationContext).removeAllNoke()
  }


  companion object {
    const val NAME = "Noke"
  }
}
