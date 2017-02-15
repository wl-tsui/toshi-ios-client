source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'

abstract_target 'CocoaPods' do
  pod 'SignalServiceKit', git: 'https://github.com/WhisperSystems/SignalServiceKit.git'
  pod 'SocketRocket', git: 'https://github.com/facebook/SocketRocket.git'

  target 'Development' do
  end

  target 'Distribution' do
  end
end

post_install do |installer|
  puts "Add embed swift standard libraries option to targets"
    installer.pods_project.targets.each do |target|
         target.build_configurations.each do |config|
             config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
         end
     end

    puts "Set Swift version to 3.0"
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end

    puts "Add code signing to pods"
    installer.pods_project.build_configurations.each do |build_configuration|
        build_configuration.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = "#{ENV["PROVISIONING_PROFILE_TEAM_ID"]}"
    end
end
