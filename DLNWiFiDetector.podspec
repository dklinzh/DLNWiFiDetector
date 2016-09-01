#
# Be sure to run `pod lib lint DLNWiFiDetector.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DLNWiFiDetector'
  s.version          = '0.1.1'
  s.summary          = 'WiFi scanning for iOS devices.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/<GITHUB_USERNAME>/DLNWiFiDetector'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Daniel' => 'linzhdk@gmail.com' }
  s.source           = { :git => 'https://github.com/<GITHUB_USERNAME>/DLNWiFiDetector.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '7.0'

  s.source_files = 'DLNWiFiDetector/Classes/**/*'

  s.requires_arc = true

  non_arc_files = 'DLNWiFiDetector/Classes/SimplePing.*'
  s.exclude_files = non_arc_files
  s.subspec 'non-arc' do |sna|
    sna.requires_arc = false
    sna.source_files = non_arc_files
  end

  # s.resource_bundles = {
  #   'DLNWiFiDetector' => ['DLNWiFiDetector/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
