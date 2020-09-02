#import "MPKitAdobeMedia.h"
#import "MPIAdobe.h"
#import "ACPCore.h"
#import "ACPAnalytics.h"
#import "ACPMedia.h"
#import "ACPUserProfile.h"
#import "ACPIdentity.h"
#import "ACPLifecycle.h"
#import "ACPSignal.h"
#import "ACPMediaConstants.h"

@import mParticle_Apple_Media_SDK;
@import mParticle_Apple_SDK;

static NSString *const marketingCloudIdIntegrationAttributeKey = @"mid";
static NSString *const blobIntegrationAttributeKey = @"aamb";
static NSString *const locationHintIntegrationAttributeKey = @"aamlh";
static NSString *const organizationIdConfigurationKey = @"organizationID";
static NSString *const launchAppIdKey = @"launchAppId";

#pragma mark - MPIAdobeApi
@implementation MPIAdobeApi

@synthesize marketingCloudID;

@end

@interface MPKitAdobeMedia ()

@property (nonatomic) NSString *organizationId;
@property (nonatomic) MPIAdobe *adobe;
@property ACPMediaTracker *mediaTracker;
@property (nonatomic) BOOL hasSetMCID;
@property (nonatomic) NSString *pushToken;

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
        if (launchAppId != nil) {
            [ACPCore setLogLevel:ACPMobileLogLevelDebug];
            [ACPCore configureWithAppId:launchAppId];
            [ACPAnalytics registerExtension];
            [ACPMedia registerExtension];
            [ACPUserProfile registerExtension];
            [ACPIdentity registerExtension];
            [ACPLifecycle registerExtension];
            [ACPSignal registerExtension];
            
            [ACPCore start:^{
                NSMutableDictionary* config = [NSMutableDictionary dictionary];

                [ACPMedia createTrackerWithConfig: config
                                         callback:^(ACPMediaTracker * _Nullable mediaTracker) {
                    self.mediaTracker = mediaTracker;
                    NSLog(@"mParticle -> Adobe Media configured");
                }];
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
            ACPMediaType contentType = [self contentTypeForMediaEvent:mediaEvent];
            
            NSDictionary *mediaObject = [ACPMedia createMediaObjectWithName:mediaEvent.mediaContentTitle mediaId:mediaEvent.mediaContentId length:mediaEvent.duration.doubleValue streamType:streamType mediaType:contentType];

            NSMutableDictionary *mediaMetadata = [[NSMutableDictionary alloc] init];

            [_mediaTracker trackSessionStart:mediaObject data:mediaMetadata];
            break;
        }
        case MPMediaEventNameSessionEnd:
            [_mediaTracker trackSessionEnd];
            break;
        case MPMediaEventNameSeekStart: {
            [_mediaTracker trackEvent:ACPMediaEventSeekStart info:nil data:nil];
            break;
        }
        case MPMediaEventNameSeekEnd: {
            [_mediaTracker trackEvent:ACPMediaEventSeekComplete info:nil data:nil];
            break;
        }
        case MPMediaEventNameBufferStart: {
            [_mediaTracker trackEvent:ACPMediaEventBufferStart info:nil data:nil];
            break;
        }
        case MPMediaEventNameBufferEnd: {
            [_mediaTracker trackEvent:ACPMediaEventBufferComplete info:nil data:nil];
            break;
        }
        case MPMediaEventNameUpdatePlayheadPosition:
            [_mediaTracker updateCurrentPlayhead:mediaEvent.playheadPosition.doubleValue];
            break;
        case MPMediaEventNameAdClick:
            //Media does not track Ad interaction
            break;
        case MPMediaEventNameAdBreakStart: {
            NSDictionary* adBreakObject = [ACPMedia createAdBreakObjectWithName:mediaEvent.adBreak.title position:1 startTime:0];
            
            [_mediaTracker trackEvent:ACPMediaEventAdBreakStart info:adBreakObject data:nil];
            break;
        }
        case MPMediaEventNameAdBreakEnd: {
            [_mediaTracker trackEvent:ACPMediaEventAdBreakComplete info:nil data:nil];
            break;
        }
        case MPMediaEventNameAdStart: {
            NSDictionary* adObject = [ACPMedia createAdObjectWithName:mediaEvent.adContent.title adId:mediaEvent.adContent.id position:mediaEvent.adContent.position.doubleValue length:mediaEvent.adContent.duration.doubleValue];
            NSMutableDictionary* adMetadata = [[NSMutableDictionary alloc] init];
            
            if (mediaEvent.adContent.advertiser != nil) {
                [adMetadata setObject:mediaEvent.adContent.advertiser forKey:ACPAdMetadataKeyAdvertiser];
            }
            if (mediaEvent.adContent.campaign != nil) {
                [adMetadata setObject:mediaEvent.adContent.campaign forKey:ACPAdMetadataKeyCampaignId];
            }
            if (mediaEvent.adContent.creative != nil) {
                [adMetadata setObject:mediaEvent.adContent.creative forKey:ACPAdMetadataKeyCreativeId];
            }
            if (mediaEvent.adContent.placement != nil) {
                [adMetadata setObject:mediaEvent.adContent.placement forKey:ACPAdMetadataKeyPlacementId];
            }
            if (mediaEvent.adContent.siteId != nil) {
                [adMetadata setObject:mediaEvent.adContent.siteId forKey:ACPAdMetadataKeyCreativeUrl];
            }
            
            [_mediaTracker trackEvent:ACPMediaEventAdStart info:adObject data:adMetadata];
            break;
        }
        case MPMediaEventNameAdEnd: {
            [_mediaTracker trackEvent:ACPMediaEventAdComplete info:nil data:nil];
            break;
        }
        case MPMediaEventNameAdSkip: {
            [_mediaTracker trackEvent:ACPMediaEventAdSkip info:nil data:nil];
            break;
        }
        case MPMediaEventNameSegmentStart: {
            NSDictionary* chapterObject = [ACPMedia createChapterObjectWithName:mediaEvent.segment.title position:mediaEvent.segment.index length:mediaEvent.segment.duration.doubleValue startTime:mediaEvent.playheadPosition.doubleValue];
            
            [_mediaTracker trackEvent:ACPMediaEventChapterStart info:chapterObject data:nil];
            break;
        }
        case MPMediaEventNameSegmentSkip: {
            [_mediaTracker trackEvent:ACPMediaEventChapterSkip info:nil data:nil];
           break;
       }
        case MPMediaEventNameSegmentEnd:  {
            [_mediaTracker trackEvent:ACPMediaEventChapterComplete info:nil data:nil];
           break;
       }
        case MPMediaEventNameUpdateQoS: {
            NSDictionary* mediaQoS = [ACPMedia createQoEObjectWithBitrate:mediaEvent.qos.bitRate.doubleValue startupTime:mediaEvent.qos.startupTime.doubleValue fps:mediaEvent.qos.fps.doubleValue droppedFrames:mediaEvent.qos.droppedFrames.doubleValue];
            
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
            return ACPMediaStreamTypeVod;
        } else {
            return ACPMediaStreamTypeAod;
        }
    } else if (mediaEvent.streamType == MPMediaStreamTypeLinear) {
        return ACPMediaStreamTypeLinear;
    } else if (mediaEvent.streamType == MPMediaStreamTypePodcast) {
        return ACPMediaStreamTypePodcast;
    } else if (mediaEvent.streamType == MPMediaStreamTypeAudiobook) {
        return ACPMediaStreamTypeAudiobook;
    } else {
        return ACPMediaStreamTypeLive;
    }
}

