//
//  RHGradeEntryListViewController_iPhone.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHGradeEntryListViewController_iPhone.h"

#import "GTLGraderecorder.h"

#import "RHEndpointsAdapter.h"
#import "RHGradeEntryDetailViewController_iPhone.h"

#define kGradeEntryCellIdentifier @"GradeEntryCell"
#define kLoadingGradeEntriesCellIdentifier @"LoadingGradeEntriesCell"
#define kNoGradeEntriesCellIdentifier @"NoGradeEntriesCell"
#define kPushGradeEntryDetailSegue @"PushGradeEntryDetailSegue"


@interface RHGradeEntryListViewController_iPhone ()
@property (nonatomic) BOOL initialQueryComplete;
@end

@implementation RHGradeEntryListViewController_iPhone

- (void)viewDidLoad {
    [super viewDidLoad];
    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(_queryForGradeEntries)
             forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}


- (void) viewWillAppear:(BOOL)animated {
    self.title = self.assignment.name;
    self.initialQueryComplete = NO;
    [self.tableView reloadData];
    [self _queryForGradeEntries];
}


- (void) setAssignment:(GTLGraderecorderAssignment*) assignment {
    if (_assignment == nil || ![_assignment isEqual:assignment]) {
        [self.gradeEntries removeAllObjects];
    }
    _assignment = assignment;
}


- (IBAction) pressedOptionsButton:(id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Add a grade entry", @"Delete a grade entry", @"Check for new grades", nil];
    [actionSheet showInView:self.view];
}


#pragma mark - Table view data source

- (NSInteger) tableView:(UITableView*) tableView numberOfRowsInSection:(NSInteger) section {
    return self.gradeEntries.count == 0 ? 1 : self.gradeEntries.count;
}


- (UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*) indexPath {
    UITableViewCell *cell = nil;
    if ([self.gradeEntries count] == 0) {
        if (self.initialQueryComplete) {
            cell = [tableView dequeueReusableCellWithIdentifier:kNoGradeEntriesCellIdentifier forIndexPath:indexPath];
            cell.accessoryView = nil;
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kLoadingGradeEntriesCellIdentifier forIndexPath:indexPath];
            UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            cell.accessoryView = activityIndicatorView;
            [((UIActivityIndicatorView*)cell.accessoryView) startAnimating];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kGradeEntryCellIdentifier forIndexPath:indexPath];
        GTLGraderecorderGradeEntry* currentRowGradeEntry = self.gradeEntries[indexPath.row];
        cell.textLabel.text = currentRowGradeEntry.studentKey;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", currentRowGradeEntry.score];
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
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.gradeEntries.count != 0;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        GTLGraderecorderGradeEntry* currentRowGradeEntry = self.gradeEntries[indexPath.row];
        [self _deleteGradeEntry: currentRowGradeEntry.entityKey];
        [self.gradeEntries removeObjectAtIndex:indexPath.row];
        if (self.gradeEntries.count == 0) {
            [tableView reloadData];
            [self setEditing:NO animated:YES];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.gradeEntries.count == 0) {
        return;
    }
    GTLGraderecorderGradeEntry* currentRowGradeEntry = self.gradeEntries[indexPath.row];
    [self performSegueWithIdentifier:kPushGradeEntryDetailSegue sender:currentRowGradeEntry];
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kPushGradeEntryDetailSegue]) {
        RHGradeEntryDetailViewController_iPhone* destination = segue.destinationViewController;
        destination.gradeEntry = sender;
        destination.parentAssignment = self.assignment;
        destination.allGradesForAssignment = self.gradeEntries;
    }
}


#pragma mark - UIActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        NSLog(@"Cancel pressed.");
    }
    switch (buttonIndex) {
        case 0:
            NSLog(@"Add an grade entry");
            [self performSegueWithIdentifier:kPushGradeEntryDetailSegue sender:nil];
            break;
        case 1:
            NSLog(@"Delete an grade entry");
            [self setEditing:YES animated:YES];
            break;
        case 3:
            // Force sync
            NSLog(@"Query for grade entries");
            [self _queryForGradeEntries];
            break;
    }
}


#pragma mark - Performing Endpoints Queries

- (void) _queryForGradeEntries {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryListWithAssignmentKey:self.assignment.entityKey];
    query.limit = 50;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderGradeEntryCollection* gradeEntryCollection, NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.initialQueryComplete = YES;
        if (error == nil) {
            self.gradeEntries = [gradeEntryCollection.items mutableCopy];
            if (gradeEntryCollection.nextPageToken != nil) {
                NSLog(@"TODO: query for more grade entries using %@", gradeEntryCollection.nextPageToken);
            }
        } else {
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
        }
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
}


- (void) _deleteGradeEntry:(NSString*) entityKeyToDelete {
    GTLServiceGraderecorder* service = [[RHEndpointsAdapter sharedInstance] graderecorderService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryDeleteWithEntityKey:entityKeyToDelete];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderGradeEntry* deletedGradeEntry, NSError* error){
        if (error == nil) {
            NSLog(@"Successfully deleted the grade entry.");
        } else {
            NSLog(@"The grade entry did not get deleted.");
            [[RHEndpointsAdapter sharedInstance] showErrorMessage:error];
        }
    }];
}

@end
