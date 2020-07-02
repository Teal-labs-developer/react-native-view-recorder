require "json"

package = JSON.parse(File.read(File.join(__dir__, "../package.json")))

Pod::Spec.new do |s|
  s.name         = "RNViewRecorder"
  s.version      = "1.0.0"
  s.summary      = "RNViewRecorder"
  s.description  = package["description"]
  s.homepage     = "https://github.com/Teal-labs-developer/react-native-view-recorder"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "dhrumil@toddleapp.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/Teal-labs-developer/react-native-view-recorder.git", :tag => "#{s.version}" }
  s.source_files  = "RNViewRecorder/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  