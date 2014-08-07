//
//  RHGradeEntryListViewController_iPhone.m
//  Grade Recorder
//
//  Created by David Fisher on 10/12/13.
//  Copyright (c) 2013 Rose-Hulman. All rights reserved.
//

#import "RHGradeEntryListViewController_iPhone.h"

#import "GTLGraderecorder.h"

#import "GTLGraderecorderStudent+Customization.h"
#import "RHDialogUtils.h"
#import "RHOAuthUtils.h"
#import "RHStudentUtils.h"

#define kGradeEntryCellIdentifier @"GradeEntryCell"
#define kNoStudentsCell @"NoStudentsCell"
#define kNoTeamsCell @"NoTeamsCell"
#define kDefaultScoreString @"100"
#define kAlertTagInsertGradeEntry   1
#define kAlertTagRefreshRoster      2

@interface RHGradeEntryListViewController_iPhone ()

// of GTLGraderecorderStudent (from the RHStudentUtils)
@property (nonatomic, weak) NSArray* students;

// of NSString (entityKey) to GTLGraderecorderStudent
@property (nonatomic, weak) NSDictionary* studentMap;

// of NSString (team names from )
@property (nonatomic, strong) NSArray* teams;

// of NSString (team name) to NSArray (of GTLGraderecorderStudent)
@property (nonatomic, weak) NSDictionary* teamMap;

// of GTLGraderecorderGradeEntry
@property (nonatomic, strong) NSMutableArray* gradeEntries;

// of NSString (student entityKey) to GTLGraderecorderGradeEntry.
@property (nonatomic, strong) NSDictionary* gradeEntryMap;
@end


@implementation RHGradeEntryListViewController_iPhone

#pragma mark - Lifecycle overrides

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
    self.gradeEntryMap = nil; // Reset the gradeEntryMap just in case
    [self.tableView reloadData];
    [self _queryForGradeEntries];
}


#pragma mark - Property getters and setters

- (void) setAssignment:(GTLGraderecorderAssignment*) assignment {
    if (_assignment == nil || ![_assignment isEqual:assignment]) {
        self.gradeEntries = nil;
        self.gradeEntryMap = nil;
    }
    _assignment = assignment;
}


- (NSArray*) students {
    if (_students == nil) {
        _students = [[RHStudentUtils getStudents] sortedArrayUsingSelector:@selector(compareLastFirst:)];
    }
    return _students;
}

- (NSDictionary*) studentMap {
    if (_studentMap == nil) {
        _studentMap = [RHStudentUtils getStudentMap];
    }
    return _studentMap;
}

- (NSArray*) teams {
    if (_teams == nil) {
        // Build the teams array from the teamsMap (there is no RHStudentUtils getTeams function).
        _teams = [[self.teamMap allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    return _teams;
}


- (NSDictionary*) teamMap {
    if (_teamMap == nil) {
        _teamMap = [RHStudentUtils getTeamMap];
    }
    return _teamMap;
}


- (NSMutableArray*) gradeEntries {
    if (_gradeEntries == nil) {
        _gradeEntries = [[NSMutableArray alloc] init];
    }
    return _gradeEntries;
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
                                                    otherButtonTitles:@"Delete a grade entry",
                                  @"Display by Team", @"Display by Student",
                                  @"Refresh student roster", @"Refresh Grade Entries", nil];
    [actionSheet showInView:self.view];
}


#pragma mark - Table view data source

- (NSInteger) tableView:(UITableView*) tableView numberOfRowsInSection:(NSInteger) section {
    NSInteger count = self.displayGradesByTeam ? self.teams.count : self.students.count;
    return count == 0 ? 1 : count;
}


- (UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*) indexPath {
    UITableViewCell *cell = nil;
    if (self.displayGradesByTeam && self.teams.count == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:kNoTeamsCell
                                               forIndexPath:indexPath];
    } else if (!self.displayGradesByTeam && self.students.count == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:kNoStudentsCell
                                               forIndexPath:indexPath];
        
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kGradeEntryCellIdentifier
                                               forIndexPath:indexPath];

        if (self.displayGradesByTeam) {
            NSString* team = self.teams[indexPath.row];
            cell.textLabel.text = team;
            NSArray* teamMembers = [self.teamMap objectForKey:team];
            NSMutableString* scoresString = [[NSMutableString alloc] init];
            for (GTLGraderecorderStudent* teamMember in teamMembers) {
                GTLGraderecorderGradeEntry* potentialGrade = [self.gradeEntryMap objectForKey:teamMember.entityKey];
                if (potentialGrade) {
                    if (scoresString.length > 0) {
                        [scoresString appendString:@", "];
                    }
                    [scoresString appendFormat:@"%@", potentialGrade.score];
                }
            }
            cell.detailTextLabel.text = scoresString;
        } else {
            GTLGraderecorderStudent* student = self.students[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", student.firstName, student.lastName];
            GTLGraderecorderGradeEntry* gradeEntryForStudent = [self.gradeEntryMap objectForKey:student.entityKey];
            if (gradeEntryForStudent) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", gradeEntryForStudent.score];
            } else {
                cell.detailTextLabel.text = nil;
            }
            
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
    return YES;
}


// Override to support editing the table view.
- (void) tableView:(UITableView*) tableView
commitEditingStyle:(UITableViewCellEditingStyle) editingStyle
 forRowAtIndexPath:(NSIndexPath *)indexPath {
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
        } else {
            GTLGraderecorderStudent* student = self.students[indexPath.row];
            GTLGraderecorderGradeEntry* potentialGrade = [self.gradeEntryMap objectForKey:student.entityKey];
            if (potentialGrade) {
                [self _deleteGradeEntry: potentialGrade.entityKey];
                [self.gradeEntries removeObject:potentialGrade];
                self.gradeEntryMap = nil; // Reset the map since the array data has changed.
            }
        }
        if (self.gradeEntries.count == 0) {
            [self setEditing:NO animated:YES];
        }
        [tableView reloadData];
    }
}


