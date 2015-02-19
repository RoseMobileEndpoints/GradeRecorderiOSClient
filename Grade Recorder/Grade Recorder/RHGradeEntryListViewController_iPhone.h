//
//  RHGradeEntryListViewController_iPhone.h
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GTLGraderecorderAssignment;

@interface RHGradeEntryListViewController_iPhone : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GTLGraderecorderAssignment* assignment;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* optionsBarButton;
@property (nonatomic) BOOL displayGradesByTeam;
@property (weak, nonatomic) IBOutlet UITabBar *displayTypeTabBar;

- (IBAction) pressedOptionsButton:(id) sender;

@end
