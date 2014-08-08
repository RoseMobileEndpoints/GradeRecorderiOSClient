//
//  RHLoginViewController.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHLoginViewController.h"

#import "GTMOAuth2ViewControllerTouch.h"

#import "RHDialogUtils.h"
#import "RHOAuthUtils.h"

#define kLoginCompleteSegue @"LoginCompleteSegue"


@implementation RHLoginViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // TODO: If a user is already logged in ([RHOAuthUtils hasAuthorizer] is true) then push to the next scene (performSegue).
}


- (IBAction)pressedSignIn:(id)sender {

    // TODO: Call signInFromViewController.  If there is an error display it, otherwise performSegue.

}

@end
