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

#define kLocalHostTesting NO
#define kLocalHostUrl @"http://localhost:8080/_ah/api/rpc?prettyPrint=false"

// For the backend --> yourusername-grade-recorder.appspot.com
#define kIosClientID @""
#define kIosClientSecret @""

#define kScope @"email"
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
    return nil;  // TODO: Implement.
}


#pragma mark - Authorizer

+ (BOOL) hasAuthorizer {
    return [RHOAuthUtils _getAuthorizer] != nil; // Very important to use the _getAuthorizer function.
}


// Returns the current authorizer if available, otherwise attempt to return the saved authorizer.
+ (GTMOAuth2Authentication*) _getAuthorizer {
    return nil;  // TODO: Implement.
}


// Set the authorizer and link the authorizer to the service.
+ (void) _setAuthorizer:(GTMOAuth2Authentication*) authorizer {
    // TODO: Implement.

}


#pragma mark - Sign in / sign out utils

// Revoke the authorizer and clear the saved authorizer.
+ (void) signOut {
    // TODO: Implement.

}


+ (void) signInFromViewController:(UIViewController*) parentViewController
                     withCallback:(void (^)(NSError* error)) callback {
    // TODO: Implement.

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
