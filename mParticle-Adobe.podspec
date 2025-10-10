Pod::Spec.new do |s|
    s.name             = "mParticle-Adobe"
    s.version          = "8.2.3"
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

    s.default_subspec = 'AdobeMedia'

    s.ios.deployment_target = "12.0"
    s.tvos.deployment_target = "12.0"

    s.subspec 'Adobe' do |ss|
        ss.ios.source_files = 'mParticle-Adobe/*.{h,m}'
        ss.ios.resource_bundles  = { 'mParticle-Adobe-Privacy' => ['mParticle-Adobe/PrivacyInfo.xcprivacy'] }
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
        
        ss.tvos.source_files = 'mParticle-Adobe/*.{h,m}'
        ss.tvos.resource_bundles  = { 'mParticle-Adobe-Privacy' => ['mParticle-Adobe/PrivacyInfo.xcprivacy'] }
        ss.tvos.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    end

    s.subspec 'AdobeMedia' do |ss|
        ss.ios.source_files = 'mParticle-Adobe-Media/*.{h,m}'
        ss.ios.resource_bundles  = { 'mParticle-Adobe-Media-Privacy' => ['mParticle-Adobe-Media/PrivacyInfo.xcprivacy'] }
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
        ss.ios.dependency 'mParticle-Apple-Media-SDK', '~> 1.5'
        ss.ios.dependency 'AEPMedia', '~> 5.0'
        ss.ios.dependency 'AEPAnalytics', '~> 5.0'
        ss.ios.dependency 'AEPCore', '~> 5.0'
        ss.ios.dependency 'AEPUserProfile', '~> 5.0'
        ss.ios.dependency 'AEPIdentity', '~> 5.0'
        ss.ios.dependency 'AEPLifecycle', '~> 5.0'
        ss.ios.dependency 'AEPSignal', '~> 5.0'

        # AdobeMedia is not supported on tvOS, so just pull in standard Adobe Kit code
        ss.tvos.source_files = 'mParticle-Adobe/*.{h,m}'
        ss.tvos.resource_bundles  = { 'mParticle-Adobe-Privacy' => ['mParticle-Adobe/PrivacyInfo.xcprivacy'] }
        ss.tvos.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    end
end
