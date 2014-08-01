//
//  RHEndpointsAdapter.h
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GTLServiceGraderecorder;
@class GTMOAuth2Authentication;

#define kLocalHostTesting YES
#define kLocalHostUrl @"http://137.112.44.42:8080/_ah/api/rpc?prettyPrint=false"

#define kScope @"https://www.googleapis.com/auth/userinfo.email"
#define kIosClientID @"396789689578-k7gd51qmljoathgk88hlm9oti0bsmfuv.apps.googleusercontent.com"
#define kIosClientSecret @"3uSoStImcdkVxP6ymLMJBIM5"
#define kKeychainItemName @"grade_recorder_authorizer"


@interface RHEndpointsAdapter : NSObject

+ (RHEndpointsAdapter*) sharedInstance;

@property (nonatomic, strong, readonly) GTLServiceGraderecorder* graderecorderService;
@property (nonatomic, strong) GTMOAuth2Authentication* authorizer;

- (void) signOut;
- (void) showErrorMessage:(NSError*) error;

@end
