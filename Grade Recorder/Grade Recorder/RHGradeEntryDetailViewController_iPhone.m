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
#import "RHDialogUtils.h"
#import "RHOAuthUtils.h"
#import "RHStudentUtils.h"



#define kDefaultScoreString @"100"

@interface RHGradeEntryDetailViewController_iPhone ()
@property (nonatomic, strong) NSArray* students; // of GTLGraderecorderStudent
@property (nonatomic, strong) NSArray* teams;  // of NSString
@property (nonatomic, strong) NSDictionary* teamMap;  // of NSString to NSArray (of GTLGraderecorderStudent)
@end

@implementation RHGradeEntryDetailViewController_iPhone


- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}


- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    [self _reloadPickerData];
}



- (void) _reloadPickerData {
    self.students = [[RHStudentUtils getStudents] sortedArrayUsingSelector:@selector(compareLastFirst:)];
    self.teamMap = [RHStudentUtils getTeamMap];
    self.teams = [[self.teamMap allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [self.studentOrTeamPicker reloadComponent:0];
    [self _populateFieldsUsingGradeEntry];
}


- (void) _populateFieldsUsingGradeEntry {
    // Prepopulate grade entry information if self.gradeEntry is set.
    NSInteger rowToSelectInPicker = 0;
    if (self.gradeEntry != nil) {
        self.scoreTextField.text = [self.gradeEntry.score description];
        for (NSInteger i = 0; i < self.students.count; ++i) {
            GTLGraderecorderStudent* student = self.students[i];
            if ([self.gradeEntry.studentKey isEqualToString:student.entityKey]) {
                if (self.enterGradesByTeam) {
                    NSUInteger searchResult = [self.teams indexOfObject:student.team];
                    if (searchResult != NSNotFound) {
                        rowToSelectInPicker = searchResult;
                    }
                } else {
                    rowToSelectInPicker = i;
                }
                break;
            }
        }
    } else {
        self.scoreTextField.text = kDefaultScoreString;
    }
    [self.studentOrTeamPicker selectRow:rowToSelectInPicker inComponent:0 animated:NO];
    [self.scoreTextField becomeFirstResponder];
}


- (IBAction) pressedInsertButton:(id) sender {
    NSInteger selectedRow = [self.studentOrTeamPicker selectedRowInComponent:0];
    NSNumber* score = [NSNumber numberWithLong:[self.scoreTextField.text integerValue]];
    [self.scoreTextField resignFirstResponder];
    if (self.enterGradesByTeam) {
        NSString* team = self.teams[selectedRow];
        NSArray* teamMembers = [self.teamMap objectForKey:team];
        self.statusTextView.text = [NSString stringWithFormat:@"Saving...\n    Team: %@\n    Score: %@",
                                    team, score];
        for (GTLGraderecorderStudent* teamMember in teamMembers) {
            [self _insertGradeEntryForStudentKey:teamMember.entityKey withScore:score];
        }

    } else {
        GTLGraderecorderStudent* student = self.students[selectedRow];
        self.statusTextView.text = [NSString stringWithFormat:@"Saving...\n    Student name: %@ %@\n    Score: %@",
                                    student.firstName, student.lastName, score];
        [self _insertGradeEntryForStudentKey:student.entityKey withScore:score];
    }
}


- (IBAction)pressedOptionsButton:(id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Enter grades by Team",
                                  @"Enter grades by Student", @"Refresh student roster", nil];
    [actionSheet showInView:self.view];

}


#pragma mark - UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}


// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.enterGradesByTeam ? self.teams.count : self.students.count;
}


#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (self.enterGradesByTeam) {
        return self.teams[row];
    } else {
        GTLGraderecorderStudent* student = self.students[row];
        return [NSString stringWithFormat:@"%@ %@", student.firstName, student.lastName];
    }
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
            // Enter grades by Team
            self.enterGradesByTeam = YES;
            [self _reloadPickerData];
            break;
        case 1:
            // Enter grades by Student
            self.enterGradesByTeam = NO;
            [self _reloadPickerData];
            break;
        case 2:
            // Refresh student roster
            NSLog(@"Refresh student roster");
            [RHStudentUtils updateStudentRosterWithCallback:^{
                [self _reloadPickerData];
            }];
            break;
    }
}


#pragma mark - Endpoints methods

- (void) _insertGradeEntryForStudentKey:(NSString*) studentKey withScore:(NSNumber*) score {
    GTLGraderecorderGradeEntry* newGradeEntry = [[GTLGraderecorderGradeEntry alloc] init];
    newGradeEntry.assignmentKey = self.parentAssignment.entityKey;
    newGradeEntry.studentKey = studentKey;
    newGradeEntry.score = score;
    [self _insertGradeEntry:newGradeEntry];
}


- (void) _insertGradeEntry:(GTLGraderecorderGradeEntry*) gradeEntry {
    GTLServiceGraderecorder* service = [RHOAuthUtils getService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryInsertWithObject:gradeEntry];
    if ([RHOAuthUtils isLocalHost]) {
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
            [RHDialogUtils showErrorDialog:error];
        }
        [self.scoreTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:2.0];
    }];
}

@end
