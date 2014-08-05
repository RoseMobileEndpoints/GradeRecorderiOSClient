//
//  RHStudentAdapter.m
//  Grade Recorder
//
//  Created by David Fisher on 8/4/14.
//  Copyright (c) 2014 Rose-Hulman. All rights reserved.
//

#import "RHStudentUtils.h"

#import "GTLGraderecorder.h"

#import "RHEndpointsAdapter.h"

static BOOL __isQueryInProgress;
static NSMutableArray* __students;
static NSMutableDictionary* __studentMap;


@implementation RHStudentUtils

// Returns NO if the query is already in progress.
+ (BOOL) updateStudentRosterWithCallback:(void (^)()) callback {
    if (__isQueryInProgress) {
        return NO;
    }
    __isQueryInProgress = YES;
    __students = [[NSMutableArray alloc] init];
    __studentMap = [[NSMutableDictionary alloc] init];
    [self _queryForStudentsWithPageToken:nil withCallback:callback];
    return YES;
}


// Returns an array of all GTLGraderecorderStudents
+ (NSArray*) getStudents {
    return __students;
}


+ (NSDictionary*) getStudentMap {
    return __studentMap;
}


+ (void) _queryForStudentsWithPageToken:(NSString*) pageToken withCallback:(void (^)()) callback {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder* query = [GTLQueryGraderecorder queryForStudentList];
    query.limit = 10;
    query.pageToken = pageToken;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket,
                                                    GTLGraderecorderStudentCollection* studentCollection,
                                                    NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error != nil) {
            NSLog(@"Unable to query for students %@", error);
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
            return;
        }

        // Add the new students to the array and the map.
        [__students addObjectsFromArray:studentCollection.items];
        for (GTLGraderecorderStudent* student in studentCollection.items) {
            [__studentMap setObject:student forKey:student.entityKey];
        }

        // See if there are more students on the server.
        if (studentCollection.nextPageToken != nil) {
            NSLog(@"Finished query but there are more students!  So far we have %d students.",
                  (int)__students.count);
            [self _queryForStudentsWithPageToken:studentCollection.nextPageToken withCallback:callback];
        } else {
            NSLog(@"Finished all student queries.  Ended up with %d students.", (int)__students.count);
            __isQueryInProgress = NO;
            if (callback != nil) {
                callback(); // Could also use a notification, but I prefer callback blocks.
            }
        }
    }];
}

@end
