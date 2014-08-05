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
@property (nonatomic, strong) NSDictionary* gradeEntryMap; // of NSString (student entityKey) to GTLGraderecorderGradeEntry.
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
    [super viewWillAppear:animated];
    self.title = self.assignment.name;
    self.initialQueryComplete = NO;
    self.gradeEntryMap = nil; // Reset the gradeEntryMap in case the detail view changed the data.
    [self.tableView reloadData];
    [self _queryForGradeEntriesWithPageToken:nil withCallback:^{
        NSLog(@"Initial query for grades is complete.");
    }];
}


- (void) setAssignment:(GTLGraderecorderAssignment*) assignment {
    if (_assignment == nil || ![_assignment isEqual:assignment]) {
        [self.gradeEntries removeAllObjects];
    }
    _assignment = assignment;
}

- (NSMutableArray*) gradeEntries {
    if (_gradeEntries == nil) {
        _gradeEntries = [[NSMutableArray alloc] init];
    }
    return _gradeEntries;
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


- (NSDictionary*) gradeEntryMap {
    if (_gradeEntryMap == nil) {
        NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
        for (GTLGraderecorderGradeEntry* grade in self.gradeEntries) {
            [temp setObject:grade forKey:grade.studentKey];
        }
        _gradeEntryMap = temp;
    }
    return _gradeEntryMap;
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
                GTLGraderecorderGradeEntry* gradeEntryForStudent = [self.gradeEntryMap objectForKey:teamMember.entityKey];
                if (gradeEntryForStudent) {
                    if (scoresString.length > 0) {
                        [scoresString appendString:@", "];
                    }
                    [scoresString appendFormat:@"%@", gradeEntryForStudent.score];
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
        if (self.displayGradesByTeam) {
            NSString* team = self.teams[indexPath.row];
            NSArray* teamMembers = [self.teamMap objectForKey:team];
            for (GTLGraderecorderStudent* teamMember in teamMembers) {
                GTLGraderecorderGradeEntry* potentialGrade = [self.gradeEntryMap objectForKey:teamMember.entityKey];
                if (potentialGrade) {
                    [self _deleteGradeEntry: potentialGrade.entityKey];
                    [self.gradeEntries removeObject:potentialGrade];
                    self.gradeEntryMap = nil; // Reset the map since the array data has changed.
                }
            }
            [tableView reloadData];
        } else {
            GTLGraderecorderGradeEntry* currentRowGradeEntry = self.gradeEntries[indexPath.row];
            [self _deleteGradeEntry: currentRowGradeEntry.entityKey];
            [self.gradeEntries removeObjectAtIndex:indexPath.row];
            self.gradeEntryMap = nil; // Reset the map since the array data has changed.
            if (self.gradeEntries.count == 0) {
                [tableView reloadData];
                [self setEditing:NO animated:YES];
            } else {
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        if (self.gradeEntries.count == 0) {
            [self setEditing:NO animated:YES];
        }
    }
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.gradeEntries.count == 0) {
        return;
    }
    GTLGraderecorderGradeEntry* currentRowGradeEntry = nil;
    if (self.displayGradesByTeam) {
        NSString* team = self.teams[indexPath.row];
        NSArray* teamMembers = [self.teamMap objectForKey:team];
        for (GTLGraderecorderStudent* teamMember in teamMembers) {
            currentRowGradeEntry = [self.gradeEntryMap objectForKey:teamMember.entityKey];
            if (currentRowGradeEntry) {
                break; // Found a grade entry for some member of the team.
            }
        }
    } else {
        currentRowGradeEntry = self.gradeEntries[indexPath.row];
    }
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
- (void) prepareForSegue:(UIStoryboardSegue*) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:kPushGradeEntryDetailSegue]) {
        RHGradeEntryDetailViewController_iPhone* destination = segue.destinationViewController;
        destination.gradeEntry = sender;
        destination.parentAssignment = self.assignment;
        destination.enterGradesByTeam = self.displayGradesByTeam;
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
            [self _queryForGradeEntriesWithPageToken:nil withCallback:^{
                NSLog(@"All the grades have loaded");
            }];
            break;
    }
}


#pragma mark - Performing Endpoints Queries

// TODO: Set the order.  The order is actually not being set.  It is fortunate to be in order.
- (void) _queryForGradeEntriesWithPageToken:(NSString*) pageToken withCallback:(void (^)()) callback {
    GTLServiceGraderecorder* service = [RHOAuthUtils getService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryListWithAssignmentKey:self.assignment.entityKey];
    query.limit = 20;
    query.pageToken = pageToken;
    if (pageToken == nil) {
        self.gradeEntries = nil;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLGraderecorderGradeEntryCollection* gradeEntryCollection, NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.initialQueryComplete = YES;
        if (error == nil) {
            [self.gradeEntries addObjectsFromArray:gradeEntryCollection.items];
            self.gradeEntryMap = nil; // Anytime the gradeEntries change reset the map.
            if (gradeEntryCollection.nextPageToken != nil) {
                NSLog(@"Finished query but there are more grades!  So far we have %d students.", (int)self.gradeEntries.count);
                [self _queryForGradeEntriesWithPageToken:gradeEntryCollection.nextPageToken
                                            withCallback:callback];
            } else {
                NSLog(@"Found %d grades for assignment %@.", (int)self.gradeEntries.count, self.assignment.name);
                if (callback) {
                    callback();
                }
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
