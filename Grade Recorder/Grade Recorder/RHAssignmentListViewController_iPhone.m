//
//  RHAssignmentListViewController_iPhone.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHAssignmentListViewController_iPhone.h"

#import "GTLGraderecorder.h"

#import "RHEndpointsAdapter.h"
#import "RHGradeEntryListViewController_iPhone.h"
#import "RHStudentAdapter.h"

#define kAssignmentCellIdentifier @"AssignmentCell"
#define kLoadingAssignmentsCellIdentifier @"LoadingAssignmentsCell"
#define kNoAssignmentsCell @"NoAssignmentsCell"

#define kPushGradeEntryListSeque @"PushGradeEntryListSeque"

@interface RHAssignmentListViewController_iPhone ()
@property (nonatomic) NSIndexPath* accessorySelectedIndexPath;
@property (nonatomic) BOOL showingRenameButtons;
@property (nonatomic) BOOL initialQueryComplete;
@end

@implementation RHAssignmentListViewController_iPhone

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(_queryForAssignments)
             forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}


- (void) viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];
    self.showingRenameButtons = NO;
    self.initialQueryComplete = NO;
    [self _queryForAssignments];
}


- (void) viewDidAppear:(BOOL) animated {
    if ([RHStudentAdapter getStudents] == nil) {
        [RHStudentAdapter updateStudentRosterWithCallback:nil]; // No action needed when complete.
    }
}


- (IBAction)pressedSignOut:(id)sender {
    [[RHEndpointsAdapter sharedInstance] signOut];
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)pressedOptions:(id)sender {
    NSString* toggleRenameButtonsTitle = self.showingRenameButtons ? @"Hide rename buttons" : @"Show rename buttons";
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Add an assignment", @"Delete an assignment", toggleRenameButtonsTitle, @"Refresh student roster", @"Refresh assignment list", nil];
    [actionSheet showInView:self.view];
}


- (NSMutableArray*) assignments {
    if (_assignments == nil) {
        _assignments = [[NSMutableArray alloc] init];
    }
    return _assignments;
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.assignments.count == 0 ? 1 : self.assignments.count;
}


- (UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*) indexPath {
    UITableViewCell *cell = nil;
    if ([self.assignments count] == 0) {
        if (self.initialQueryComplete) {
            cell = [tableView dequeueReusableCellWithIdentifier:kNoAssignmentsCell forIndexPath:indexPath];
            cell.accessoryView = nil;
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kLoadingAssignmentsCellIdentifier forIndexPath:indexPath];
            UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            cell.accessoryView = activityIndicatorView;
            [((UIActivityIndicatorView*)cell.accessoryView) startAnimating];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kAssignmentCellIdentifier forIndexPath:indexPath];
        cell.accessoryView = nil;
        if (self.showingRenameButtons) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        GTLGraderecorderAssignment* currentRowAssignment = self.assignments[indexPath.row];
        cell.textLabel.text = currentRowAssignment.name;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}


- (void) setEditing:(BOOL) editing animated:(BOOL) animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    } else {
        self.navigationItem.rightBarButtonItem = self.optionsBarButton;
    }
}


// Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView*) tableView canEditRowAtIndexPath:(NSIndexPath*) indexPath {
    return self.assignments.count != 0;
}


// Override to support editing the table view.
- (void) tableView:(UITableView*) tableView
commitEditingStyle:(UITableViewCellEditingStyle) editingStyle
 forRowAtIndexPath:(NSIndexPath*) indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GTLGraderecorderAssignment* currentRowAssignment = self.assignments[indexPath.row];
        [self _deleteAssignment: currentRowAssignment.entityKey];
        [self.assignments removeObjectAtIndex:indexPath.row];
        if (self.assignments.count == 0) {
            [self.tableView reloadData];
            [self setEditing:NO animated:YES];  // Nothing more to delete so end editing mode.
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.assignments.count == 0) {
        return;
    }
    GTLGraderecorderAssignment* currentRowAssignment = self.assignments[indexPath.row];
    [self performSegueWithIdentifier:kPushGradeEntryListSeque sender:currentRowAssignment];
}

- (void) tableView:(UITableView*) tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.accessorySelectedIndexPath = indexPath;
    GTLGraderecorderAssignment* currentAssignment = self.assignments[indexPath.row];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Edit assignment name"
                                                    message:[NSString stringWithFormat:@"Current name %@", currentAssignment.name]
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Update name", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField* tf = [alert textFieldAtIndex:0];
    tf.placeholder = @"New name for assignment";
    tf.text = currentAssignment.name;
    [tf setClearButtonMode:UITextFieldViewModeAlways];
    [alert show];
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kPushGradeEntryListSeque]) {
        RHGradeEntryListViewController_iPhone* destination = [segue destinationViewController];
        destination.assignment = sender;
    }
}

