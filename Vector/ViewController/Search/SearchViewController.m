//
//  SearchViewController.m
//  Vector
//
//  Created by Emmanuel ROHEE on 03/12/15.
//  Copyright © 2015 matrix.org. All rights reserved.
//

#import "SearchViewController.h"

#import "RecentsViewController.h"
#import "RecentsDataSource.h"

@interface SearchViewController ()
{
    UISearchBar* searchBar;
}

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    searchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.frame];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.showsCancelButton = YES;
    searchBar.returnKeyType = UIReturnKeySearch;

    self.navigationItem.leftBarButtonItem = [UIBarButtonItem new];
    self.navigationItem.titleView = searchBar;

    // This is a VC for searching. So, show the keyboard with the VC
    dispatch_async(dispatch_get_main_queue(), ^{
        [searchBar becomeFirstResponder];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)displayWithSession:(MXSession *)session
{
    NSMutableArray* viewControllers = [[NSMutableArray alloc] init];
    NSMutableArray* titles = [[NSMutableArray alloc] init];

    [titles addObject: NSLocalizedStringFromTable(@"Rooms", @"Vector", nil)];
    RecentsViewController* recentsViewController = [RecentsViewController recentListViewController];
    RecentsDataSource *recentlistDataSource = [[RecentsDataSource alloc] initWithMatrixSession:session];
    [recentsViewController displayList:recentlistDataSource];
    [viewControllers addObject:recentsViewController];

    [titles addObject: NSLocalizedStringFromTable(@"Messages", @"Vector", nil)];
    /*RecentsViewController**/ recentsViewController = [RecentsViewController recentListViewController];
    /*RecentsDataSource **/recentlistDataSource = [[RecentsDataSource alloc] initWithMatrixSession:session];
    [recentsViewController displayList:recentlistDataSource];
    [viewControllers addObject:recentsViewController];

    [titles addObject: NSLocalizedStringFromTable(@"People", @"Vector", nil)];
    /*RecentsViewController**/ recentsViewController = [RecentsViewController recentListViewController];
    /*RecentsDataSource **/recentlistDataSource = [[RecentsDataSource alloc] initWithMatrixSession:session];
    [recentsViewController displayList:recentlistDataSource];
    [viewControllers addObject:recentsViewController];

    //segmentedViewController.title = NSLocalizedStringFromTable(@"room_details_title", @"Vector", nil);
    [self initWithTitles:titles viewControllers:viewControllers defaultSelected:0];

    // to display a red navbar when the home server cannot be reached.
    [self addMatrixSession:session];
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

@end
