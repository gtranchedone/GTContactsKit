//
//  GTContactsPickerController.m
//  GTContactsKit
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Gianluca Tranchedone (@gtranchedone)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <GTFoundation/NSString+Web.h>
#import <VENTokenField/VENTokenField.h>
#import "GTContactsPickerController.h"
#import "GTPersonTableViewCell.h"
#import "GTContactsPicker.h"
#import "GTPerson.h"

@interface GTContactsPickerController () <VENTokenFieldDataSource, VENTokenFieldDelegate>

@property (nonatomic, strong) NSMutableArray *pickedContacts;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, assign) BOOL searching;

@property (nonatomic, weak) VENTokenField *tokenField;

@end

@implementation GTContactsPickerController

#pragma mark - Superclass Methods Override -

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIView *headerView = nil;
    CGRect headerViewFrame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44.0f);
    if (self.pickerStyle == GTContactsPickerStyleDefault) {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:headerViewFrame];
        searchBar.delegate = self;
        headerView = searchBar;
    }
    else if (self.pickerStyle == GTContactsPickerStyleMail || self.pickerStyle == GTContactsPickerStyleSingularEmail) {
        VENTokenField *tokenField = [[VENTokenField alloc] initWithFrame:headerViewFrame];
        [tokenField setColorScheme:self.view.tintColor];
        tokenField.layer.borderColor = [UIColor lightGrayColor].CGColor;
        tokenField.layer.borderWidth = 1;
        tokenField.dataSource = self;
        tokenField.delegate = self;
        headerView = tokenField;
        [self setTokenField:tokenField];
    }

    [self.tableView setTableHeaderView:headerView];
    [self.tableView setRowHeight:60.0f];
    [self reloadContacts];
    [self _updateView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tokenField becomeFirstResponder];
}

#pragma mark - Public APIs -

- (instancetype)initWithStyle:(UITableViewStyle)style pickerStyle:(GTContactsPickerStyle)pickerStyle
{
    self = [super initWithStyle:style];
    if (self) {
        _pickerStyle = pickerStyle;
    }
    return self;
}

- (void)selectContactAtIndex:(NSUInteger)index
{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (NSArray *)selectedContacts
{
    return [self.pickedContacts copy];
}

#pragma mark - Private APIs -

- (void)_updateView
{
    self.title = @"Contacts";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(_finish)];
    if (self.allowsCancellation) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                      target:self
                                                                                      action:@selector(_cancel)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
}

- (void)_dismissKeyboard{
    if (self.pickerStyle == GTContactsPickerStyleDefault) {
        UISearchBar *searchBar = (UISearchBar*)self.tableView.tableHeaderView;
        [searchBar resignFirstResponder];
        
    }
    else if (self.pickerStyle == GTContactsPickerStyleMail || self.pickerStyle == GTContactsPickerStyleSingularEmail){
        [self.tokenField resignFirstResponder];
    }
}

- (void)_cancel
{
    [self setPickedContacts:nil];
    [self _finish];
}

- (void)_finish
{
    [self _dismissKeyboard];
    
    if ([self.delegate respondsToSelector:@selector(contactsPickerController:didFinishWithContacts:)]) {
        [self.delegate contactsPickerController:self didFinishWithContacts:self.pickedContacts];
    }
}

- (void)reloadContacts
{
    __weak typeof(self) weakSelf = self;
    [self.contactsPicker fetchContactsWithCompletionBlock:^(NSArray *contacts, NSError *error) {
        [weakSelf setContacts:contacts];
        [weakSelf.tableView reloadData];
    }];
}

- (void)filterListWithSearchString:(NSString *)searchString
{
    if (searchString.length) {
        if (self.pickerStyle == GTContactsPickerStyleSingularEmail) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[cd] %@ OR emailAddress CONTAINS[cd] %@", searchString,searchString];
            self.searchResults = [self.contacts filteredArrayUsingPredicate:predicate];
        }
        else {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[cd] %@", searchString];
            self.searchResults = [self.contacts filteredArrayUsingPredicate:predicate];
        }
    }
    else {
        self.searchResults = self.contacts;
    }
    [self.tableView reloadData];

}

- (NSArray *)peopleWithName:(NSString *)name
{
    NSArray *contacts = self.searching ? self.searchResults : self.contacts;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullName CONTAINS[cd] %@", name];
    NSArray *people = [contacts filteredArrayUsingPredicate:predicate];
    return people;
}

- (GTPerson *)personAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searching) {
        return self.searchResults[(NSUInteger)indexPath.row];
    }
    else {
        return self.contacts[(NSUInteger)indexPath.row];
    }
}

