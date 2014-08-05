//
//  RHGradeEntryListViewController_iPhone.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHGradeEntryListViewController_iPhone.h"

#import "GTLGraderecorder.h"

#import "RHDialogUtils.h"
#import "RHGradeEntryDetailViewController_iPhone.h"
#import "RHOAuthUtils.h"
#import "RHStudentUtils.h"

#define kGradeEntryCellIdentifier @"GradeEntryCell"
#define kLoadingGradeEntriesCellIdentifier @"LoadingGradeEntriesCell"
#define kNoGradeEntriesCellIdentifier @"NoGradeEntriesCell"
#define kPushGradeEntryDetailSegue @"PushGradeEntryDetailSegue"


@interface RHGradeEntryListViewController_iPhone ()
@property (nonatomic) BOOL initialQueryComplete;
@property (nonatomic, strong) NSMutableArray* gradeEntries; // of GTLGraderecorderGradeEntry
@property (nonatomic, weak) NSDictionary* studentMap; // of NSString (entityKey) to GTLGraderecorderStudent
@property (nonatomic, weak) NSDictionary* teamMap; // of NSString to NSArray (of GTLGraderecorderStudent)
@property (nonatomic, strong) NSArray* teams; // of NSString
@property (nonatomic, strong) NSDictionary* scoresMap; // of NSString (student entityKey) to NSNumber.
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


- (NSDictionary*) studentMap {
    if (_studentMap == nil) {
        _studentMap = [RHStudentUtils getStudentMap];
    }
    return _studentMap;
}


- (NSDictionary*) teamMap {
    if (_teamMap == nil) {
        _teamMap = [RHStudentUtils getTeamMap];
    }
    return _teamMap;
}


- (NSArray*) teams {
    if (_teams == nil) {
        // Build the teams array from the teamsMap
        _teams = [[self.teamMap allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return _teams;
}


- (NSDictionary*) scoresMap {
    if (_scoresMap == nil) {
        NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
        for (GTLGraderecorderGradeEntry* grade in self.gradeEntries) {
            [temp setObject:grade.score forKey:grade.studentKey];
        }
        _scoresMap = temp;
    }
    return _scoresMap;
}


- (IBAction) pressedOptionsButton:(id)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Add a grade entry", @"Delete a grade entry",
                                  @"Display by Team", @"Display by Student",
                                  @"Refresh student roster", @"Refresh Grade Entries", nil];
    [actionSheet showInView:self.view];
}


#pragma mark - Table view data source

- (NSInteger) tableView:(UITableView*) tableView numberOfRowsInSection:(NSInteger) section {
    if (self.gradeEntries.count == 0) {
        return 1;
    }
    if (self.displayGradesByTeam) {
        return self.teams.count;
    } else {
        return self.gradeEntries.count;
    }
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
        if (self.displayGradesByTeam) {
            NSString* team = self.teams[indexPath.row];
            cell.textLabel.text = team;
            NSArray* teamMembers = [self.teamMap objectForKey:team];
            NSMutableString* scoresString = [[NSMutableString alloc] init];
            for (GTLGraderecorderStudent* teamMember in teamMembers) {
                NSNumber* scoreForStudent = [self.scoresMap objectForKey:teamMember.entityKey];
                if (scoreForStudent) {
                    if (scoresString.length > 0) {
                        [scoresString appendString:@", "];
                    }
                    [scoresString appendFormat:@"%@", scoreForStudent];
                }
            }
            cell.detailTextLabel.text = scoresString;
        } else {
            // Displaying in student mode is easy.  Each grade entry is a row.
            GTLGraderecorderGradeEntry* currentRowGradeEntry = self.gradeEntries[indexPath.row];
            GTLGraderecorderStudent* student = [self.studentMap objectForKey:currentRowGradeEntry.studentKey];
            if (student != nil) {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", student.firstName, student.lastName];
            } else {
                cell.textLabel.text = @"Missing name";
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

            }
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", currentRowGradeEntry.score];
        }
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


- (void) tableView:(UITableView*) tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Missing student data"
                                                    message:@"Would you like to update the student roster now?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Update roster", nil];
    [alert show];
}


#pragma mark - UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [RHStudentUtils updateStudentRosterWithCallback:^{
            NSLog(@"Roster up to date.  Refresh table.");
            [self.tableView reloadData];
        }];
    }
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kPushGradeEntryDetailSegue]) {
        RHGradeEntryDetailViewController_iPhone* destination = segue.destinationViewController;
        destination.gradeEntry = sender;
        destination.parentAssignment = self.assignment;
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
        case 2:
            NSLog(@"Display by Team");
            self.displayGradesByTeam = YES;
            [self.tableView reloadData];
            break;
        case 3:
            NSLog(@"Display by Student");
            self.displayGradesByTeam = NO;
            [self.tableView reloadData];
            break;
        case 4: {
            // Update Student Roster
            NSLog(@"Refresh student roster");
            [RHStudentUtils updateStudentRosterWithCallback:^{
                NSLog(@"Roster up to date.  Refresh table.");
                [self.tableView reloadData];
            }];
        }
            break;
        case 5:
            // Refresh the grade entries.
            NSLog(@"Refresh Grade Entries");
            [self _queryForGradeEntries];
            break;
    }
}


#pragma mark - Performing Endpoints Queries

// TODO: Refactor to allow more than 50 grades in an assignment.
// TODO: Set the order.  The order is actually not being set.  It is fortunate to be in order.
- (void) _queryForGradeEntries {
    GTLServiceGraderecorder* service = [RHOAuthUtils getService];
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
            [RHDialogUtils showErrorDialog:error];
        }
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    }];
}


- (void) _deleteGradeEntry:(NSString*) entityKeyToDelete {
    GTLServiceGraderecorder* service = [RHOAuthUtils getService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryDeleteWithEntityKey:entityKeyToDelete];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderGradeEntry* deletedGradeEntry, NSError* error){
        if (error == nil) {
            NSLog(@"Successfully deleted the grade entry.");
        } else {
            NSLog(@"The grade entry did not get deleted.");
            [RHDialogUtils showErrorDialog:error];
        }
    }];
}

@end
