Pod::Spec.new do |s|
  s.name    = 'TCJSBridge'
  s.version = '0.0.1'
  s.summary = 'JavaScriptCore extension'
  s.license = 'Apache License 2.0'
  s.author  = { 'sodas tsai' => 'sodas@icloud.com' }

  s.homepage = 'https://github.com/sodastsai/tcjsbridge'
  s.source   = {
    :git => 'git@github.com:sodastsai/tcjsbridge.git',
    :tag => "#{s.version.to_s}"
  }

  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit', 'JavaScriptCore'

  s.source_files         = 'JSBridge/**/*.{h,m}'
  s.public_header_files  = 'JSBridge/**/*.h'
  s.private_header_files = 'JSBridge/**/*_Internal.h'
  s.resources            = 'JSBridge/**/*.{js}'
  s.preserve_paths       = 'jsbridge.d.ts'

  s.dependency 'BenzeneFoundation/UIKit', '~> 0.5.41'
  s.dependency 'libextobjc'
end
