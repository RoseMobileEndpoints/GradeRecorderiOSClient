//
//  RHLoginViewController.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHLoginViewController.h"
#import "RHEndpointsAdapter.h"
#import "GTMOAuth2ViewControllerTouch.h"

#define kLoginCompleteSegue @"LoginCompleteSegue"

@interface RHLoginViewController ()

@end

@implementation RHLoginViewController

- (void) viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[RHEndpointsAdapter sharedInstance] authorizer] != nil) {
        [self performSegueWithIdentifier:kLoginCompleteSegue sender:nil];
    }
}

- (IBAction)pressedSignIn:(id)sender {
    GTMOAuth2ViewControllerTouch* signInViewController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kScope
                                                                      clientID:kIosClientID
                                                                  clientSecret:kIosClientSecret
                                                              keychainItemName:kKeychainItemName
                                                                      delegate:self
                                                              finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:signInViewController];
    navigationController.navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelSignIn)];
    navigationController.navigationBar.barStyle = UIBarStyleBlack;
    navigationController.navigationBar.translucent = NO;
    [self presentViewController:navigationController animated:YES completion:nil];
}


- (void) cancelSignIn {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    if (![self.presentedViewController isBeingDismissed]) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    if (error != nil) {
        // Authentication failed.
    } else {
        // Authentication succeeded.
        [[RHEndpointsAdapter sharedInstance] setAuthorizer:auth];
        [self performSegueWithIdentifier:kLoginCompleteSegue sender:nil];
    }
}


@end