- (void) tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath*) indexPath {
    NSString* title;
    NSString* message;
    GTLGraderecorderGradeEntry* potentialGradeEntry = nil;
    if (self.displayGradesByTeam) {
        NSString* team = self.teams[indexPath.row];
        title = @"Insert team grade";
        message = [NSString stringWithFormat:@"for %@", team];
        NSArray* teamMembers = [self.teamMap objectForKey:team];
        for (GTLGraderecorderStudent* teamMember in teamMembers) {
            potentialGradeEntry = [self.gradeEntryMap objectForKey:teamMember.entityKey];
            if (potentialGradeEntry) {
                break; // Found a grade entry for some member of the team.
            }
        }
    } else {
        GTLGraderecorderStudent* student = self.students[indexPath.row];
        title = @"Insert student grade";
        message = [NSString stringWithFormat:@"for %@ %@", student.firstName, student.lastName];
        potentialGradeEntry = [self.gradeEntryMap objectForKey:student.entityKey];
    }
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Send", nil];

    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    UITextField* scoreTextField = [alert textFieldAtIndex:0];
    scoreTextField.placeholder = @"Score (integers only)";
    scoreTextField.keyboardType = UIKeyboardTypeNumberPad;
    if (potentialGradeEntry) {
        scoreTextField.text = [potentialGradeEntry.score description];
    } else {
        scoreTextField.text = kDefaultScoreString;
    }
    alert.tag = kAlertTagInsertGradeEntry;
    [alert show];
}


- (void) tableView:(UITableView*) tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Missing student data"
                                                    message:@"Would you like to update the student roster now?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Update roster", nil];
    alert.tag = kAlertTagRefreshRoster;
    [alert show];
}


#pragma mark - UIAlertViewDelegate

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        NSLog(@"Do nothing.  User hit cancel.");
        return;
    }
    if (alertView.tag == kAlertTagInsertGradeEntry) {
        NSString* scoreString = [[alertView textFieldAtIndex:0] text];
        NSNumber* score = [NSNumber numberWithLong:[scoreString integerValue]];
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (self.displayGradesByTeam) {
            NSString* team = self.teams[indexPath.row];
            NSLog(@"Inserting team grade of %@ for %@", scoreString, team);
            NSArray* teamMembers = [self.teamMap objectForKey:team];
            for (GTLGraderecorderStudent* teamMember in teamMembers) {
                [self _insertGradeEntryForStudentKey:teamMember.entityKey withScore:score];
            }
        } else {
            GTLGraderecorderStudent* student = self.students[indexPath.row];
            NSLog(@"Inserting student grade of %@ for %@ %@", scoreString, student.firstName, student.lastName);
            [self _insertGradeEntryForStudentKey:student.entityKey withScore:score];
        }
        [self.tableView reloadData];
    } else if (alertView.tag == kAlertTagRefreshRoster) {
        [RHStudentUtils updateStudentRosterWithCallback:^{
            NSLog(@"Roster up to date.  Refresh table.");
            [self.tableView reloadData];
        }];
    }
}


