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

@interface RHGradeEntryDetailViewController_iPhone : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate,
                                                                       UITextFieldDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) GTLGraderecorderAssignment* parentAssignment;
@property (nonatomic, strong) GTLGraderecorderGradeEntry* gradeEntry; // Optional: Pass a grade to pre-populate fields.
@property (nonatomic) BOOL enterGradesByTeam;

@property (weak, nonatomic) IBOutlet UIPickerView* studentOrTeamPicker;
@property (weak, nonatomic) IBOutlet UITextField* scoreTextField;
@property (strong, nonatomic) IBOutlet UITextView* statusTextView;

- (IBAction) pressedOptionsButton:(id) sender;
- (IBAction) pressedInsertButton:(id) sender;

@end
