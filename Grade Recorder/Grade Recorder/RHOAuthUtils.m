//
//  RHEndpointsAdapter.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHOAuthUtils.h"

#import "GTLServiceGraderecorder.h"
#import "GTMOAuth2Authentication.h"
#import "GTMHTTPFetcherLogging.h"
#import "GTMOAuth2ViewControllerTouch.h"

#import "RHDialogUtils.h"

#define kLocalHostTesting YES
#define kLocalHostUrl @"http://localhost:8080/_ah/api/rpc?prettyPrint=false"

// For the backend --> fisherds-grade-recorder.appspot.com
//#define kIosClientID @"396789689578-k7gd51qmljoathgk88hlm9oti0bsmfuv.apps.googleusercontent.com"
//#define kIosClientSecret @"3uSoStImcdkVxP6ymLMJBIM5"

// For the backend --> me430-grade-recorder.appspot.com
#define kIosClientID @"260346932481-da10f7trblkq1vpcbq9qsje35tt056g3.apps.googleusercontent.com"
#define kIosClientSecret @"Nfk7evO93EqnoeItHoEoBdpI"

//#define kScope @"https://www.googleapis.com/auth/userinfo.email" // Old scope name.
#define kScope @"email"  // New scope name.
#define kKeychainItemName @"grade_recorder_authorizer"

static GTLServiceGraderecorder* __graderecorderService;
static GTMOAuth2Authentication* __authorizer;

static UIViewController* __parentViewControllerForSignInModal;
static void (^__signInCallback)(NSError* error);


@implementation RHOAuthUtils

#pragma mark - Service

+ (BOOL) isLocalHost {
    return kLocalHostTesting;
}


+ (GTLServiceGraderecorder*) getService {
    if (__graderecorderService == nil) {
        __graderecorderService = [[GTLServiceGraderecorder alloc] init];
        if (kLocalHostTesting) {
            [__graderecorderService setRpcURL:[NSURL URLWithString:kLocalHostUrl]];
        }
        __graderecorderService.retryEnabled = YES;
        [GTMHTTPFetcher setLoggingEnabled:YES];
    }
    return __graderecorderService;
}


#pragma mark - Authorizer

+ (BOOL) hasAuthorizer {
    return [RHOAuthUtils _getAuthorizer] != nil; // Very important to use the _getAuthorizer function.
}


// Returns the current authorizer if available, otherwise attempt to return the saved authorizer.
+ (GTMOAuth2Authentication*) _getAuthorizer {
    if (__authorizer == nil) {
        GTMOAuth2Authentication* savedAuthorizer;
        savedAuthorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                clientID:kIosClientID
                                                                            clientSecret:kIosClientSecret];
        if (savedAuthorizer.canAuthorize && savedAuthorizer.userEmail != nil) {
            NSLog(@"Using a saved authorizer");
            [RHOAuthUtils _setAuthorizer:savedAuthorizer];
        }
    }
    __authorizer.authorizationTokenKey = @"id_token";
    if (kLocalHostTesting) {
        NSLog(@"Authorizing all requests.");
        __authorizer.shouldAuthorizeAllRequests = YES;
    }
    return __authorizer;
}


// Save the authorizer for later use and link the authorizer to the service.
+ (void) _setAuthorizer:(GTMOAuth2Authentication*) authorizer {
    if (authorizer != nil) {
        NSAssert(authorizer.userEmail != nil, @"Authorizer has no user email");
        NSAssert(authorizer.canAuthorize, @"Authorizer can't authorize");
    }
    __authorizer = authorizer;
    [RHOAuthUtils getService].authorizer = [RHOAuthUtils _getAuthorizer];
}


#pragma mark - Sign in / sign out utils

// Revoke the authorizer and clear the saved authorizer.
+ (void) signOut {
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:__authorizer];
    [RHOAuthUtils _setAuthorizer:nil];
}


+ (void) signInFromViewController:(UIViewController*) parentViewController
                     withCallback:(void (^)(NSError* error)) callback {
    __parentViewControllerForSignInModal = parentViewController;
    __signInCallback = callback;
    GTMOAuth2ViewControllerTouch* signInViewController;
    signInViewController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kScope
                                                                      clientID:kIosClientID
                                                                  clientSecret:kIosClientSecret
                                                              keychainItemName:kKeychainItemName
                                                                      delegate:self
                                                              finishedSelector:@selector(_viewController:finishedWithAuth:error:)];

    // Display the signInViewController within a Navigation Controller so we can add a cancel button in the top bar.
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:signInViewController];
    navigationController.navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                                    initWithTitle:@"Cancel"
                                                                    style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(_cancelSignIn)];
    navigationController.navigationBar.barStyle = UIBarStyleBlack;
    navigationController.navigationBar.translucent = NO;
    [parentViewController presentViewController:navigationController animated:YES completion:nil];
}


# pragma mark - private methods

// Called when a user presses Cancel from the Sign in modal.
+ (void) _cancelSignIn {
    [__parentViewControllerForSignInModal dismissViewControllerAnimated:YES completion:nil];
}

// Called when a user completes Sign in.
+ (void) _viewController:(GTMOAuth2ViewControllerTouch*) viewController
        finishedWithAuth:(GTMOAuth2Authentication*) auth
                   error:(NSError*) error {
    if (error != nil) {
        // Authentication failed.
        [RHOAuthUtils signOut];
    } else {
        // Authentication succeeded.
        NSLog(@"Authentication success!");
        [RHOAuthUtils _setAuthorizer:auth];
    }
    if (![__parentViewControllerForSignInModal.presentedViewController isBeingDismissed]) {
        [__parentViewControllerForSignInModal dismissViewControllerAnimated:NO completion:nil];
    }
    __signInCallback(error);
    __parentViewControllerForSignInModal = nil;
    __signInCallback = nil;
}

@end
