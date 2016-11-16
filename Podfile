def shared_pods
    pod 'Alamofire', '~> 4.0.0'
    pod 'AlamofireImage', '~> 3.1.0'
    pod 'AlamofireObjectMapper', '~> 4.0'

    pod 'Kanna', '~> 2.0.0'
    pod 'KeychainSwift', '~> 7.0'
end

target 'antenna-tvos-extension' do
    platform :tvos, '9.0'
    use_frameworks!

    shared_pods
end

target 'antenna-tvos' do
    platform :tvos, '9.0'
    use_frameworks!

    shared_pods
    pod 'AutoScrollLabel', '~> 0.4'
end



#post_install do |installer|
#    installer.pods_project.targets.each do |target|
#        target.build_configurations.each do |config|
#            config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
#            config.build_settings['SWIFT_VERSION'] = '2.3'
#        end
#    end
#end