#pragma mark - UIActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        NSLog(@"Cancel pressed.");
        return;
    }
    switch (buttonIndex) {
        case 0:
        {
            // Add an assignemnt
            self.accessorySelectedIndexPath = nil;
            NSLog(@"Add an assignment");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Add an assignment"
                                                            message:@""
                                                           delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Add assignment", nil];
            [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            UITextField* tf = [alert textFieldAtIndex:0];
            tf.placeholder = @"Name for assignment";
            [alert show];
        }
            break;
        case 1:
            // Delete an assignemnt
            NSLog(@"Delete an assignment");
            [self setEditing:YES animated:YES];
            break;
        case 2:
            // Toggle rename button state
            NSLog(@"Toggle rename buttons");
            self.showingRenameButtons ^= YES;
            [self.tableView reloadData];
            break;
        case 3:
            // Update Student Roster
            NSLog(@"Refresh student roster");
            [RHStudentAdapter updateStudentRosterWithCallback:nil];
            break;
        case 4:
            // Check for new grades (also done via pull down to refresh)
            NSLog(@"Requery for assignments");
            [self _queryForAssignments];
            break;
    }
}

#pragma mark - UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (self.accessorySelectedIndexPath == nil) {
            NSLog(@"Adding a new assignment");
            NSString* assignmentName = [[alertView textFieldAtIndex:0] text];
            GTLGraderecorderAssignment* newAssignment = [[GTLGraderecorderAssignment alloc] init];
            newAssignment.name = assignmentName;

            // Put the new assignment into the correct alphabetical location.
            NSUInteger insertLocation = [self.assignments
                                   indexOfObject:newAssignment
                                   inSortedRange:(NSRange){0, self.assignments.count}
                                   options:NSBinarySearchingInsertionIndex
                                   usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                       return [[(GTLGraderecorderAssignment*) obj1 name] compare:[(GTLGraderecorderAssignment*) obj2 name]];
                                   }];
            [self.assignments insertObject:newAssignment atIndex:insertLocation];

            if (self.assignments.count == 1) {
                [self.tableView reloadData];
            } else {
                NSIndexPath* newIndexPath = [NSIndexPath indexPathForRow:insertLocation inSection:0];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];                
            }
            [self _insertAssignment:newAssignment];

        } else {
            NSLog(@"Updating an existing assignment name");
            NSString* newAssignmentName = [[alertView textFieldAtIndex:0] text];
            GTLGraderecorderAssignment* currentAssignment = self.assignments[self.accessorySelectedIndexPath.row];
            currentAssignment.name = newAssignmentName;
            [self _insertAssignment:currentAssignment];
            [self.tableView reloadRowsAtIndexPaths:@[self.accessorySelectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}



#pragma mark - Performing Endpoints Queries

- (void) _queryForAssignments {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForAssignmentList];
    query.limit = 30;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderAssignmentCollection* assignmentCollection, NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.initialQueryComplete = YES;
        if (error == nil) {
            if (assignmentCollection.nextPageToken != nil) {
                NSLog(@"TODO: query for more assignemnts using page token %@", assignmentCollection.nextPageToken);
            }
            self.assignments = [assignmentCollection.items mutableCopy];
        } else {
            NSLog(@"Unable to query for assignments %@", error);
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
        }
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
}

- (void) _insertAssignment:(GTLGraderecorderAssignment*) assignment {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForAssignmentInsertWithObject:assignment];
    if (kLocalHostTesting) {
        query.JSON = assignment.JSON;
        query.bodyObject = nil;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderAssignment* updatedAssignment, NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error != nil) {
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
            return;
        }
        assignment.entityKey = updatedAssignment.entityKey;
        [self performSelector:@selector(_queryForAssignments) withObject:nil afterDelay:1.0];
    }];
}

- (void) _deleteAssignment:(NSString*) entityKeyToDelete {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForAssignmentDeleteWithEntityKey:entityKeyToDelete];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderAssignment* deletedAssignment, NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error == nil) {
            NSLog(@"Successfully deleted the assignment.");
        } else {
            NSLog(@"The assignment did not get deleted.");
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
        }
    }];
}

@end
