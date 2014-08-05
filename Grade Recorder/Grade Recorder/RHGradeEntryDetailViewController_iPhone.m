//
//  RHGradeEntryDetailViewController_iPhone.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHGradeEntryDetailViewController_iPhone.h"

#import "GTLGraderecorder.h"

#import "GTLGraderecorderStudent+Customization.h"
#import "RHEndpointsAdapter.h"
#import "RHStudentAdapter.h"



#define kDefaultScoreString @"100"

@interface RHGradeEntryDetailViewController_iPhone ()
@end

@implementation RHGradeEntryDetailViewController_iPhone


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // In a real app you wouldn't be able to hardcode the class roster, but fine here.
    // This app is not ready to ship. :)
    self.students = [[RHStudentAdapter getStudents] sortedArrayUsingSelector:@selector(compareFirstLast:)];
    
}


- (void) viewWillAppear:(BOOL)animated {
    NSInteger studentIndex = 0;
    if (self.gradeEntry != nil) {
        self.scoreTextField.text = [self.gradeEntry.score description];
        for (NSInteger i = 0; i < self.students.count; ++i) {
            if ([self.gradeEntry.studentKey isEqualToString:((GTLGraderecorderStudent*)self.students[i]).entityKey]) {
                studentIndex = i;
                break;
            }
        }
    } else {
        self.scoreTextField.text = kDefaultScoreString;
    }
    [self.studentNamePicker selectRow:studentIndex inComponent:0 animated:NO];
    [self.scoreTextField becomeFirstResponder];
}


- (IBAction)pressedInsertButton:(id)sender {
    NSInteger selectedRow = [self.studentNamePicker selectedRowInComponent:0];
    GTLGraderecorderStudent* student = self.students[selectedRow];
    NSNumber* score = [NSNumber numberWithLong:[self.scoreTextField.text integerValue]];
    [self.scoreTextField resignFirstResponder];
    self.statusTextView.text = [NSString stringWithFormat:@"Saving...\n    Student name: %@\n    Score: %@", student, score];
    
    GTLGraderecorderGradeEntry* newGradeEntry = [[GTLGraderecorderGradeEntry alloc] init];
    newGradeEntry.assignmentKey = self.parentAssignment.entityKey;
    newGradeEntry.studentKey = student.entityKey;
    newGradeEntry.score = score;
    [self _insertGradeEntry:newGradeEntry];
}


- (IBAction)pressedOptionsButton:(id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Enter grades by Team", @"Student: First Last", @"Student: Last, First", @"Refresh student roster", nil];
    [actionSheet showInView:self.view];

}


#pragma mark - UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.students.count;
}


#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    GTLGraderecorderStudent* student = self.students[row];
    return [NSString stringWithFormat:@"%@ %@", student.firstName, student.lastName];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    //NSLog(@"You just stopped the wheel on %@", self.studentNames[row]);
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        NSLog(@"Cancel pressed.");
        return;
    }
    switch (buttonIndex) {
        case 0:
            // Enter grades by team
            break;
        case 1:
            // Enter grades by team student First Last
            break;
        case 2:
            // Enter grades by team student Last, First
            break;
        case 3:
            // Refresh student roster
            NSLog(@"Refresh student roster");
            [RHStudentAdapter updateStudentRosterWithCallback:^{
                NSLog(@"TODO: Refresh the picker data.");
            }];
            break;
    }
}


#pragma mark - Endpoints methods

- (void) _insertGradeEntry:(GTLGraderecorderGradeEntry*) gradeEntry {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryInsertWithObject:gradeEntry];
    if (kLocalHostTesting) {
        query.JSON = gradeEntry.JSON;
        query.bodyObject = nil;
    }
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
