/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLGraderecorderGradeEntryCollection.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   graderecorder/v1
// Description:
//   Grade Recorder API
// Classes:
//   GTLGraderecorderGradeEntryCollection (0 custom class methods, 2 custom properties)

#import "GTLGraderecorderGradeEntryCollection.h"

#import "GTLGraderecorderGradeEntry.h"

// ----------------------------------------------------------------------------
//
//   GTLGraderecorderGradeEntryCollection
//

@implementation GTLGraderecorderGradeEntryCollection
@dynamic items, nextPageToken;

+ (NSDictionary *)arrayPropertyToClassMap {
  NSDictionary *map =
    [NSDictionary dictionaryWithObject:[GTLGraderecorderGradeEntry class]
                                forKey:@"items"];
  return map;
}

@end