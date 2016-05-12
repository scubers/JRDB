Pod::Spec.new do |s|

    s.name                  = "JRDB"
    s.version               = "0.0.3"
    s.summary               = "The light packing of fmdb for my self"

    s.homepage              = "https://github.com/scubers/JRDB"
    s.license               = { :type => "MIT", :file => "LICENSE" }

    s.author                = { "jrwong" => "jr-wong@qq.com" }
    s.ios.deployment_target = "7.0"
    s.source                = { :git => "https://github.com/scubers/JRDB.git", :tag => "#{s.version}" }


    s.source_files          = "JRDB/JRDB/**/*.{h,m}"
    s.public_header_files   = "JRDB/JRDB/**/*.h"

    s.requires_arc          = true

    s.dependency 'FMDB', '~> 2.6.2'

end
