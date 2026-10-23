source 'https://cdn.cocoapods.org/'

platform :ios, '17.0'
use_frameworks!

post_install do |installer|
  min_ios = 17.0

  installer.pods_project.build_configurations.each do |config|
    if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < min_ios
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < min_ios
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      end
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end

  fuse_path = "./Pods/HyperSDK/fuse.rb"
  if !File.exist?(fuse_path)
    fuse_path = "./Pods/HyperSDK/Fuse.rb"
  end
  if File.exist?(fuse_path)
    `ruby #{fuse_path}`
  end
end

target 'BoltEarthTestApp' do
  # Pinned to the 1.1.0 release tag so this sample keeps building after newer SDK releases.
  # To always use the latest SDK, replace `1.1.0` in the URL with `main`.
  # 'https://raw.githubusercontent.com/BOLT-EARTH/bolt-earth-ios-sdk/main/BoltEarthUiSdkCore.podspec'
  pod 'BoltEarthUiSdkCore',
    :podspec => 'https://raw.githubusercontent.com/BOLT-EARTH/bolt-earth-ios-sdk/1.1.0/BoltEarthUiSdkCore.podspec'
end
