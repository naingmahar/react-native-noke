//
//  RCTNativeNoke.mm
//  ExtraSpace
//
//  Created by Naing Mahar on 17/10/2025.
//

#import "RCTNativeNoke.h"
#import <React/RCTEventEmitter.h>
//#import "RCTDefaultReactNativeFactoryDelegate.h"
#import <React/RCTConvert.h> // Useful for converting complex types
#import <NokeMobileLibrary/NokeMobileLibrary.h>
#import <RNNoke/RNNoke-Swift.h>


@implementation RCTNativeNoke

RCT_EXPORT_MODULE(NativeRNNoke);

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

RCT_EXPORT_METHOD(addDevices:(NSArray<NSDictionary *> *)devices) {
  [[NativeNokeImpl shared] addDevices:devices];
}

RCT_EXPORT_METHOD(startScan) {
  [[NativeNokeImpl shared] startScan];
}

RCT_EXPORT_METHOD(stopScan) {
  [[NativeNokeImpl shared] stopScan];
}

RCT_EXPORT_METHOD(unlockDevice:(NSString *)command) {
  [[NativeNokeImpl shared] unlockDevice:command];
}

RCT_EXPORT_METHOD(offlineUnlockDevice:(NSString *)key
                  cmd:(NSString *)cmd) {
  [[NativeNokeImpl shared] offlineUnlockDeviceWithKey:key cmd:cmd];
}

RCT_EXPORT_METHOD(connectDevice:(NSString *)mac) {
  [[NativeNokeImpl shared] connectDevice:mac];
}

RCT_EXPORT_METHOD(disconnectDevice:(NSString *)deviceName
                  deviceMac:(NSString *)deviceMac) {
  [[NativeNokeImpl shared] disconnectDevice:deviceName deviceMac:deviceMac];
}

RCT_EXPORT_METHOD(clearDevices) {
  [[NativeNokeImpl shared] clearDevices];
}

RCT_EXPORT_METHOD(initNoke:(nonnull NSString *)apiKey
                  productionBundleName:(nonnull NSString *)productionBundleName) {
  [[NativeNokeImpl shared] initNoke:apiKey productionBundleName:productionBundleName];
}


// Required methods for manual listener delegation
RCT_EXTERN_METHOD(addListener:(NSString *)eventName)

RCT_EXTERN_METHOD(removeListeners:(double)count)

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeNokeSpecJSI>(params);
}

@end

