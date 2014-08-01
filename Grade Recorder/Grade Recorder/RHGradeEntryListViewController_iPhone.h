//
//  RHGradeEntryListViewController_iPhone.h
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GTLGraderecorderAssignment;

@interface RHGradeEntryListViewController_iPhone : UITableViewController <UIActionSheetDelegate>

@property (nonatomic, strong) GTLGraderecorderAssignment* assignment;
@property (nonatomic, strong) NSMutableArray* gradeEntries;
- (IBAction)pressedOptionsButton:(id)sender;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *optionsBarButton;

@end
