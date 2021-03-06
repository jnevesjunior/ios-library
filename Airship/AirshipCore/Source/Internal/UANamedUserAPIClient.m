/* Copyright Airship and Contributors */

#import "UANamedUserAPIClient+Internal.h"
#import "UARuntimeConfig.h"
#import "UAUtils+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "NSURLResponse+UAAdditions.h"
#import "UAJSONSerialization.h"

#define kUANamedUserPath @"/api/named_users"
#define kUANamedUserChannelIDKey @"channel_id"
#define kUANamedUserDeviceTypeKey @"device_type"
#define kUANamedUserIdentifierKey @"named_user_id"

NSString * const UANamedUserAPIClientErrorDomain = @"com.urbanairship.named_user_api_client";

@implementation UANamedUserAPIClient

+ (instancetype)clientWithConfig:(UARuntimeConfig *)config {
    return [[self alloc] initWithConfig:config session:[UARequestSession sessionWithConfig:config]];
}

+ (instancetype)clientWithConfig:(UARuntimeConfig *)config session:(UARequestSession *)session {
    return [[self alloc] initWithConfig:config session:session];
}

- (void)associate:(NSString *)identifier
        channelID:(NSString *)channelID
completionHandler:(void (^)(NSError * _Nullable))completionHandler {

    if (!self.enabled) {
        UA_LDEBUG(@"Disabled");
        return;
    }

    if (!identifier) {
        UA_LERR(@"The named user ID cannot be nil.");
        return;
    }

    if (!channelID) {
        UA_LERR(@"The channel ID cannot be nil.");
        return;
    }

    UA_LTRACE(@"Associating channel %@ with named user ID: %@", channelID, identifier);


    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:channelID forKey:kUANamedUserChannelIDKey];
    [payload setObject:@"ios" forKey:kUANamedUserDeviceTypeKey];
    [payload setValue:identifier forKey:kUANamedUserIdentifierKey];

    NSString *urlString = [NSString stringWithFormat:@"%@%@", self.config.deviceAPIURL, kUANamedUserPath];
    UARequest *request = [self requestWithPayload:payload
                                        urlString:[NSString stringWithFormat:@"%@%@", urlString, @"/associate"]];

    [self performRequest:request retryWhere:^BOOL(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response) {
        return [response hasRetriableStatus];
    } completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            return completionHandler(error);
        }

        NSInteger status = response.statusCode;

        // Failure
        if (!(status >= 200 && status <= 299)) {
            UA_LTRACE(@"Failed to associate named user with status: %lu", (unsigned long)status);
            return completionHandler([self unsuccessfulStatusError]);
        }

        // Success
        UA_LTRACE(@"Associated named user with status: %lu", (unsigned long)status);
        completionHandler(nil);
    }];
}

- (NSError *)unsuccessfulStatusError {
    NSString *msg = [NSString stringWithFormat:@"Named user client encountered an unsuccessful status"];

    NSError *error = [NSError errorWithDomain:UANamedUserAPIClientErrorDomain
                                         code:UANamedUserAPIClientErrorUnsuccessfulStatus
                                     userInfo:@{NSLocalizedDescriptionKey:msg}];

    return error;
}

- (void)disassociate:(NSString *)channelID
   completionHandler:(void (^)(NSError * _Nullable))completionHandler {

    if (!self.enabled) {
        UA_LDEBUG(@"Disabled");
        return;
    }

    if (!channelID) {
        UA_LERR(@"The channel ID cannot be nil.");
        return;
    }

    UA_LTRACE(@"Disassociating channel %@ from named user ID", channelID);

    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    [payload setValue:channelID forKey:kUANamedUserChannelIDKey];
    [payload setObject:@"ios" forKey:kUANamedUserDeviceTypeKey];

    NSString *urlString = [NSString stringWithFormat:@"%@%@", self.config.deviceAPIURL, kUANamedUserPath];
    UARequest *request = [self requestWithPayload:payload
                                        urlString:[NSString stringWithFormat:@"%@%@", urlString, @"/disassociate"]];

    [self performRequest:request retryWhere:^BOOL(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response) {
        return [response hasRetriableStatus];
    } completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            return completionHandler(error);
        }

        NSInteger status = response.statusCode;

        // Failure
        if (!(status >= 200 && status <= 299)) {
            UA_LTRACE(@"Failed to dissociate named user with status: %lu", (unsigned long)status);
            completionHandler([self unsuccessfulStatusError]);
            return;
        }

        // Success
        UA_LTRACE(@"Dissociated named user with status: %lu", (unsigned long)status);
        completionHandler(nil);
    }];
}

- (UARequest *)requestWithPayload:(NSDictionary *)payload urlString:(NSString *)urlString {

    UARequest *request = [UARequest requestWithBuilderBlock:^(UARequestBuilder * _Nonnull builder) {
        builder.method = @"POST";
        builder.URL = [NSURL URLWithString:urlString];
        builder.username = self.config.appKey;
        builder.password = self.config.appSecret;
        [builder setValue:@"application/vnd.urbanairship+json; version=3;" forHeader:@"Accept"];
        [builder setValue:@"application/json" forHeader:@"Content-Type"];
        builder.body = [UAJSONSerialization dataWithJSONObject:payload
                                                       options:0
                                                         error:nil];
    }];

    return request;
}

@end


