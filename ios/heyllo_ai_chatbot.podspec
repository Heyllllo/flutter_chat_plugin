# heyllo_ai_chatbot.podspec

Pod::Spec.new do |s|
  s.name             = 'heyllo_ai_chatbot'
  s.version          = '0.0.3' # Match your pubspec.yaml version
  s.summary          = 'A short description of heyllo_ai_chatbot.' # Add a brief summary
  s.description      = <<-DESC
A longer description of the plugin goes here.
                       DESC
  s.homepage         = 'http://example.com' # Optional: Link to your plugin's homepage or repo
  s.license          = { :file => '../LICENSE' } # Assumes you have a LICENSE file at the root
  s.author           = { 'Your Name' => 'your.email@example.com' } # Your details
  s.source           = { :path => '.' } # Indicates source is the current directory
  s.source_files = 'Classes/**/*' # Assumes native code is in ios/Classes (even if empty for now)
  s.dependency 'Flutter'
  s.platform = :ios, '11.0' # Set a minimum iOS deployment target

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0' # If you use Swift in the Classes folder
end