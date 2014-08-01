//
//  RHGradeEntryDetailViewController_iPhone.h
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GTLGraderecorderAssignment;
@class GTLGraderecorderGradeEntry;

@interface RHGradeEntryDetailViewController_iPhone : UIViewController <UIPickerViewDataSource,UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) GTLGraderecorderAssignment* parentAssignment;
@property (nonatomic, strong) GTLGraderecorderGradeEntry* gradeEntry;
@property (nonatomic, strong) NSArray* allGradesForAssignment;
@property (nonatomic, strong) NSArray* studentNames;

@property (weak, nonatomic) IBOutlet UIPickerView *studentNamePicker;
@property (weak, nonatomic) IBOutlet UITextField *scoreTextField;
@property (strong, nonatomic) IBOutlet UITextView *statusTextView;
- (IBAction)pressedInsertButton:(id)sender;

@end
