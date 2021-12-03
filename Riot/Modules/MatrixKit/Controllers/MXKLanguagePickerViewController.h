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

#import "MXKTableViewController.h"

@class MXKLanguagePickerViewController;

 /**
  `MXKLanguagePickerViewController` delegate.
  */
 @protocol MXKLanguagePickerViewControllerDelegate <NSObject>

 /**
  Tells the delegate that the user has selected a language.

  @param languagePickerViewController the `MXKLanguagePickerViewController` instance.
  @param language the ISO language code. nil means use the language chosen by the OS.
  */
 - (void)languagePickerViewController:(MXKLanguagePickerViewController*)languagePickerViewController didSelectLangugage:(NSString*)language;

 @end

/**
 'MXKLanguagePickerViewController' instance displays the list of languages.
 For the moment, it displays only languages available in the application bundle.
 */
@interface MXKLanguagePickerViewController : MXKTableViewController <UISearchResultsUpdating>

/**
The searchController used to manage search.
*/
@property (nonatomic, strong) UISearchController *searchController;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<MXKLanguagePickerViewControllerDelegate> delegate;

/**
 The language marked in the list.
 @"" by default.
 */
@property (nonatomic) NSString *selectedLanguage;

#pragma mark - Class methods

/**
 Returns the `UINib` object initialized for a `MXKLanguagePickerViewController`.
 
 @return The initialized `UINib` object or `nil` if there were errors during initialization
 or the nib file could not be located.
 
 @discussion You may override this method to provide a customized nib. If you do,
 you should also override `listViewController` to return your
 view controller loaded from your custom nib.
 */
+ (UINib *)nib;

/**
 Creates and returns a new `MXKLanguagePickerViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `MXKLanguagePickerViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)languagePickerViewController;

/**
 Get the description string of a language defined by its ISO country code.
 The description is localised in this language.
 
 @param language the ISO country code of the language (ex: "en").
 @return its description (ex: "English").
 */
+ (NSString *)languageDescription:(NSString*)language;

/**
 Get the localised description string of a language defined by its ISO country code.

 @param language the ISO country code of the language (ex: "en").
 @return its localised description (ex: "Anglais" on a device running in French).
 */
+ (NSString *)languageLocalisedDescription:(NSString *)language;

/**
 Get the ISO country code of the language selected by the OS according to
 the device language and languages available in the app bundle.
 */
+ (NSString *)defaultLanguage;

@end

