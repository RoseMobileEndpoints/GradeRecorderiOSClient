//
//  RHDialogUtils.m
//  Grade Recorder
//
//  Created by David Fisher on 8/4/14.
//  Copyright (c) 2014 Rose-Hulman. All rights reserved.
//

#import "RHDialogUtils.h"

@implementation RHDialogUtils

+ (void) showErrorDialog:(NSError*) error {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:error.localizedDescription
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
