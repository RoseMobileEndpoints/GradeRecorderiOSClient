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
	// Do any additional setup after loading the view.
    if ([RHOAuthUtils hasAuthorizer]) {
        NSLog(@"Push to next scene.  The service already has an authorizer.");
        [self performSegueWithIdentifier:kLoginCompleteSegue sender:nil];
    }
}


- (IBAction)pressedSignIn:(id)sender {
    [RHOAuthUtils signInFromViewController:self withCallback:^(NSError *error) {
        if (error != nil) {
            [RHDialogUtils showErrorDialog:error];
        } else {
            NSLog(@"Sign in successfully completed.  Push to next scene.");
            [self performSegueWithIdentifier:kLoginCompleteSegue sender:nil];
        }
    }];
}

@end
