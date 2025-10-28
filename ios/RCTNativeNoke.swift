
import Foundation
import NokeMobileLibrary
import React


struct NokeEvents {
    static let CONNECTING = "connecting"
    static let CONNECTED  = "connected"
    static let UNLOCKED  = "unlocked"
    static let DISCONNECTED = "disconnected"
    static let ERROR = "error"
    static let SHUTDOWN = "shutdown"
    static let SYNCING  = "syncing"
    static let DISCOVERED  = "discovered"
    static let BLUETOOTH_OFF = "bluetooth_off"
}

@objc(NativeNokeModule)
public class NativeNokeModule: NSObject {
  
  var nokeErrorMessage : String? = nil
  
  var nokeDevices = [NokeDevice]()
  var currentConnectedDevice : NokeDevice? = nil
  
  var previousStatus: String = ""
  
  @objc public static let shared = NativeNokeModule()
  
  @objc public func initNoke(_ apiKey: String, productionBundleName: String) {
        NokeDeviceManager.shared().setAPIKey("dba1586f-2992-442d-a4e7-970b43ee420d")
        let bundleID = Bundle.main.bundleIdentifier
        if bundleID == "com.extraspaceasia.loyalty" {
          NokeDeviceManager.shared().setLibraryMode(NokeLibraryMode.PRODUCTION)
        } else {
          NokeDeviceManager.shared().setLibraryMode(NokeLibraryMode.SANDBOX)
        }
        NokeDeviceManager.shared().delegate = self
  }
  
  @objc public func addDevices(_ devices: [Any]) {
        debugPrint("ESNOKE Adding devices to Noke")
        NokeDeviceManager.shared().removeAllNoke()
        for item in devices {
          if let dict = item as? NSDictionary,
             let name = dict["name"] as? String,
             let mac = dict["mac"] as? String {
              if let noke = NokeDevice(name: name, mac: mac) {
                  NokeDeviceManager.shared().addNoke(noke)
              }
              print("✅ Added Noke device:", name, mac)
          } else {
              print("⚠️ Invalid device item:", item)
          }
        }
  }
  
  @objc public func startScan() {
        debugPrint("ESNOKE Starting scan")
        NokeDeviceManager.shared().startScanForNokeDevices()
  }
  
  @objc public func stopScan() {
        debugPrint("ESNOKE Stopping scan")
        NokeDeviceManager.shared().stopScan()
  }
  
  @objc public func unlockDevice(_ command: String) {
        guard let nokeDevice = self.currentConnectedDevice else {
          return
        }
        nokeDevice.sendCommands(command)
        debugPrint("ESNOKE Unlock command sent")
  }
  
  @objc public func offlineUnlockDevice(_ key: String, cmd: String) {
        guard let nokeDevice = self.currentConnectedDevice else {
          return
        }
        let result = nokeDevice.offlineUnlock(key: key, command: cmd, addTimestamp: false)
        debugPrint("ESNOKE key: " + key)
        debugPrint("ESNOKE cmd: " + cmd)
        debugPrint("ESNOKE Offline unlock command sent " + result.description)
        return

  }
  
  @objc public func connectDevice(_ mac: String) {
        let filtered = NokeDeviceManager.shared().nokeDevices.filter{ $0.value.mac == mac }.first?.value
        if let data = filtered {
          NokeDeviceManager.shared().connectToNokeDevice(data)
        }
  }
  
  @objc public func disconnectDevice(_ deviceName: String, deviceMac: String) {
        let device = NokeDevice.init(name: "\(deviceName)", mac: "\(deviceMac)")
        NokeDeviceManager.shared().disconnectNokeDevice(device!)
  }
  
  @objc public func clearDevices() {
        NokeDeviceManager.shared().removeAllNoke()
  }
  
//  @objc public static func moduleName() -> String! {
//    return "NativeRNNoke"
//  }
//  
//  func getTurboModule(_ params: Any!) -> Any! {
//    return self
//  }
}


extension NativeNokeModule : NokeDeviceManagerDelegate{
  public func nokeReadyForFirmwareUpdate(noke: NokeDevice) {}

  public func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
    switch state {
        case .Discovered:
      updateNokeStatus(status: NokeEvents.DISCOVERED, noke: noke, message: "")
            break
        case .Connected:
          debugPrint("[ESNOKE] device connected: " + noke.name)
          currentConnectedDevice = noke
      updateNokeStatus(status: NokeEvents.CONNECTED, noke: noke, message: "")
            break
        case .Syncing:
          debugPrint("[ESNOKE] device syncing: " + noke.name)
      updateNokeStatus(status: NokeEvents.SYNCING, noke: noke, message: "")
            break
        case .Unlocked:
          debugPrint("[ESNOKE] device unlocked: " + noke.name)
      updateNokeStatus(status: NokeEvents.UNLOCKED, noke: noke, message: "")
            break
        case .Disconnected:
          debugPrint("[ESNOKE] device disconnected: " + noke.name)
      updateNokeStatus(status: NokeEvents.DISCONNECTED, noke: noke, message: "")
            break
        default:
          debugPrint("[ESNOKE] device Undefine Something: " + noke.name)
            break
        }
    }

  func updateNokeStatus(status : String, noke : NokeDevice?, message: String?) -> Void {
      var params = ["status" : status]
      params["name"] = noke?.name ?? ""
      params["mac"] = noke?.mac ?? ""
      params["session"] = noke?.session ?? ""
      if (status == NokeEvents.ERROR) {
        params["error"] = message ?? ""
      }
    NativeNokeEmitter.shared?.emit("nokeServiceUpdated", params)
  }

  public func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
    debugPrint("[ESNOKE] error: \(error.rawValue)")
    debugPrint("[ESNOKE] error message: " + message)
    updateNokeStatus(status: NokeEvents.ERROR, noke: noke, message: message)
  }

  public func nokeDeviceDidShutdown(noke: NokeDevice, isLocked: Bool, didTimeout: Bool) {}

  public func didUploadData(result: Int, message: String) {}

  public func bluetoothManagerDidUpdateState(state: NokeManagerBluetoothState) {
    switch (state) {
        case NokeManagerBluetoothState.poweredOn:
            debugPrint("[NOKE] MANAGER ON")
            NokeDeviceManager.shared().startScanForNokeDevices()
            break
        case NokeManagerBluetoothState.poweredOff:
            debugPrint("[NOKE] MANAGER OFF")
            break
        default:
            debugPrint("[NOKE] MANAGER UNSUPPORTED")
            break
        }
    }
}


@objc(NativeNokeEmitter)
class NativeNokeEmitter: RCTEventEmitter {
  // Singleton reference used across the SDK
    public static var shared: NativeNokeEmitter?

    private var hasListeners = false

    override init() {
      super.init()
      print("[NOKE] Init")
      NativeNokeEmitter.shared = self
    }
  
  
  // React Native requires this for event setup
  override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  // Declare supported event names
  override func supportedEvents() -> [String]! {
    return [
      "nokeServiceUpdated",
    ]
  }

  override func startObserving() {
    print("[NOKE] Start observing events")
    hasListeners = true
  }

  override func stopObserving() {
    print("[NOKE] Stop observing events")
    hasListeners = false
  }

  /// Safe emitter helper — used by NativeNokeModule
  @objc func emit(_ name: String, _ body: [String: Any]) {
    guard hasListeners else {
      print("⚠️ [NOKE] No JS listeners for event: \(name)")
      return
    }
    sendEvent(withName: name, body: body)
  }
}


  
