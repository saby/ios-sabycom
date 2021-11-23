Pod::Spec.new do |s|
  s.name             = 'Sabycom'
  s.version          = '21.5160'
  s.summary          = 'Виджет чата поддержки.'
  s.description      = 'Виджет чата поддержки СБИС.'

  s.homepage         = 'https://github.com/saby/ios-sabycom'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'iskhakovsa' => 'sa.ishakov@tensor.ru' }
  s.source           = { :git => 'https://github.com/saby/ios-sabycom.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.2'

  s.swift_versions = ['5.4', '5.5']
  s.source_files = 'Sabycom/Classes/**/*'
  
  s.resource_bundles = {
    'Sabycom' => ['Sabycom/Assets/**/*']
  }

end
