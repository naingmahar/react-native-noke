//
//  RCTNativeNoke.mm
//  ExtraSpace
//
//  Created by Naing Mahar on 17/10/2025.
//

#import "RCTNativeNoke.h"
#import <React/RCTBridge.h> // Include bridge headers
#import <RNNoke/RNNoke-Swift.h>

@implementation RCTNativeNoke

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

RCT_EXPORT_METHOD(addDevices:(NSArray<NSDictionary *> *)devices) {
  [[NativeNokeModule shared] addDevices:devices];
}

RCT_EXPORT_METHOD(startScan) {
  [[NativeNokeModule shared] startScan];
}

RCT_EXPORT_METHOD(stopScan) {
  [[NativeNokeModule shared] stopScan];
}

RCT_EXPORT_METHOD(unlockDevice:(NSString *)command) {
  [[NativeNokeModule shared] unlockDevice:command];
}

RCT_EXPORT_METHOD(offlineUnlockDevice:(NSString *)key
                  cmd:(NSString *)cmd) {
  [[NativeNokeModule shared] offlineUnlockDevice:key cmd:cmd];
}

RCT_EXPORT_METHOD(connectDevice:(NSString *)mac) {
  [[NativeNokeModule shared] connectDevice:mac];
}

RCT_EXPORT_METHOD(disconnectDevice:(NSString *)deviceName
                  deviceMac:(NSString *)deviceMac) {
  [[NativeNokeModule shared] disconnectDevice:deviceName deviceMac:deviceMac];
}

RCT_EXPORT_METHOD(clearDevices) {
  [[NativeNokeModule shared] clearDevices];
}

RCT_EXPORT_METHOD(initNoke:(nonnull NSString *)apiKey
                  productionBundleName:(nonnull NSString *)productionBundleName) {
  [[NativeNokeModule shared] initNoke:apiKey productionBundleName:productionBundleName];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeNokeSpecJSI>(params);
}

@end
