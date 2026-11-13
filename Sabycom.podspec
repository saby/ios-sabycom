#
# Be sure to run `pod lib lint Sabycom.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Sabycom'
  s.version          = '0.1.0'
  s.summary          = 'Виджет чата поддержки для мобильных приложений.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Виджет чата поддержки для мобильных приложений'

  s.homepage         = 'https://github.com/saby/ios-sabycom'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'iskhakovsa' => 'sa.ishakov@tensor.ru' }
  s.source           = { :git => 'https://github.com/saby/ios-sabycom.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.2'

  s.source_files = 'ios-sabycom-sdk/Sabycom/Classes/**/*'
  
   s.resource_bundles = {
     'Sabycom' => ['ios-sabycom-sdk/Sabycom/Assets/**/*']
   }

end
