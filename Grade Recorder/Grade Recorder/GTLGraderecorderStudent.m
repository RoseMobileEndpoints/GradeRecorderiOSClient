/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLGraderecorderStudent.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   graderecorder/v1
// Description:
//   Grade Recorder API
// Classes:
//   GTLGraderecorderStudent (0 custom class methods, 5 custom properties)

#import "GTLGraderecorderStudent.h"

// ----------------------------------------------------------------------------
//
//   GTLGraderecorderStudent
//

@implementation GTLGraderecorderStudent
@dynamic entityKey, firstName, lastName, roseUsername, team;

+ (NSDictionary *)propertyToJSONKeyMap {
  NSDictionary *map =
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"first_name", @"firstName",
      @"last_name", @"lastName",
      @"rose_username", @"roseUsername",
      nil];
  return map;
}

@end