/*
 Copyright 2017 Vector Creations Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKCountryPickerViewController.h"

@import libPhoneNumber_iOS;

#import "NSBundle+MatrixKit.h"
#import "MXKSwiftHeader.h"


NSString* const kMXKCountryPickerViewControllerCountryCellId = @"kMXKCountryPickerViewControllerCountryCellId";

@interface MXKCountryPickerViewController ()
{
    NSMutableDictionary<NSString*, NSString*> *isoCountryCodesByCountryName;
    
    NSArray<NSString*> *countryNames;
    NSMutableArray<NSString*> *filteredCountryNames;
    
    NSString *previousSearchPattern;
    
    NSMutableDictionary<NSString*, NSNumber*> *callingCodesByCountryName;
}

@end

@implementation MXKCountryPickerViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKCountryPickerViewController class])
                          bundle:[NSBundle bundleForClass:[MXKCountryPickerViewController class]]];
}

+ (instancetype)countryPickerViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKCountryPickerViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKCountryPickerViewController class]]];
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    NSArray *isoCountryCodes = [NSLocale ISOCountryCodes];
    NSMutableArray<NSString*> *countries;
    
    isoCountryCodesByCountryName = [NSMutableDictionary dictionaryWithCapacity:isoCountryCodes.count];
    countries = [NSMutableArray arrayWithCapacity:isoCountryCodes.count];
    
    NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:[[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0]];
    
    for (NSString *isoCountryCode in isoCountryCodes)
    {
        NSString *country = [local displayNameForKey:NSLocaleCountryCode value:isoCountryCode];
        if (country)
        {
            [countries addObject: country];
            isoCountryCodesByCountryName[country] = isoCountryCode;
        }
    }
    
    countryNames = [countries sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    previousSearchPattern = nil;
    filteredCountryNames = nil;
    
    _showCountryCallingCode = NO;
}

- (void)destroy
{
    [super destroy];
    
    isoCountryCodesByCountryName = nil;
    
    countryNames = nil;
    filteredCountryNames = nil;
    
    callingCodesByCountryName = nil;
    
    previousSearchPattern = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Check whether the view controller has been pushed via storyboard
    if (!self.tableView)
    {
        // Instantiate view controller objects
        [[[self class] nib] instantiateWithOwner:self options:nil];
    }
    
    self.navigationItem.title = [VectorL10n countryPickerTitle];
    
    [self setupSearchController];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationItem.hidesSearchBarWhenScrolling = YES;
}

#pragma mark - 

- (void)setShowCountryCallingCode:(BOOL)showCountryCallingCode
{
    if (_showCountryCallingCode != showCountryCallingCode)
    {
        _showCountryCallingCode = showCountryCallingCode;
        
        if (_showCountryCallingCode && !callingCodesByCountryName)
        {
            callingCodesByCountryName = [NSMutableDictionary dictionary];
            
            for (NSString *countryName in countryNames)
            {
                NSString *isoCountryCode = isoCountryCodesByCountryName[countryName];
                NSNumber *callingCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:isoCountryCode];
                
                callingCodesByCountryName[countryName] = callingCode;
            }
        }
        
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (void)setupSearchController
{
    UISearchController *searchController = [[UISearchController alloc]
     initWithSearchResultsController:nil];
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.hidesNavigationBarDuringPresentation = NO;
    searchController.searchResultsUpdater = self;
    
    self.navigationItem.searchController = searchController;
    // Make the search bar visible on first view appearance
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    self.definesPresentationContext = YES;
    
    self.searchController = searchController;
}

#pragma mark - UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (filteredCountryNames)
    {
        return filteredCountryNames.count;
    }
    return countryNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kMXKCountryPickerViewControllerCountryCellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:kMXKCountryPickerViewControllerCountryCellId];
    }
    
    NSInteger index = indexPath.row;
    NSString *countryName;
    
    if (filteredCountryNames)
    {
        if (index < filteredCountryNames.count)
        {
            countryName = filteredCountryNames[index];
        }
    }
    else if (index < countryNames.count)
    {
        countryName = countryNames[index];
    }
    
    if (countryName)
    {
        cell.textLabel.text = countryName;
        
        if (self.showCountryCallingCode)
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@", [callingCodesByCountryName[countryName] stringValue]];
        }
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.delegate)
    {
        NSInteger index = indexPath.row;
        NSString *countryName;
        
        if (filteredCountryNames)
        {
            if (index < filteredCountryNames.count)
            {
                countryName = filteredCountryNames[index];
            }
        }
        else if (index < countryNames.count)
        {
            countryName = countryNames[index];
        }
        
        if (countryName)
        {
            NSString *isoCountryCode = isoCountryCodesByCountryName[countryName];
            
            [self.delegate countryPickerViewController:self didSelectCountry:isoCountryCode];
        }
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = searchController.searchBar.text;
    
    if (searchText.length)
    {
        searchText = [searchText lowercaseString];
        
        if (previousSearchPattern && [searchText hasPrefix:previousSearchPattern])
        {
            for (NSUInteger index = 0; index < filteredCountryNames.count;)
            {
                NSString *countryName = [filteredCountryNames[index] lowercaseString];
                
                if ([countryName hasPrefix:searchText] == NO)
                {
                    [filteredCountryNames removeObjectAtIndex:index];
                }
                else
                {
                    index++;
                }
            }
        }
        else
        {
            filteredCountryNames = [NSMutableArray array];
            
            for (NSUInteger index = 0; index < countryNames.count; index++)
            {
                NSString *countryName = [countryNames[index] lowercaseString];
                
                if ([countryName hasPrefix:searchText])
                {
                    [filteredCountryNames addObject:countryNames[index]];
                }
            }
        }
        
        previousSearchPattern = searchText;
    }
    else
    {
        previousSearchPattern = nil;
        filteredCountryNames = nil;
    }
    
    [self.tableView reloadData];
}

@end
