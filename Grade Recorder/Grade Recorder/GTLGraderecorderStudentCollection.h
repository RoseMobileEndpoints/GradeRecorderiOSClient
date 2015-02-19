/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLGraderecorderStudentCollection.h
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   graderecorder/v1
// Description:
//   Grade Recorder API
// Classes:
//   GTLGraderecorderStudentCollection (0 custom class methods, 2 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLGraderecorderStudent;

// ----------------------------------------------------------------------------
//
//   GTLGraderecorderStudentCollection
//

// This class supports NSFastEnumeration over its "items" property. It also
// supports -itemAtIndex: to retrieve individual objects from "items".

@interface GTLGraderecorderStudentCollection : GTLCollectionObject
@property (retain) NSArray *items;  // of GTLGraderecorderStudent
@property (copy) NSString *nextPageToken;
@end