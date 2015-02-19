/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLServiceGraderecorder.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   graderecorder/v1
// Description:
//   Grade Recorder API
// Classes:
//   GTLServiceGraderecorder (0 custom class methods, 0 custom properties)

#import "GTLGraderecorder.h"

@implementation GTLServiceGraderecorder

#if DEBUG
// Method compiled in debug builds just to check that all the needed support
// classes are present at link time.
+ (NSArray *)checkClasses {
  NSArray *classes = [NSArray arrayWithObjects:
                      [GTLQueryGraderecorder class],
                      [GTLGraderecorderAssignment class],
                      [GTLGraderecorderAssignmentCollection class],
                      [GTLGraderecorderGradeEntry class],
                      [GTLGraderecorderGradeEntryCollection class],
                      [GTLGraderecorderStudent class],
                      [GTLGraderecorderStudentCollection class],
                      nil];
  return classes;
}
#endif  // DEBUG

- (id)init {
  self = [super init];
  if (self) {
    // Version from discovery.
    self.apiVersion = @"v1";

    // From discovery.  Where to send JSON-RPC.
    // Turn off prettyPrint for this service to save bandwidth (especially on
    // mobile). The fetcher logging will pretty print.
    self.rpcURL = [NSURL URLWithString:@"https://me430-grade-recorder.appspot.com/_ah/api/rpc?prettyPrint=false"];
  }
  return self;
}

@end