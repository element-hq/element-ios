/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKLanguagePickerViewController.h"

@import libPhoneNumber_iOS;

#import "NSBundle+MatrixKit.h"
#import "MXKSwiftHeader.h"

NSString* const kMXKLanguagePickerViewControllerCellId = @"kMXKLanguagePickerViewControllerCellId";

NSString* const kMXKLanguagePickerCellDataKeyText = @"text";
NSString* const kMXKLanguagePickerCellDataKeyDetailText = @"detailText";
NSString* const kMXKLanguagePickerCellDataKeyLanguage = @"language";

@interface MXKLanguagePickerViewController ()
{
    NSMutableArray<NSDictionary*> *cellDataArray;
    NSMutableArray<NSDictionary*> *filteredCellDataArray;
    
    NSString *previousSearchPattern;
}

@end

@implementation MXKLanguagePickerViewController

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKLanguagePickerViewController class])
                          bundle:[NSBundle bundleForClass:[MXKLanguagePickerViewController class]]];
}

+ (instancetype)languagePickerViewController
{
    return [[[self class] alloc] initWithNibName:NSStringFromClass([MXKLanguagePickerViewController class])
                                          bundle:[NSBundle bundleForClass:[MXKLanguagePickerViewController class]]];
}

+ (NSString *)languageDescription:(NSString *)language
{
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:language];

    return [locale displayNameForKey:NSLocaleIdentifier value:language];
}

+ (NSString *)languageLocalisedDescription:(NSString *)language
{
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[NSBundle mainBundle].preferredLocalizations.firstObject];

    return [locale displayNameForKey:NSLocaleIdentifier value:language];
}

+ (NSString *)defaultLanguage
{
    return [NSBundle mainBundle].preferredLocalizations.firstObject;
}

- (void)finalizeInit
{
    [super finalizeInit];

    cellDataArray = [NSMutableArray array];
    filteredCellDataArray = nil;

    previousSearchPattern = nil;

    // Populate cellDataArray
    // Start by the default language chosen by the OS
    NSString *defaultLanguage = [MXKLanguagePickerViewController defaultLanguage];
    NSString *languageDescription = [VectorL10n languagePickerDefaultLanguage:[MXKLanguagePickerViewController languageDescription:defaultLanguage]];

    [cellDataArray addObject:@{
                               kMXKLanguagePickerCellDataKeyText:languageDescription
                               }];

    // Then, add languages available in the app bundle
    NSArray<NSString *> *localizations = [[NSBundle mainBundle] localizations];
    for (NSString *language in localizations)
    {
        // Do not duplicate the default lang
        if (![language isEqualToString:defaultLanguage])
        {
            languageDescription = [MXKLanguagePickerViewController languageDescription:language];
            NSString *localisedLanguageDescription = [MXKLanguagePickerViewController languageLocalisedDescription:language];

            // Capitalise the description in the language locale
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:language];
            languageDescription = [languageDescription capitalizedStringWithLocale:locale];
            localisedLanguageDescription = [localisedLanguageDescription capitalizedStringWithLocale:locale];

            if (languageDescription)
            {
                [cellDataArray addObject:@{
                                           kMXKLanguagePickerCellDataKeyText: languageDescription,
                                           kMXKLanguagePickerCellDataKeyDetailText: localisedLanguageDescription,
                                           kMXKLanguagePickerCellDataKeyLanguage: language
                                           }];
            }
        }
    }

    // Default to "" in order to differentiate it from nil
    _selectedLanguage = @"";
}

- (void)destroy
{
    [super destroy];

    cellDataArray = nil;
    filteredCellDataArray = nil;

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

    [self setupSearchController];

    self.navigationItem.title = [VectorL10n languagePickerTitle];
        
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.navigationItem.hidesSearchBarWhenScrolling = YES;
}

#pragma mark - Private

- (void)setupSearchController
{
    UISearchController *searchController = [[UISearchController alloc]
     initWithSearchResultsController:nil];
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.hidesNavigationBarDuringPresentation = NO;
    searchController.searchResultsUpdater = self;
    
    // Search bar is hidden for the moment, uncomment following line to enable it.
    // TODO: Enable it once we have enough translations to fill pages and pages
    //        self.navigationItem.searchController = searchController;
    // Make the search bar visible on first view appearance
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    self.definesPresentationContext = YES;
    
    self.searchController = searchController;
}

#pragma mark - UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (filteredCellDataArray)
    {
        return filteredCellDataArray.count;
    }
    return cellDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kMXKLanguagePickerViewControllerCellId];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMXKLanguagePickerViewControllerCellId];
    }
    
    NSInteger index = indexPath.row;
    NSDictionary *itemCellData;
    
    if (filteredCellDataArray)
    {
        if (index < filteredCellDataArray.count)
        {
            itemCellData = filteredCellDataArray[index];
        }
    }
    else if (index < cellDataArray.count)
    {
        itemCellData = cellDataArray[index];
    }
    
    if (itemCellData)
    {
        cell.textLabel.text = itemCellData[kMXKLanguagePickerCellDataKeyText];
        cell.detailTextLabel.text = itemCellData[kMXKLanguagePickerCellDataKeyDetailText];

        // Mark the cell with the selected language
        if (_selectedLanguage == itemCellData[kMXKLanguagePickerCellDataKeyLanguage] || [_selectedLanguage isEqualToString:itemCellData[kMXKLanguagePickerCellDataKeyLanguage]])
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
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
        NSString *language;
        
        if (filteredCellDataArray)
        {
            if (index < filteredCellDataArray.count)
            {
                language = filteredCellDataArray[index][kMXKLanguagePickerCellDataKeyLanguage];
            }
        }
        else if (index < cellDataArray.count)
        {
            language = cellDataArray[index][kMXKLanguagePickerCellDataKeyLanguage];
        }

        [self.delegate languagePickerViewController:self didSelectLangugage:language];
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
            for (NSUInteger index = 0; index < filteredCellDataArray.count;)
            {
                NSString *text = [filteredCellDataArray[index][kMXKLanguagePickerCellDataKeyText] lowercaseString];
                
                if ([text hasPrefix:searchText] == NO)
                {
                    [filteredCellDataArray removeObjectAtIndex:index];
                }
                else
                {
                    index++;
                }
            }
        }
        else
        {
            filteredCellDataArray = [NSMutableArray array];
            
            for (NSUInteger index = 0; index < cellDataArray.count; index++)
            {
                NSString *text = [cellDataArray[index][kMXKLanguagePickerCellDataKeyText] lowercaseString];
                
                if ([text hasPrefix:searchText])
                {
                    [filteredCellDataArray addObject:cellDataArray[index]];
                }
            }
        }
        
        previousSearchPattern = searchText;
    }
    else
    {
        previousSearchPattern = nil;
        filteredCellDataArray = nil;
    }
}

@end
