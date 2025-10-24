//
//  File.swift
//  RNNoke
//
//  Created by Naing Mahar on 24/10/2025.
//

import Foundation
import NokeMobileLibrary

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

// -------------------------------------------------------------------------
// MARK: - NokeEventEmitter (The Actual Emitter Module)
// This module handles the low-level event communication with the React Native Bridge.
// -------------------------------------------------------------------------

@objc(NokeEventEmitter)
final class NokeEventEmitter: RCTEventEmitter {
    // This is the static reference that NokeModuleImpl uses to send events.
    @objc static var shared: NokeEventEmitter?
    
    override init() {
        super.init()
        // Initialize and set the static shared instance for access
        NokeEventEmitter.shared = self
    }
    
    // Required to conform to RCTEventEmitter. Called by React Native.
    override func startObserving() {
        // Inform the business logic class that JS listeners are active
        NokeModuleImpl.shared.hasListeners = true
    }

    override func stopObserving() {
        // Inform the business logic class that JS listeners are gone
        NokeModuleImpl.shared.hasListeners = false
    }

    override func supportedEvents() -> [String]! {
        // These are the event names exposed to JavaScript
        return ["nokeServiceUpdated"]
    }

    // Required by RCTBridge to know setup time
  @objc public override class func requiresMainQueueSetup() -> Bool {
        return true
    }
}


// -------------------------------------------------------------------------
// MARK: - NokeModuleImpl (TurboModule Implementation/Business Logic)
// This NSObject handles all Noke SDK interaction and is called by the C++ shim.
// -------------------------------------------------------------------------

// Renamed and set to match the name used in the Objective-C++ shim (RCTNativeNoke.mm)
@objc(NativeNokeImpl)
public class NativeNokeImpl: NSObject {

    // MARK: - Singleton and State

    @objc public static let shared = NokeModuleImpl()

    var currentConnectedDevice : NokeDevice? = nil
    var hasListeners: Bool = false // Tracks if JS is listening (set by NokeEventEmitter)

    // Private initializer to enforce singleton and set up the delegate
    private override init() {
        super.init()
        // Noke SDK delegate is set on this instance for receiving events
        NokeDeviceManager.shared().delegate = self
    }


    // MARK: - TurboModule Exposed Methods (Called by RCTNativeNoke.mm)

  // Matches @objc func initNoke() from your original code
  @objc public func initNoke(_ apiKey:String, productionBundleName:String) {
      NokeDeviceManager.shared().setAPIKey(apiKey)
      let bundleID = Bundle.main.bundleIdentifier
      if bundleID == productionBundleName {
            NokeDeviceManager.shared().setLibraryMode(NokeLibraryMode.PRODUCTION)
        } else {
            NokeDeviceManager.shared().setLibraryMode(NokeLibraryMode.SANDBOX)
        }
        
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
    @objc public func offlineUnlockDevice(withKey key: String, cmd: String, callback: RCTResponseSenderBlock) {
        guard let nokeDevice = self.currentConnectedDevice else {
            // Error case, send null for success result and a message for error result
            callback(["Empty Noke Device", NSNull()])
            return
        }
        let result = nokeDevice.offlineUnlock(key: key, command: cmd, addTimestamp: false)
        debugPrint("ESNOKE key: " + key)
        debugPrint("ESNOKE cmd: " + cmd)
        debugPrint("ESNOKE Offline unlock command sent " + result.description)
        
        // Success case: pass null for error, result description for success
        callback([NSNull(), result.description])
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
    // These methods are required by the C++ shim (RCTNativeNoke.mm) and delegate to the Emitter.
    @objc public func addListener(_ eventName: String) {
        // Calls the startObserving on the dedicated Emitter
        NokeEventEmitter.shared?.startObserving()
    }

    @objc public func removeListeners(_ count: Int) {
        // Calls the stopObserving on the dedicated Emitter when all listeners are gone
        if count == 0 {
            NokeEventEmitter.shared?.stopObserving()
        }
    }


    // MARK: - Event Emission Helper

    // Helper method to dispatch events to JavaScript via the dedicated Emitter
    internal func dispatch(name: String, body: Any?) {
        guard hasListeners, let emitter = NokeEventEmitter.shared else {
            print("NokeModuleImpl: Cannot send event '\(name)'. No listeners registered.")
            return
        }
        
        // Use the RCTEventEmitter to send the event
        emitter.sendEvent(withName: name, body: body)
    }

    // Status updater utility (based on your original updateNokeStatus method)
    internal func updateNokeStatus(status : String, noke : NokeDevice?, message: String?) -> Void {
        var params: [String: Any] = ["status" : status]
        params["name"] = noke?.name ?? ""
        params["mac"] = noke?.mac ?? ""
        params["session"] = noke?.session ?? ""
        if (status == NokeEvents.ERROR) {
            params["error"] = message ?? ""
        }
        
        // Dispatch event using the Emitter helper
        dispatch(name: "nokeServiceUpdated", body: params)
    }
}

// -------------------------------------------------------------------------
// MARK: - NokeDeviceManagerDelegate Extension
// -------------------------------------------------------------------------

extension NokeModuleImpl : NokeDeviceManagerDelegate {
  public func nokeReadyForFirmwareUpdate(noke: NokeDevice) {}

  public func nokeDeviceDidUpdateState(to state: NokeDeviceConnectionState, noke: NokeDevice) {
        switch state {
        case .Discovered:
            updateNokeStatus(status: NokeEvents.DISCOVERED, noke: noke, message: "")
            break
        case .Connected:
            debugPrint("ESNOKE device connected: " + noke.name)
            currentConnectedDevice = noke
            updateNokeStatus(status: NokeEvents.CONNECTED, noke: noke, message: "")
            break
        case .Syncing:
            debugPrint("ESNOKE device syncing: " + noke.name)
            updateNokeStatus(status: NokeEvents.SYNCING, noke: noke, message: "")
            break
        case .Unlocked:
            debugPrint("ESNOKE device unlocked: " + noke.name)
            updateNokeStatus(status: NokeEvents.UNLOCKED, noke: noke, message: "")
            break
        case .Disconnected:
            debugPrint("ESNOKE device disconnected: " + noke.name)
            currentConnectedDevice = nil // Important: clear current device on disconnect
            updateNokeStatus(status: NokeEvents.DISCONNECTED, noke: noke, message: "")
            break
        default:
            debugPrint("ESNOKE device Undefine Something: " + noke.name)
            break
        }
    }

  public func nokeErrorDidOccur(error: NokeDeviceManagerError, message: String, noke: NokeDevice?) {
        debugPrint("ESNOKE error: \(error.rawValue)")
        debugPrint("ESNOKE error message: " + message)
        updateNokeStatus(status: NokeEvents.ERROR, noke: noke, message: message)
    }

  public func nokeDeviceDidShutdown(noke: NokeDevice, isLocked: Bool, didTimeout: Bool) {}

  public func didUploadData(result: Int, message: String) {}

  public func bluetoothManagerDidUpdateState(state: NokeManagerBluetoothState) {
        switch (state) {
        case NokeManagerBluetoothState.poweredOn:
            debugPrint("NOKE MANAGER ON")
            NokeDeviceManager.shared().startScanForNokeDevices()
            break
        case NokeManagerBluetoothState.poweredOff:
            debugPrint("NOKE MANAGER OFF")
            updateNokeStatus(status: NokeEvents.BLUETOOTH_OFF, noke: nil, message: "Bluetooth Off")
            break
        default:
            debugPrint("NOKE MANAGER UNSUPPORTED")
            break
        }
    }
}
