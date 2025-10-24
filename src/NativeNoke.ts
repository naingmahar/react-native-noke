import { TurboModuleRegistry, type CodegenTypes, type TurboModule} from 'react-native';


// Define the structure of the event payload
export type NokeUpdateEvent = {
    status: string;
    name: string;
    mac: string;
    session: string;
    error?: string; // Optional error message
};


// Define the interface for the Turbo Module
export interface Spec extends TurboModule {
    // 1. Methods (The functions callable from JS)
    initNoke(apiKey:string,productionBundleName:string): void;
    addDevices(devices: ReadonlyArray<{ name: string; mac: string }>): void;
    startScan(): void;
    stopScan(): void;
    unlockDevice(command: string): void;
    
    // Callbacks are still supported, but Promises are generally preferred in new modules.
    offlineUnlockDevice(key: string, cmd: string): void;
    
    connectDevice(mac: string): void;
    disconnectDevice(deviceName: string, deviceMac: string): void;
    clearDevices(): void;

    // 2. Event Emitter (The New Architecture way to expose events)
    // NOTE: Codegen handles the 'addListener' and 'removeListeners' methods automatically.
    // You only need to define the custom event name and its payload type.
    readonly onNokeServiceUpdate: CodegenTypes.EventEmitter<NokeUpdateEvent>;
}

export default TurboModuleRegistry.get<Spec>(
    'NativeRNNoke' // This MUST match the name exposed in the native code
) as Spec ;
