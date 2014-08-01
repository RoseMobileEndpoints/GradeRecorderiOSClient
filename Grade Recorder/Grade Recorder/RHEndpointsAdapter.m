//
//  RHEndpointsAdapter.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHEndpointsAdapter.h"
#import "GTLServiceGraderecorder.h"
#import "GTMOAuth2Authentication.h"
#import "GTMHTTPFetcherLogging.h"
#import "GTMOAuth2ViewControllerTouch.h"


@implementation RHEndpointsAdapter

@synthesize authorizer = _authorizer;


+ (id) sharedInstance
{
    static dispatch_once_t pred;
    static RHEndpointsAdapter *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[RHEndpointsAdapter alloc] init];
    });
    return sharedInstance;
}

- (GTLServiceGraderecorder*) graderecorderService {
    static GTLServiceGraderecorder *service = nil;
    if (!service) {
        service = [[GTLServiceGraderecorder alloc] init];
        if (kLocalHostTesting) {
            [service setRpcURL:[NSURL URLWithString:kLocalHostUrl]];
        }
        service.retryEnabled = YES;
        [GTMHTTPFetcher setLoggingEnabled:YES];
    }
    return service;
}

#pragma mark - authorizer
- (GTMOAuth2Authentication*) authorizer {
    if (_authorizer == nil) {
        GTMOAuth2Authentication* savedAuthorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                                         clientID:kIosClientID
                                                                                                     clientSecret:kIosClientSecret];
        if (savedAuthorizer.canAuthorize && savedAuthorizer.userEmail != nil) {
            NSLog(@"Using a saved authorizer");
            self.authorizer = savedAuthorizer;
        }
    }
    _authorizer.authorizationTokenKey = @"id_token";
    if (kLocalHostTesting) {
        NSLog(@"Authorizing all requests.");
        _authorizer.shouldAuthorizeAllRequests = YES;
    }
    return _authorizer;
}

- (void) setAuthorizer:(GTMOAuth2Authentication*) authorizer {
    if (authorizer != nil) {
        NSAssert(authorizer.userEmail != nil, @"Authorizer has no user email");
        NSAssert(authorizer.canAuthorize, @"Authorizer can't authorize");
        _authorizer.authorizationTokenKey = @"id_token";
        if (kLocalHostTesting) {
            NSLog(@"Authorizing all requests.");
            _authorizer.shouldAuthorizeAllRequests = YES;
        }
    }
    self.graderecorderService.authorizer = authorizer;
    _authorizer = authorizer;
}

- (void) signOut {
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.authorizer];
    self.authorizer = nil;
}


- (void) showErrorMessage:(NSError*) error {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Endpoints error"
                                                    message:error.localizedDescription
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
