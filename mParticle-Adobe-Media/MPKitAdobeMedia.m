#import "MPKitAdobeMedia.h"
#import "MPIAdobe.h"
#if defined(__has_include) && __has_include(<AEPCore/AEPCore.h>)
#import <AEPCore/AEPCore.h>
#elseif defined(__has_include) && __has_include(AEPCore.h)
#import "AEPCore.h"
#else
@import AEPCore;
#endif
#if defined(__has_include) && __has_include(<AEPAnalytics/AEPAnalytics.h>)
#import <AEPAnalytics/AEPAnalytics.h>
#elseif defined(__has_include) && __has_include(AEPAnalytics.h)
#import "AEPAnalytics.h"
#else
@import AEPAnalytics;
#endif
#if defined(__has_include) && __has_include(<AEPMedia/AEPMedia.h>)
#import <AEPMedia/AEPMedia.h>
#elseif defined(__has_include) && __has_include(AEPMedia.h)
#import "AEPMedia.h"
#else
@import AEPMedia;
#endif
#if defined(__has_include) && __has_include(<AEPUserProfile/AEPUserProfile.h>)
#import <AEPUserProfile/AEPUserProfile.h>
#elseif defined(__has_include) && __has_include(AEPUserProfile.h)
#import "AEPUserProfile.h"
#else
@import AEPUserProfile;
#endif
#if defined(__has_include) && __has_include(<AEPIdentity/AEPIdentity.h>)
#import <AEPIdentity/AEPIdentity.h>
#elseif defined(__has_include) && __has_include(AEPIdentity.h)
#import "AEPIdentity.h"
#else
@import AEPIdentity;
#endif
#if defined(__has_include) && __has_include(<AEPLifecycle/AEPLifecycle.h>)
#import <AEPLifecycle/AEPLifecycle.h>
#elseif defined(__has_include) && __has_include(AEPLifecycle.h)
#import "AEPLifecycle.h"
#else
@import AEPLifecycle;
#endif
#if defined(__has_include) && __has_include(<AEPSignal/AEPSignal.h>)
#import <AEPSignal/AEPSignal.h>
#elseif defined(__has_include) && __has_include(AEPSignal.h)
#import "AEPSignal.h"
#else
@import AEPSignal;
#endif
#if defined(__has_include) && __has_include(<AEPServices/AEPServices.h>)
#import <AEPServices/AEPServices.h>
#elseif defined(__has_include) && __has_include(AEPServices.h)
#import "AEPServices.h"
#else
@import AEPServices;
#endif

@import mParticle_Apple_Media_SDK;
@import mParticle_Apple_SDK;

static NSString *const marketingCloudIdIntegrationAttributeKey = @"mid";
static NSString *const blobIntegrationAttributeKey = @"aamb";
static NSString *const locationHintIntegrationAttributeKey = @"aamlh";
static NSString *const organizationIdConfigurationKey = @"organizationID";
static NSString *const launchAppIdKey = @"launchAppId";
static NSString *const audienceManagerServerConfigurationKey = @"audienceManagerServer";

#pragma mark - MPIAdobeApi
@implementation MPIAdobeApi

@synthesize marketingCloudID;

@end

@interface MPKitAdobeMedia ()

@property (nonatomic) NSString *organizationId;
@property (nonatomic) MPIAdobe *adobe;
@property id<AEPMediaTracker> mediaTracker;
@property (nonatomic) NSString *pushToken;
@property (nonatomic) NSString *audienceManagerServer;

@end

@implementation MPKitAdobeMedia

