//
//  RHStudentAdapter.m
//  Grade Recorder
//
//  Created by David Fisher on 8/4/14.
//  Copyright (c) 2014 Rose-Hulman. All rights reserved.
//

#import "RHStudentUtils.h"

#import "GTLGraderecorder.h"

#import "RHDialogUtils.h"
#import "RHOAuthUtils.h"

static BOOL __isQueryInProgress;
static NSMutableArray* __students;
static NSMutableDictionary* __teamMap;


@implementation RHStudentUtils

+ (void) initialize {
    __students = [[NSMutableArray alloc] init];
    __teamMap = [[NSMutableDictionary alloc] init];
}


// Returns NO if the query is already in progress.
+ (BOOL) updateStudentRosterWithCallback:(void (^)()) callback {
    if (__isQueryInProgress) {
        return NO;
    }
    NSLog(@"Query for students.");
    __isQueryInProgress = YES;
    [__students removeAllObjects];
    [__teamMap removeAllObjects];
    [self _queryForStudentsWithPageToken:nil withCallback:callback];
    return YES;
}


// Returning data structures.
+ (NSArray*) getStudents { return __students; }
+ (NSDictionary*) getTeamMap { return __teamMap; }


// TODO: Create _queryForStudentsWithPageToken:withCallback:


@end
