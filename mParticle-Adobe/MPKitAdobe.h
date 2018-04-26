#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
#endif

#pragma mark - MPIAdobeApi
@interface MPIAdobeApi : NSObject

/// Returns the Adobe Marketing Cloud ID if present
@property (readwrite, nullable) NSString *marketingCloudID;

@end

#pragma mark - MPKitAdobe
@interface MPKitAdobe : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

@end
