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


+ (void) _queryForStudentsWithPageToken:(NSString*) pageToken withCallback:(void (^)()) callback {
    GTLServiceGraderecorder* service = [RHOAuthUtils getService];
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
            [RHDialogUtils showErrorDialog:error];
            __isQueryInProgress = NO;
            return;
        }

        // Add the new students to the array and the maps.
        [__students addObjectsFromArray:studentCollection.items];
        for (GTLGraderecorderStudent* student in studentCollection.items) {
            // Add this student to the array of students for the team.
            if (student.team) {
                NSMutableArray* teamMembers = [__teamMap objectForKey:student.team];
                if (teamMembers == nil) {
                    teamMembers = [[NSMutableArray alloc] init]; // First student on team.
                }
                [teamMembers addObject:student];
                [__teamMap setObject:teamMembers forKey:student.team];
            }
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