#pragma mark - UIActionSheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        NSLog(@"Cancel pressed.");
    }
    switch (buttonIndex) {
        case 0:
            NSLog(@"Delete an grade entry");
            [self setEditing:YES animated:YES];
            break;
        case 1:
            NSLog(@"Display by Team");
            self.displayGradesByTeam = YES;
            [self.tableView reloadData];
            break;
        case 2:
            NSLog(@"Display by Student");
            self.displayGradesByTeam = NO;
            [self.tableView reloadData];
            break;
        case 3: {
            // Update Student Roster
            NSLog(@"Refresh student roster");
            [RHStudentUtils updateStudentRosterWithCallback:^{
                NSLog(@"Roster up to date.  Refresh table.");
                [self.tableView reloadData];
            }];
        }
            break;
        case 4:
            // Refresh the grade entries.
            NSLog(@"Refresh Grade Entries");
            [self _queryForGradeEntries];
            break;
    }
}


#pragma mark - Performing Endpoints Queries

- (void) _queryForGradeEntries {
    [self _queryForGradeEntriesWithPageToken:nil];
}


- (void) _queryForGradeEntriesWithPageToken:(NSString*) pageToken {
    GTLServiceGraderecorder* service = [RHOAuthUtils getService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryListWithAssignmentKey:self.assignment.entityKey];
    query.limit = 20;
    query.pageToken = pageToken;
    if (pageToken == nil) {
        self.gradeEntries = nil; // Reset the array
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket,
                                                    GTLGraderecorderGradeEntryCollection* gradeEntryCollection,
                                                    NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [self.refreshControl endRefreshing];
        if (error != nil) {
            NSLog(@"Unable to query for grade entries %@", error);
            [RHDialogUtils showErrorDialog:error];
            return;
        }
        [self.gradeEntries addObjectsFromArray:gradeEntryCollection.items];
        self.gradeEntryMap = nil; // Anytime the gradeEntries change reset the map.
        if (gradeEntryCollection.nextPageToken != nil) {
            NSLog(@"Finished query but there are more grades!  So far we have %d grades.", (int)self.gradeEntries.count);
            [self _queryForGradeEntriesWithPageToken:gradeEntryCollection.nextPageToken];
        } else {
            NSLog(@"Finished getting grades %d grades found for assignment %@.", (int)self.gradeEntries.count, self.assignment.name);
        }
        NSLog(@"Refresh table data");
        [self.tableView reloadData];
    }];
}


- (void) _insertGradeEntryForStudentKey:(NSString*) studentKey withScore:(NSNumber*) score {
    GTLGraderecorderGradeEntry* newGradeEntry = [[GTLGraderecorderGradeEntry alloc] init];
    newGradeEntry.assignmentKey = self.assignment.entityKey;
    newGradeEntry.studentKey = studentKey;
    newGradeEntry.score = score;
    [self.gradeEntries addObject:newGradeEntry];
    self.gradeEntryMap = nil;
    [self _insertGradeEntry:newGradeEntry];
}


- (void) _insertGradeEntry:(GTLGraderecorderGradeEntry*) gradeEntry {
    GTLServiceGraderecorder* service = [RHOAuthUtils getService];
    GTLQueryGraderecorder * query = [GTLQueryGraderecorder queryForGradeentryInsertWithObject:gradeEntry];
    if ([RHOAuthUtils isLocalHost]) {
        query.JSON = gradeEntry.JSON;
        query.bodyObject = nil;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [service executeQuery:query completionHandler:^(GTLServiceTicket* ticket,
                                                    GTLGraderecorderGradeEntry* updatedGradeEntry,
                                                    NSError* error){
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error == nil) {
            NSLog(@"Successfully updated/added the grade entry.");
            gradeEntry.entityKey = updatedGradeEntry.entityKey;
            [self performSelector:@selector(_queryForGradeEntries) withObject:nil afterDelay:1.0];
        } else {
            NSLog(@"The grade entry did not get updated/added. error = %@", error.localizedDescription);
            [RHDialogUtils showErrorDialog:error];
        }
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
