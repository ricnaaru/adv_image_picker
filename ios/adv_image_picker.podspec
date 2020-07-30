#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'adv_image_picker'
  s.version          = '0.3.1'
  s.summary          = 'An advanced image picker with crop'
  s.description      = <<-DESC
An advanced image picker with crop
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  s.pod_target_xcconfig = { "DEFINES_MODULE" => "YES" }
  
  s.ios.deployment_target = '9.0'
end

