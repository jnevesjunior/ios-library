/* Copyright Airship and Contributors */

#import "UAAirshipBaseTest.h"
#import "UAUserAPIClient+Internal.h"
#import "NSJSONSerialization+UAAdditions.h"
#import "UAUtils+Internal.h"
#import "UARuntimeConfig.h"
#import "UAirship+Internal.h"
#import "UAUserAPIClient+Internal.h"
#import "UAUser+Internal.h"
#import "UAUserData+Internal.h"
#import "UAJSONSerialization.h"

@interface UAUserAPIClientTest : UAAirshipBaseTest
@property (nonatomic, strong) UAUserAPIClient *client;
@property (nonatomic, strong) id mockRequest;
@property (nonatomic, strong) id mockSession;
@property (nonatomic, strong) UAUserData *userData;
@end

@implementation UAUserAPIClientTest

- (void)setUp {
    [super setUp];
    self.mockSession = [self mockForClass:[UARequestSession class]];
    self.mockRequest = [self mockForClass:[UARequest class]];
    self.client = [UAUserAPIClient clientWithConfig:self.config session:self.mockSession];
    self.userData = [UAUserData dataWithUsername:@"username" password:@"password"];
}

- (void)testCreateUser {
    // Create a valid response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""] statusCode:201 HTTPVersion:nil headerFields:nil];

    NSDictionary *responseDict = @{@"user_id": @"someUserName", @"password": @"somePassword", @"user_url": @"http://url.com"};

    NSData *responseData =  [UAJSONSerialization dataWithJSONObject:responseDict
                                                            options:0
                                                              error:nil];

    BOOL (^checkRequestBlock)(id obj) = ^(id obj) {
        UARequest *request = obj;

        // Check the url
        if (![[request.URL absoluteString] isEqualToString:@"https://device-api.urbanairship.com/api/user/"]) {
            return NO;
        }

        // Check that it's a POST
        if (![request.method isEqualToString:@"POST"]) {
            return NO;
        }

        // Check that it contains an accept header
        if (![[request.headers valueForKey:@"Accept"] isEqualToString:@"application/vnd.urbanairship+json; version=3;"]) {
            return NO;
        }

        // Check that it contains an content type header
        if (![[request.headers valueForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
            return NO;
        }

        if (![request.body isEqualToData:[UAJSONSerialization dataWithJSONObject:@{@"ios_channels": @[@"channelID"]} options:0 error:nil]]) {
            return NO;
        }

        return YES;
    };

    // Stub the session to return the response
    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(responseData, response, nil);
    }] performHTTPRequest:[OCMArg checkWithBlock:checkRequestBlock] completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client createUserWithChannelID:@"channelID"
                       completionHandler:^(UAUserData * _Nullable data, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(data.username, [responseDict valueForKey:@"user_id"]);
        XCTAssertEqualObjects(data.password, [responseDict valueForKey:@"password"]);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

- (void)testCreateUserFailureClientError {
    // Create a valid response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
                                                              statusCode:400
                                                             HTTPVersion:nil
                                                            headerFields:nil];

    // Stub the session to return the response
    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(nil, response, nil);
    }] performHTTPRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client createUserWithChannelID:@"channelID" completionHandler:^(UAUserData * _Nullable data, NSError * _Nullable error) {
        XCTAssertNil(data);
        XCTAssertEqual(UAUserAPIClientErrorDomain, error.domain);
        XCTAssertEqual(UAUserAPIClientErrorUnrecoverable, error.code);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

- (void)testCreateUserFailureServerError {
    // Create a valid response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
                                                              statusCode:500
                                                             HTTPVersion:nil
                                                            headerFields:nil];

    // Stub the session to return the response
    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(nil, response, nil);
    }] performHTTPRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client createUserWithChannelID:@"channelID" completionHandler:^(UAUserData * _Nullable data, NSError * _Nullable error) {
        XCTAssertNil(data);
        XCTAssertEqual(UAUserAPIClientErrorDomain, error.domain);
        XCTAssertEqual(UAUserAPIClientErrorRecoverable, error.code);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

- (void)testCreateUserFailureJSONParseError {
    // Create a valid response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
                                                              statusCode:200
                                                             HTTPVersion:nil
                                                            headerFields:nil];

    NSDictionary *responseDict = @{};

    NSData *responseData =  [UAJSONSerialization dataWithJSONObject:responseDict
                                                            options:0
                                                              error:nil];


    // Stub the session to return the response
    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(responseData, response, nil);
    }] performHTTPRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client createUserWithChannelID:@"channelID" completionHandler:^(UAUserData * _Nullable data, NSError * _Nullable error) {
        XCTAssertNil(data);
        XCTAssertEqual(UAUserAPIClientErrorDomain, error.domain);
        XCTAssertEqual(UAUserAPIClientErrorUnrecoverable, error.code);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

- (void)testCreateUserFailureSessionError {
    NSError *error = [NSError errorWithDomain:@"some-domain" code:100 userInfo:@{}];

    // Stub the session to return the response
    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(nil, nil, error);
    }] performHTTPRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client createUserWithChannelID:@"channelID" completionHandler:^(UAUserData * _Nullable data, NSError * _Nullable error) {
        XCTAssertNil(data);
        XCTAssertEqual(UAUserAPIClientErrorDomain, error.domain);
        XCTAssertEqual(UAUserAPIClientErrorRecoverable, error.code);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

-(void)testUpdateUser {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""] statusCode:200 HTTPVersion:nil headerFields:nil];
    BOOL (^checkRequestBlock)(id obj) = ^(id obj) {
        UARequest *request = obj;

        // Check the url
        if (![[request.URL absoluteString] isEqualToString:@"https://device-api.urbanairship.com/api/user/username/"]) {
            return NO;
        }

        // Check that it's a POST
        if (![request.method isEqualToString:@"POST"]) {
            return NO;
        }

        // Check that it contains an accept header
        if (![[request.headers valueForKey:@"Accept"] isEqualToString:@"application/vnd.urbanairship+json; version=3;"]) {
            return NO;
        }

        // Check that it contains an content type header
        if (![[request.headers valueForKey:@"Content-Type"] isEqualToString:@"application/json"]) {
            return NO;
        }

        if (![request.body isEqualToData:[UAJSONSerialization dataWithJSONObject:@{@"ios_channels": @{@"add" : @[@"channelID"]}} options:0 error:nil]]) {
            return NO;
        }

        return YES;
    };

    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(nil, response, nil);
    }] performHTTPRequest:[OCMArg checkWithBlock:checkRequestBlock] completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client updateUserWithData:self.userData channelID:@"channelID" completionHandler:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

