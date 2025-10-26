// NokeModuleImpl.swift

import Foundation
import React
import NokeMobileLibrary // Required import for Noke SDK functionality

// MARK: - Event Constants (From User Input)

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

// Renamed and set to match the name used in the Objective-C++ shim (RCTNativeNoke.mm)
@objc(NativeNokeImpl)
public class NativeNokeImpl: RCTEventEmitter {


  // MARK: - State and Initialization
  
  // Static reference for delegate callbacks to find the active module instance
    private static var instance: NativeNokeImpl?
    
    var currentConnectedDevice : NokeDevice? = nil
    var hasListeners: Bool = false // Tracks if JS is listening
  @objc public static let shared = NativeNokeImpl()
  var isNokeInitialized: Bool = false
  
    override init() {
        super.init()
      NativeNokeImpl.instance = self
        // Set the Noke SDK delegate to this instance immediately
        NokeDeviceManager.shared().delegate = self
    }
   
    // Matches @objc func initNoke() from your original code
    @objc(initNoke:productionBundleName:)
    public func initNoke(apiKey:String,productionBundleName:String) {
        NokeDeviceManager.shared().setAPIKey(apiKey)
        let bundleID = Bundle.main.bundleIdentifier
        if bundleID == productionBundleName {
            NokeDeviceManager.shared().setLibraryMode(NokeLibraryMode.PRODUCTION)
        } else {
            NokeDeviceManager.shared().setLibraryMode(NokeLibraryMode.SANDBOX)
        }
      self.isNokeInitialized = true
        // Use our internal status updater to send the initialization event
       updateNokeStatus(status: "initialized", noke: nil, message: "SDK Initialized")
    }

    @objc public func addDevices(_ devices: [NSDictionary]){
        debugPrint("ESNOKE Adding devices to Noke")
        NokeDeviceManager.shared().removeAllNoke()
        for noke in devices {
            let deviceName = noke["name"]
            let deviceMac = noke["mac"]
            let device = NokeDevice.init(name: "\(deviceName!)", mac: "\(deviceMac!)")
            NokeDeviceManager.shared().addNoke(device!)
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

    @objc public func unlockDevice(_ command : String) ->Void {
        guard let nokeDevice = self.currentConnectedDevice else {
            return
        }
        nokeDevice.sendCommands(command)
        debugPrint("ESNOKE Unlock command sent")
    }

    // Adjusted signature to match the TurboModule specification: (withKey: cmd: callback:)
    @objc public func offlineUnlockDevice(withKey key: String, cmd: String) {
        guard let nokeDevice = self.currentConnectedDevice else {
            // Error case, send null for success result and a message for error result
            return
        }
        let result = nokeDevice.offlineUnlock(key: key, command: cmd, addTimestamp: false)
        debugPrint("ESNOKE key: " + key)
        debugPrint("ESNOKE cmd: " + cmd)
        debugPrint("ESNOKE Offline unlock command sent " + result.description)
        
        // Success case: pass null for error, result description for success
        return
    }

    @objc public func connectDevice(_ mac : String) {
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

    // --- TurboModule Event Plumbing ---
  
  // Required by RCTEventEmitter
  override public func supportedEvents() -> [String]! {
      // You only send one event type, so declare it here.
      return ["nokeServiceUpdated"]
  }

  // Required by RCTEventEmitter
  override public func startObserving() {
      super.startObserving()
      self.hasListeners = true

      // Check flag and send deferred event
      if self.isNokeInitialized {
           DispatchQueue.main.async {
               self.updateNokeStatus(status: "initialized", noke: nil, message: "SDK Initialized")
           }
      }
  }

  // Required by RCTEventEmitter
  override public func stopObserving() {
      // Called when the last JS listener is removed
      super.stopObserving()
      self.hasListeners = false // Keep your internal flag
  }

  // Required by RCTBridge to know setup time
  @objc public override class func requiresMainQueueSetup() -> Bool {
      return true
  }


    // MARK: - Event Emission Helper

    // Status updater utility (based on your original updateNokeStatus method)
    internal func updateNokeStatus(status : String, noke : NokeDevice?, message: String?) -> Void {
      
      // Check the hasListeners flag set by start/stopObserving
        if !self.hasListeners {
            print("NativeNokeImpl: Cannot send event '\(status)'. No listeners registered.")
            return
        }
        var params: [String: Any] = ["status" : status]
        params["name"] = noke?.name ?? ""
        params["mac"] = noke?.mac ?? ""
        params["session"] = noke?.session ?? ""
        if (status == NokeEvents.ERROR) {
            params["error"] = message ?? ""
        }
        
        // Dispatch event using the Emitter helper
        self.sendEvent(withName: "nokeServiceUpdated", body: params)
    }
}




// -------------------------------------------------------------------------
// MARK: - NokeDeviceManagerDelegate Extension
// -------------------------------------------------------------------------

extension NativeNokeImpl : NokeDeviceManagerDelegate {
  
  // Ensure delegate methods use the static instance reference to call the helper
  private func delegateUpdateStatus(status : String, noke : NokeDevice?, message: String?) {
    NativeNokeImpl.instance?.updateNokeStatus(status: status, noke: noke, message: message)
  }

  public func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        switch state {
        case .Discovered:
            delegateUpdateStatus(status: NokeEvents.DISCOVERED, noke: noke, message: "")
            break
        case .Connected:
            debugPrint("ESNOKE device connected: " + noke.name)
            currentConnectedDevice = noke
            delegateUpdateStatus(status: NokeEvents.CONNECTED, noke: noke, message: "")
            break
        case .Syncing:
            debugPrint("ESNOKE device syncing: " + noke.name)
            delegateUpdateStatus(status: NokeEvents.SYNCING, noke: noke, message: "")
            break
        case .Unlocked:
            debugPrint("ESNOKE device unlocked: " + noke.name)
            delegateUpdateStatus(status: NokeEvents.UNLOCKED, noke: noke, message: "")
            break
        case .Disconnected:
            debugPrint("ESNOKE device disconnected: " + noke.name)
            currentConnectedDevice = nil // Important: clear current device on disconnect
            delegateUpdateStatus(status: NokeEvents.DISCONNECTED, noke: noke, message: "")
            break
        default:
            debugPrint("ESNOKE device Undefine Something: " + noke.name)
            break
        }
    }

  public func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
        debugPrint("ESNOKE error: \(error.rawValue)")
        debugPrint("ESNOKE error message: " + message)
        delegateUpdateStatus(status: NokeEvents.ERROR, noke: noke, message: message)
    }


  public func bluetoothManagerDidUpdateState(state: NokeManagerBluetoothState) {
        switch (state) {
        case NokeManagerBluetoothState.poweredOn:
            debugPrint("NOKE MANAGER ON")
            NokeDeviceManager.shared().startScanForNokeDevices()
            break
        case NokeManagerBluetoothState.poweredOff:
            debugPrint("NOKE MANAGER OFF")
            delegateUpdateStatus(status: NokeEvents.BLUETOOTH_OFF, noke: nil, message: "Bluetooth Off")
            break
        default:
          debugPrint("NOKE MANAGER UNSUPPORTED/UNKNOWN - State: \(state.rawValue)")
          delegateUpdateStatus(status: NokeEvents.ERROR, noke: nil, message: "Bluetooth Unsupported or Unknown State.")
          break
        }
    }
  
  public func nokeReadyForFirmwareUpdate(noke: NokeDevice) {}
  public func nokeDeviceDidShutdown(noke: NokeDevice, isLocked: Bool, didTimeout: Bool) {}
  public func didUploadData(result: Int, message: String) {}
}
