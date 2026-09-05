Pod::Spec.new do |s|
  s.name             = 'Sabycom'
  s.version          = '24.5200'
  s.summary          = 'Виджет чата поддержки.'
  s.description      = 'Виджет чата поддержки СБИС.'

  s.homepage         = 'https://github.com/saby/ios-sabycom'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tensor' => 'appdev2@tensor.ru' }
  s.source           = { :git => 'https://github.com/saby/ios-sabycom.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.swift_versions = ['5.4', '5.5']
  s.source_files = 'Sabycom/Classes/**/*'
  
  s.resource_bundles = { 'Sabycom' => ['Sabycom/Assets/**/*'] }

end