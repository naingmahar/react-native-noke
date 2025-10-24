require "json"

# Set a minimum iOS version. The current minimum supported by React Native is often 12.4 or 13.0.
# A safe modern default is often used here.
min_ios_version_supported = '15.0'

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "RNNoke"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/naingmahar/react-native-noke.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,cpp,swift}"
  s.swift_version = '5.0'
  s.requires_arc = true
  s.private_header_files = "ios/**/*.h"

  s.dependency "React-Core"
  s.dependency "NokeMobileLibrary", "~> 0.9.2"

  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'DEFINES_MODULE' => 'YES',
    'IPHONEOS_DEPLOYMENT_TARGET' => min_ios_version_supported
  }
  # Since you are using Turbo Modules, you might also need to configure codegen:
  # s.pod_target_xcconfig = {
  #   'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) RCT_NEW_ARCH_ENABLED=1',
  #   'IPHONEOS_DEPLOYMENT_TARGET' => min_ios_version_supported,
  # }

  install_modules_dependencies(s)
end