- (void)testUpdateUserFailureClientError {
    // Create a valid response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
                                                              statusCode:400
                                                             HTTPVersion:nil
                                                            headerFields:nil];

    // Stub the session to return the response
    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(nil, response, nil);
    }] performHTTPRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client updateUserWithData:self.userData channelID:@"channelID" completionHandler:^(NSError * _Nullable error) {
        XCTAssertEqual(UAUserAPIClientErrorDomain, error.domain);
        XCTAssertEqual(UAUserAPIClientErrorUnrecoverable, error.code);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

- (void)testUpdateUserFailureServerError {
    // Create a valid response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@""]
                                                              statusCode:500
                                                             HTTPVersion:nil
                                                            headerFields:nil];

    // Stub the session to return the response
    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(nil, response, nil);
    }] performHTTPRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client updateUserWithData:self.userData channelID:@"channelID" completionHandler:^(NSError * _Nullable error) {
        XCTAssertEqual(UAUserAPIClientErrorDomain, error.domain);
        XCTAssertEqual(UAUserAPIClientErrorRecoverable, error.code);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

- (void)testUpdateUserFailureSessionError {
    NSError *error = [NSError errorWithDomain:@"some-domain" code:100 userInfo:@{}];

    // Stub the session to return the response
    [[[self.mockSession stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        UAHTTPRequestCompletionHandler completionHandler = (__bridge UAHTTPRequestCompletionHandler)arg;
        completionHandler(nil, nil, error);
    }] performHTTPRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    XCTestExpectation *callbackCalled = [self expectationWithDescription:@"callback called"];
    [self.client updateUserWithData:self.userData channelID:@"channelID" completionHandler:^(NSError * _Nullable error) {
        XCTAssertEqual(UAUserAPIClientErrorDomain, error.domain);
        XCTAssertEqual(UAUserAPIClientErrorRecoverable, error.code);
        [callbackCalled fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockSession verify];
}

@end