- (ACPMediaType)contentTypeForMediaEvent:(MPMediaEvent *)mediaEvent  {
    if (mediaEvent.contentType == MPMediaContentTypeVideo) {
        return ACPMediaTypeVideo;
    } else {
        return ACPMediaTypeAudio;
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
            _hasSetMCID = YES;
        }
    }
    
    NSString *advertiserId = [self advertiserId];
    NSString *pushToken = [self pushToken];
    FilteredMParticleUser *user = [self currentUser];
    NSDictionary *userIdentities = user.userIdentities;
    [_adobe sendRequestWithMarketingCloudId:marketingCloudId advertiserId:advertiserId pushToken:pushToken organizationId:_organizationId userIdentities:userIdentities completion:^(NSString *marketingCloudId, NSString *locationHint, NSString *blob, NSError *error) {
        if (error) {
            NSLog(@"mParticle -> Adobe kit request failed with error: %@", error);
            return;
        }
        
        NSMutableDictionary *integrationAttributes = [NSMutableDictionary dictionary];
        if (marketingCloudId.length) {
            [integrationAttributes setObject:marketingCloudId forKey:marketingCloudIdIntegrationAttributeKey];
        }
        if (locationHint.length) {
            [integrationAttributes setObject:locationHint forKey:locationHintIntegrationAttributeKey];
        }
        if (blob.length) {
            [integrationAttributes setObject:blob forKey:blobIntegrationAttributeKey];
        }
        
        if (integrationAttributes.count) {
            [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
            self->_hasSetMCID = YES;
        }
    }];
}

@end
