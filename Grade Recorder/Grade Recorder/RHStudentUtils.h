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
+ (NSArray*) getStudents; // Returns an array of all GTLGraderecorderStudents.
+ (NSDictionary*) getStudentMap; // Return map of entityKey to GTLGraderecorderStudents.

@end