+ (NSNumber *)kitCode {
    return @124;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AdobeMedia" className:NSStringFromClass(self)];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus *)execStatus:(MPKitReturnCode)returnCode {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.class.kitCode returnCode:returnCode];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    _organizationId = [configuration[organizationIdConfigurationKey] copy];
    if (!_organizationId) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }
    
    if (!_organizationId.length) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }

    _audienceManagerServer = [configuration[audienceManagerServerConfigurationKey] copy];

    _configuration = configuration;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    [self start];

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (void)start {
    static dispatch_once_t kitPredicate;

    NSString *launchAppId  = _configuration[launchAppIdKey];
    
    dispatch_once(&kitPredicate, ^{
        [AEPMobileCore setLogLevel:AEPLogLevelDebug];
        if (launchAppId != nil) {
            [AEPMobileCore registerExtensions:@[AEPMobileAnalytics.class, AEPMobileMedia.class, AEPMobileUserProfile.class, AEPMobileSignal.class, AEPMobileLifecycle.class, AEPMobileIdentity.class] completion:^{
                [AEPMobileCore configureWithAppId:launchAppId];
                NSMutableDictionary* config = [NSMutableDictionary dictionary];
                self.mediaTracker = [AEPMobileMedia createTrackerWithConfig:config];;
                NSLog(@"mParticle -> Adobe Media configured");
            }];
        } else {
            NSLog(@"mParticle -> Adobe Media not configured");
        }

        self->_started = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

- (id const)providerKitInstance {
    if (![self started]) {
        return nil;
    }

    /*
        If your company SDK instance is available and is applicable (Please return nil if your SDK is based on class methods)
     */
    MPIAdobeApi *adobeApi = [[MPIAdobeApi alloc] init];
    adobeApi.marketingCloudID = [self marketingCloudIdFromIntegrationAttributes];
    return adobeApi;
}

#pragma mark Base events
 - (MPKitExecStatus *)logBaseEvent:(MPBaseEvent *)event {
     MPKitExecStatus *status = nil;
     if ([event isKindOfClass:[MPMediaEvent class]]) {
         MPMediaEvent *mediaEvent = (MPMediaEvent *)event;

         status = [self routeMediaEvent:mediaEvent];
     } else if ([event isKindOfClass:[MPEvent class]]) {
         status = [self execStatus:MPKitReturnCodeSuccess];
     } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
         status = [self execStatus:MPKitReturnCodeSuccess];
     }

     if (!status) {
         status = [self execStatus:MPKitReturnCodeFail];
     }
     return status;
 }

- (MPKitExecStatus *)routeMediaEvent:(MPMediaEvent *)mediaEvent {
    switch (mediaEvent.mediaEventName) {
        case MPMediaEventNamePlay:
            [_mediaTracker trackPlay];
            break;
        case MPMediaEventNamePause:
            [_mediaTracker trackPause];
            break;
        case MPMediaEventNameSessionStart: {
            NSString *streamType = [self streamTypeForMediaEvent:mediaEvent];
            AEPMediaType contentType = [self contentTypeForMediaEvent:mediaEvent];
            
            NSDictionary *mediaObject = [AEPMobileMedia createMediaObjectWith:mediaEvent.mediaContentTitle id:mediaEvent.mediaContentId length:mediaEvent.duration.doubleValue streamType:streamType mediaType:contentType];

            NSMutableDictionary *mediaMetadata = [[NSMutableDictionary alloc] init];

            [_mediaTracker trackSessionStart:mediaObject metadata:mediaMetadata];
            break;
        }
        case MPMediaEventNameSessionEnd:
            [_mediaTracker trackSessionEnd];
            break;
        case MPMediaEventNameSeekStart: {
            [_mediaTracker trackEvent:AEPMediaEventSeekStart info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameSeekEnd: {
            [_mediaTracker trackEvent:AEPMediaEventSeekComplete info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameBufferStart: {
            [_mediaTracker trackEvent:AEPMediaEventBufferStart info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameBufferEnd: {
            [_mediaTracker trackEvent:AEPMediaEventBufferComplete info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameUpdatePlayheadPosition:
            [_mediaTracker updateCurrentPlayhead:mediaEvent.playheadPosition.doubleValue];
            break;
        case MPMediaEventNameAdClick:
            //Media does not track Ad interaction
            break;
        case MPMediaEventNameAdBreakStart: {
            NSDictionary* adBreakObject = [AEPMobileMedia createAdBreakObjectWith:mediaEvent.adBreak.title position:1 startTime:0];
            
            [_mediaTracker trackEvent:AEPMediaEventAdBreakStart info:adBreakObject metadata:nil];
            break;
        }
        case MPMediaEventNameAdBreakEnd: {
            [_mediaTracker trackEvent:AEPMediaEventAdBreakComplete info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameAdStart: {
            NSDictionary* adObject = [AEPMobileMedia createAdObjectWith:mediaEvent.adContent.title id:mediaEvent.adContent.id position:mediaEvent.adContent.position.doubleValue length:mediaEvent.adContent.duration.doubleValue];
            NSMutableDictionary* adMetadata = [[NSMutableDictionary alloc] init];
            
            if (mediaEvent.adContent.advertiser != nil) {
                [adMetadata setObject:mediaEvent.adContent.advertiser forKey:AEPAdMetadataKeys.ADVERTISER];
            }
            if (mediaEvent.adContent.campaign != nil) {
                [adMetadata setObject:mediaEvent.adContent.campaign forKey:AEPAdMetadataKeys.CAMPAIGN_ID];
            }
            if (mediaEvent.adContent.creative != nil) {
                [adMetadata setObject:mediaEvent.adContent.creative forKey:AEPAdMetadataKeys.CREATIVE_ID];
            }
            if (mediaEvent.adContent.placement != nil) {
                [adMetadata setObject:mediaEvent.adContent.placement forKey:AEPAdMetadataKeys.PLACEMENT_ID];
            }
            if (mediaEvent.adContent.siteId != nil) {
                [adMetadata setObject:mediaEvent.adContent.siteId forKey:AEPAdMetadataKeys.CREATIVE_URL];
            }
            
            [_mediaTracker trackEvent:AEPMediaEventAdStart info:adObject metadata:adMetadata];
            break;
        }
        case MPMediaEventNameAdEnd: {
            [_mediaTracker trackEvent:AEPMediaEventAdComplete info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameAdSkip: {
            [_mediaTracker trackEvent:AEPMediaEventAdSkip info:nil metadata:nil];
            break;
        }
        case MPMediaEventNameSegmentStart: {
            NSDictionary* chapterObject = [AEPMobileMedia createChapterObjectWith:mediaEvent.segment.title position:mediaEvent.segment.index length:mediaEvent.segment.duration.doubleValue startTime:mediaEvent.playheadPosition.doubleValue];
            
            [_mediaTracker trackEvent:AEPMediaEventChapterStart info:chapterObject metadata:nil];
            break;
        }
        case MPMediaEventNameSegmentSkip: {
            [_mediaTracker trackEvent:AEPMediaEventChapterSkip info:nil metadata:nil];
           break;
       }
        case MPMediaEventNameSegmentEnd:  {
            [_mediaTracker trackEvent:AEPMediaEventChapterComplete info:nil metadata:nil];
           break;
       }
        case MPMediaEventNameUpdateQoS: {
            NSDictionary* mediaQoS = [AEPMobileMedia createQoEObjectWith:mediaEvent.qos.bitRate.doubleValue startTime:mediaEvent.qos.startupTime.doubleValue fps:mediaEvent.qos.fps.doubleValue droppedFrames:mediaEvent.qos.droppedFrames.doubleValue];
            
            [_mediaTracker updateQoEObject:mediaQoS];
           break;
       }
        default:
            break;
    }

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitAdobeMedia kitCode] returnCode:MPKitReturnCodeSuccess];
}

#pragma mark Private Methods
- (NSString *)streamTypeForMediaEvent:(MPMediaEvent *)mediaEvent  {
    if (mediaEvent.streamType == MPMediaStreamTypeOnDemand) {
        if (mediaEvent.contentType == MPMediaContentTypeVideo) {
            return AEPMediaStreamType.VOD;
        } else {
            return AEPMediaStreamType.AOD;
        }
    } else if (mediaEvent.streamType == MPMediaStreamTypeLinear) {
        return AEPMediaStreamType.LINEAR;
    } else if (mediaEvent.streamType == MPMediaStreamTypePodcast) {
        return AEPMediaStreamType.PODCAST;
    } else if (mediaEvent.streamType == MPMediaStreamTypeAudiobook) {
        return AEPMediaStreamType.AUDIOBOOK;
    } else {
        return AEPMediaStreamType.LIVE;
    }
}

- (AEPMediaType)contentTypeForMediaEvent:(MPMediaEvent *)mediaEvent  {
    if (mediaEvent.contentType == MPMediaContentTypeVideo) {
        return AEPMediaTypeVideo;
    } else {
        return AEPMediaTypeAudio;
    }
}

- (void)didEnterBackground:(NSNotification *)notification {
    [self sendNetworkRequest];
}

- (void)willTerminate:(NSNotification *)notification {
    [self sendNetworkRequest];
}

- (FilteredMParticleUser *)currentUser {
    return [[self kitApi] getCurrentUserWithKit:self];
}

- (NSString *)marketingCloudIdFromIntegrationAttributes {
    NSDictionary *dictionary = _kitApi.integrationAttributes;
    return dictionary[marketingCloudIdIntegrationAttributeKey];
}

- (NSString *)advertiserId {
    NSString *advertiserId = nil;
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    
    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];
        
        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL advertisingTrackingEnabled = (BOOL)[adIdentityManager performSelector:selector];
        if (advertisingTrackingEnabled) {
            selector = NSSelectorFromString(@"advertisingIdentifier");
            advertiserId = [[adIdentityManager performSelector:selector] UUIDString];
        }
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }
    
    return advertiserId;
}

- (NSString *)pushToken {
    return _pushToken;
}

- (void)sendNetworkRequest {
    NSString *marketingCloudId = [self marketingCloudIdFromIntegrationAttributes];
    if (!marketingCloudId) {
        marketingCloudId = [_adobe marketingCloudIdFromUserDefaults];
        if (marketingCloudId.length) {
            [[MParticle sharedInstance] setIntegrationAttributes:@{marketingCloudIdIntegrationAttributeKey: marketingCloudId} forKit:[[self class] kitCode]];
        }
    }
    
    NSString *advertiserId = [self advertiserId];
    NSString *pushToken = [self pushToken];
    FilteredMParticleUser *user = [self currentUser];
    NSDictionary *userIdentities = user.userIdentities;
    [_adobe sendRequestWithMarketingCloudId:marketingCloudId advertiserId:advertiserId pushToken:pushToken organizationId:_organizationId userIdentities:userIdentities audienceManagerServer:_audienceManagerServer completion:^(NSString *marketingCloudId, NSString *locationHint, NSString *blob, NSError *error) {
        if (error) {
            NSLog(@"mParticle -> Adobe kit request failed with error: %@", error);
            return;
        }
        
        NSMutableDictionary *integrationAttributes = [NSMutableDictionary dictionary];
        NSString *existingMarketingCloudId = [self marketingCloudIdFromIntegrationAttributes];
        if (marketingCloudId.length && existingMarketingCloudId.length == 0) {
            [integrationAttributes setObject:marketingCloudId forKey:marketingCloudIdIntegrationAttributeKey];
        } else {
            [integrationAttributes setObject:existingMarketingCloudId forKey:marketingCloudIdIntegrationAttributeKey];
        }
        if (locationHint.length) {
            [integrationAttributes setObject:locationHint forKey:locationHintIntegrationAttributeKey];
        }
        if (blob.length) {
            [integrationAttributes setObject:blob forKey:blobIntegrationAttributeKey];
        }
        
        if (integrationAttributes.count) {
            [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
        }
    }];
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    _pushToken = [[NSString alloc] initWithData:deviceToken encoding:NSUTF8StringEncoding];
    [self sendNetworkRequest];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    [self sendNetworkRequest];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)didBecomeActive {
    [self sendNetworkRequest];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdobe) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (BOOL)shouldDelayMParticleUpload {
    NSString *marketingCloudId = [self marketingCloudIdFromIntegrationAttributes];
    return marketingCloudId.length == 0;
}

- (MPKitAPI *)kitApi {
    if (_kitApi == nil) {
        _kitApi = [[MPKitAPI alloc] init];
    }
    
    return _kitApi;
}

@end
