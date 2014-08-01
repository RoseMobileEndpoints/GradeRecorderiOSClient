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
    self.showingRenameButtons = NO;
    self.initialQueryComplete = NO;
    [self _queryForAssignments];
}

- (IBAction)pressedSignOut:(id)sender {
    [[RHEndpointsAdapter sharedInstance] signOut];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)pressedOptions:(id)sender {
    NSString* toggleRenameButtonsTitle = @"Show rename buttons";
    if (self.showingRenameButtons) {
        toggleRenameButtonsTitle = @"Hide rename buttons";
    }
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Add an assignment", @"Delete an assignment", toggleRenameButtonsTitle, @"Check for new grades", nil];
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
    if (self.assignments.count == 0) {
        return 1;
    }
    return self.assignments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        cell.textLabel.text = currentRowAssignment.assignmentName;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;

}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if (editing) {
        NSLog(@"Change the right button to the edit button for Done.");
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    } else {
        NSLog(@"Put back the options button");
        self.navigationItem.rightBarButtonItem = self.optionsBarButton;
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.assignments.count == 0) {
        return NO;
    }
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GTLGraderecorderAssignment* currentRowAssignment = self.assignments[indexPath.row];
        [self _deleteAssignment: currentRowAssignment.identifier];
        [self.assignments removeObjectAtIndex:indexPath.row];
        
        if (self.assignments.count == 0) {
            [self.tableView reloadData];
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
                                                    message:[NSString stringWithFormat:@"Current name %@", currentAssignment.assignmentName]
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Update name", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField* tf = [alert textFieldAtIndex:0];
    tf.placeholder = @"New name for assignment";
    tf.text = currentAssignment.assignmentName;
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
            // Force sync
            NSLog(@"Force sycn");
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
            newAssignment.assignmentName = assignmentName;

            // Put the new assignment into the correct alphabetical location.
            NSUInteger insertLocation = [self.assignments
                                   indexOfObject:newAssignment
                                   inSortedRange:(NSRange){0, self.assignments.count}
                                   options:NSBinarySearchingInsertionIndex
                                   usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                       return [[(GTLGraderecorderAssignment*) obj1 assignmentName] compare:[(GTLGraderecorderAssignment*) obj2 assignmentName]];
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
            currentAssignment.assignmentName = newAssignmentName;
            [self _insertAssignment:currentAssignment];
            [self.tableView reloadRowsAtIndexPaths:@[self.accessorySelectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
    }
}



#pragma mark - Performing Endpoints Queries

- (void) _queryForAssignments {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForAssignmentList];
    query.order = @"assignment_name";
    query.limit = 30;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderAssignmentCollection* assignmentCollection, NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.initialQueryComplete = YES;
        if (error == nil) {
            if (assignmentCollection.nextPageToken != nil) {
                NSLog(@"TODO: query for more assignemnts");
            }
            self.assignments = [assignmentCollection.items mutableCopy];
        } else {
            NSLog(@"Unable to query for assignments %@", error);
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
        }
        [self.tableView reloadData];
    }];
}

- (void) _insertAssignment:(GTLGraderecorderAssignment*) assignment {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForAssignmentInsertWithObject:assignment];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderAssignment* updatedAssignment, NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error == nil) {
            NSLog(@"Successfully updated/added the assignment.");
            assignment.identifier = updatedAssignment.identifier;
        } else {
            NSLog(@"The assignment did not get updated/added.");
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
        }
        [self _queryForAssignments]; // Do an update for all the assignments. Very important to update the
    }];
}

- (void) _deleteAssignment:(NSNumber*) idToDelete {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForAssignmentDeleteWithIdentifier:idToDelete.longLongValue];
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
