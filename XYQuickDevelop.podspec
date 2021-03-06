Pod::Spec.new do |s|  
  version            = "0.5.2"
  s.name             = "XYQuickDevelop"  
  s.version          = version  
  s.summary          = "A quick develop utility on iOS."  
  s.homepage         = "https://github.com/uxyheaven"  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }  
  s.author           = { "uxyheaven" => "uxyheaven@163.com" }  
  s.platform         = :ios, '7.0'
  s.source           = { :git => "https://github.com/uxyheaven/XYQuickDevelop.git", :tag => version } 
  s.source_files     = 'XYQuickDevelop/*'  , 'XYQuickDevelop/*/*' , 'XYQuickDevelop/*/*/*', 'XYQuickDevelop/*/*/*/*'
  s.requires_arc     = true  
end