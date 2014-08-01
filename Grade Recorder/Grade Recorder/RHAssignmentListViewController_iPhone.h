//
//  RHAssignmentListViewController_iPhone.h
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RHAssignmentListViewController_iPhone : UITableViewController <UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSMutableArray* assignments;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *optionsBarButton;

- (IBAction)pressedSignOut:(id)sender;
- (IBAction)pressedOptions:(id)sender;

@end
