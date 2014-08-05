//
//  GTLGraderecorderStudent+Customization.m
//  Grade Recorder
//
//  Created by David Fisher on 8/4/14.
//  Copyright (c) 2014 Rose-Hulman. All rights reserved.
//

#import "GTLGraderecorderStudent+Customization.h"

#import "GTLGraderecorder.h"


@implementation GTLGraderecorderStudent (Customization)

- (NSComparisonResult) compareFirstLast:(GTLGraderecorderStudent*) otherStudent {
    NSComparisonResult firstNameCompare = [self.firstName compare:otherStudent.firstName];
    if (firstNameCompare != NSOrderedSame) {
        return firstNameCompare;
    }
    NSComparisonResult lastNameCompare = [self.lastName compare:otherStudent.lastName];
    if (lastNameCompare != NSOrderedSame) {
        return lastNameCompare;
    }
    return [self.roseUsername compare:otherStudent.roseUsername];
}

@end
