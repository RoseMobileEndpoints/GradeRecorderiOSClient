//
//  RHGradeEntryDetailViewController_iPhone.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHGradeEntryDetailViewController_iPhone.h"
#import "RHEndpointsAdapter.h"
#import "GTLGraderecorder.h"

#define kDefaultScoreString @"100"

@interface RHGradeEntryDetailViewController_iPhone ()

@end

@implementation RHGradeEntryDetailViewController_iPhone


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // In a real app you wouldn't be able to hardcode the class roster, but fine here.
    // This app is not ready to ship. :)
    self.studentNames = @[@"Team 01",
                          @"Team 02",
                          @"Team 03",
                          @"Team 04",
                          @"Team 05",
                          @"Team 06",
                          @"Team 07",
                          @"Team 08",
                          @"Team 09",
                          @"Team 10",
                          @"Team 11",
                          @"Team 12",
                          @"Team 13",
                          @"Team 14",
                          @"Team 15",
                          @"Team 16",
                          @"Team 17",
                          @"Team 18",
                          @"Team 19",
                          @"Team 20",
                          @"Team 21",
                          @"Team 22",
                          @"Team 23",
                          @"Team 24"];
}

- (void) viewWillAppear:(BOOL)animated {
    NSInteger studentIndex = 0;
    if (self.gradeEntry != nil) {
        self.scoreTextField.text = [self.gradeEntry.score description];
        NSUInteger searchResult = [self.studentNames indexOfObject:self.gradeEntry.studentName];
        if (searchResult != NSNotFound) {
            studentIndex = searchResult;
        }
    } else {
        self.scoreTextField.text = kDefaultScoreString;
    }
    [self.studentNamePicker selectRow:studentIndex inComponent:0 animated:NO];
    [self.scoreTextField becomeFirstResponder];
}

- (IBAction)pressedInsertButton:(id)sender {
    NSInteger selectedRow = [self.studentNamePicker selectedRowInComponent:0];
    NSString* student = self.studentNames[selectedRow];
    NSNumber* score = [NSNumber numberWithLong:[self.scoreTextField.text integerValue]];
    [self.scoreTextField resignFirstResponder];
    self.statusTextView.text = [NSString stringWithFormat:@"Saving...\n    Student name: %@\n    Score: %@", student, score];
    
    
    GTLGraderecorderGradeEntry* newGradeEntry = [[GTLGraderecorderGradeEntry alloc] init];
    newGradeEntry.assignmentId = self.parentAssignment.identifier;
    
    // Check to see if there is already a grade entry for this exact student name.  If so replace it instead.
    for (GTLGraderecorderGradeEntry* aGradeEntry in self.allGradesForAssignment) {
        if ([aGradeEntry.studentName isEqualToString:student]) {
            self.statusTextView.text = [NSString stringWithFormat:@"%@\nReplacing the %@", self.statusTextView.text, aGradeEntry.score];
            newGradeEntry = aGradeEntry;
            break;
        }
    }
    newGradeEntry.studentName = student;
    newGradeEntry.score = score;
    [self _insertGradeEntry:newGradeEntry];
}


#pragma mark - UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.studentNames.count;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.studentNames[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    //NSLog(@"You just stopped the wheel on %@", self.studentNames[row]);
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

#pragma mark - Endpoints methods

- (void) _insertGradeEntry:(GTLGraderecorderGradeEntry*) gradeEntry {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryInsertWithObject:gradeEntry];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderGradeEntry* updatedGradeEntry, NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error == nil) {
            NSLog(@"Successfully updated/added the grade entry.");
            self.statusTextView.text = @"Grade entry added!";
            self.gradeEntry = nil;
        } else {
            NSLog(@"The grade entry did not get updated/added. error = %@", error.localizedDescription);
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
        }
        [self.scoreTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:2.0];
    }];
}

@end
