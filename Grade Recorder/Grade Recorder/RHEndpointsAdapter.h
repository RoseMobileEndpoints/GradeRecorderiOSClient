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

#define kLocalHostTesting NO
#define kLocalHostUrl @"http://localhost:8080/_ah/api/rpc?prettyPrint=false"
//#define kLocalHostUrl @"http://137.112.44.42:8080/_ah/api/rpc?prettyPrint=false"

// For the backend --> fisherds-grade-recorder.appspot.com
//#define kIosClientID @"396789689578-k7gd51qmljoathgk88hlm9oti0bsmfuv.apps.googleusercontent.com"
//#define kIosClientSecret @"3uSoStImcdkVxP6ymLMJBIM5"

// For the backend --> me430-grade-recorder.appspot.com
#define kIosClientID @"260346932481-da10f7trblkq1vpcbq9qsje35tt056g3.apps.googleusercontent.com"
#define kIosClientSecret @"Nfk7evO93EqnoeItHoEoBdpI"

//#define kScope @"https://www.googleapis.com/auth/userinfo.email" // Old scope name.
#define kScope @"email"  // New scope name.
#define kKeychainItemName @"grade_recorder_authorizer"


@interface RHEndpointsAdapter : NSObject

+ (RHEndpointsAdapter*) sharedInstance;

@property (nonatomic, strong, readonly) GTLServiceGraderecorder* graderecorderService;
@property (nonatomic, strong) GTMOAuth2Authentication* authorizer;

- (void) signOut;
- (void) showErrorMessage:(NSError*) error;

@end
