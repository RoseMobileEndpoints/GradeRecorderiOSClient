//
//  RHStudentAdapter.h
//  Grade Recorder
//
//  Created by David Fisher on 8/4/14.
//  Copyright (c) 2014 Rose-Hulman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RHStudentUtils : NSObject

+ (BOOL) updateStudentRosterWithCallback:(void (^)()) callback;
+ (NSArray*) getStudents; // Array of all GTLGraderecorderStudents.
+ (NSDictionary*) getTeamMap; // Map of NSString to NSArray (of GTLGraderecorderStudents).

@end
