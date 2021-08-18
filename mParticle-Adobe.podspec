Pod::Spec.new do |s|
    s.name             = "mParticle-Adobe"
    s.version          = "8.0.3"
    s.summary          = "Adobe integration for mParticle"

    s.description      = <<-DESC
                       This is the Adobe integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-adobe.git", :tag => s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"

    s.static_framework = true
    s.swift_version = "5.0"

    s.ios.deployment_target = "10.0"
    s.tvos.deployment_target = "10.0"
    s.default_subspec = 'Adobe'

    s.ios.pod_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.ios.user_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.tvos.pod_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }
    s.tvos.user_target_xcconfig = {
        'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
    }

    s.subspec 'Adobe' do |ss|
        ss.ios.source_files      = 'mParticle-Adobe/*.{h,m}'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.0'
        s.ios.framework = 'UIKit'
        ss.tvos.source_files      = 'mParticle-Adobe/*.{h,m}'
        ss.tvos.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.0'
        s.tvos.framework = 'UIKit'
    end

end