#pragma mark - UITableViewDataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searching ? self.searchResults.count : self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const GTContactsPickerControllerCellIdentifier = @"GTContactsPickerControllerCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GTContactsPickerControllerCellIdentifier];
    if (!cell) {
        if (self.pickerStyle == GTContactsPickerStyleSingularEmail) {
            cell = [[GTPersonTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                reuseIdentifier:GTContactsPickerControllerCellIdentifier];
        }
        else {
            cell = [[GTPersonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                reuseIdentifier:GTContactsPickerControllerCellIdentifier];
        }
        
    }

    GTPerson *person = [self personAtIndexPath:indexPath];
    cell.textLabel.text = person.fullName;
    cell.detailTextLabel.text = self.pickerStyle == GTContactsPickerStyleSingularEmail ? [person.emailAddresses firstObject] : @"";
    cell.imageView.image = person.profileImage;
    cell.accessoryType = [self didSelectContact:person] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

    return cell;
}

- (BOOL)didSelectContact:(GTPerson *)person
{
    BOOL isSelectedContact = [self.pickedContacts containsObject:person];
    return isSelectedContact;
}

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GTPerson *contact = [self personAtIndexPath:indexPath];
    if ([self didSelectContact:contact]) {
        [self.pickedContacts removeObject:contact];
    }
    else {
        [self.pickedContacts addObject:contact];
    }
    [self tokenFieldDidUpdate:self.tokenField];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UISearchBarDelegate -

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
    [self setSearching:YES];
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setText:nil];
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];

    [self setSearching:NO];
    [self setSearchResults:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self filterListWithSearchString:searchText];
}

#pragma mark - VENTokenFieldDelegate

- (void)tokenFieldDidUpdate:(VENTokenField *)tokenField
{
    if (tokenField) {
        [tokenField reloadData];
        [self filterListWithSearchString:nil];
        [self.tableView setTableHeaderView:tokenField];
    }
}

- (void)tokenField:(VENTokenField *)tokenField didEnterText:(NSString *)text
{
    NSArray *matches = [self peopleWithName:text];
    GTPerson *person = nil;
    if (matches.count) {
        person = [matches firstObject];
    }
    else if ([text GT_isValidEmailAddress]) {
        person = [[GTPerson alloc] init];
        person.firstName = text;
        person.emailAddresses = @[text];
    }
    
    if (person && ![self.pickedContacts containsObject:person]) {
        [self.pickedContacts addObject:person];
    }
    
    [self tokenFieldDidUpdate:tokenField];
}

- (void)tokenField:(VENTokenField *)tokenField didDeleteTokenAtIndex:(NSUInteger)index
{
    [self.pickedContacts removeObjectAtIndex:index];
    [self tokenFieldDidUpdate:tokenField];
}

- (void)tokenField:(VENTokenField *)tokenField didChangeText:(NSString *)text
{
    [self filterListWithSearchString:text];
}

- (void)tokenFieldDidBeginEditing:(VENTokenField *)tokenField
{
    [self setSearching:YES];
}

#pragma mark - VENTokenFieldDataSource

- (NSString *)tokenField:(VENTokenField *)tokenField titleForTokenAtIndex:(NSUInteger)index
{
    return [self.pickedContacts[index] fullName];
}

- (NSUInteger)numberOfTokensInTokenField:(VENTokenField *)tokenField
{
    return [self.pickedContacts count];
}

- (NSString *)tokenFieldCollapsedText:(VENTokenField *)tokenField
{
    return [NSString stringWithFormat:@"%lu people", (unsigned long)[self.pickedContacts count]];
}

#pragma mark - Setters and Getters -

- (void)setAllowsCancellation:(BOOL)allowsCancellation
{
    _allowsCancellation = allowsCancellation;
    [self _updateView];
}

- (void)setSearching:(BOOL)searching
{
    _searching = searching;
    if (searching && !self.searchResults) {
        self.searchResults = self.contacts;
    }
    [self.tableView reloadData];
}

- (void)setContacts:(NSArray *)contacts
{
    _contacts = [contacts copy];
    if (self.searching && !self.searchResults) {
        self.searchResults = self.contacts;
    }
    [self.tableView reloadData];
}

- (GTContactsPicker *)contactsPicker
{
    if (!_contactsPicker) {
        self.contactsPicker = [[GTContactsPicker alloc] initWithPickerStyle:self.pickerStyle];
    }
    return _contactsPicker;
}

- (NSMutableArray *)pickedContacts
{
    if (!_pickedContacts) {
        self.pickedContacts = [NSMutableArray array];
    }
    return _pickedContacts;
}

@end
