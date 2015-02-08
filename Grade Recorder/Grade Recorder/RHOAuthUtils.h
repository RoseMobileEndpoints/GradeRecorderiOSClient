//
//  RHEndpointsAdapter.h
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GTLServiceGraderecorder;

@interface RHOAuthUtils : NSObject

+ (GTLServiceGraderecorder*) getService;
+ (BOOL) hasAuthorizer;
+ (BOOL) isLocalHost;
+ (void) signInFromViewController:(UIViewController*) parentViewController
                     withCallback:(void (^)(NSError* error)) callback;
+ (void) signOut;

@end
