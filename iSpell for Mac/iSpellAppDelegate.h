//
//  iSpellAppDelegate.h
//  iSpell for Mac
//
//  Created by Mihir Garimella on 2/18/12.
//  Copyright (c) 2012 Mihir Garimella. All rights reserved.
//
//  iSpell is a program that makes it easy for students to study for a spelling bee/test
//

#import <Cocoa/Cocoa.h>
#import "Lists.h"

@interface iSpellAppDelegate : NSObject <NSApplicationDelegate>

// Create an outlet to the main wi

// Start Core Data

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// Creates an outlet to the array controller which populates the main table

@property (weak) IBOutlet NSArrayController *arrayController;

// Creates outlets to the windows

@property (assign) IBOutlet NSWindow *window;

@property (unsafe_unretained) IBOutlet NSPanel *aboutPanel; // About this Application - Window

@property (unsafe_unretained) IBOutlet NSWindow *createWindow; // Create New List - Window

@property (unsafe_unretained) IBOutlet NSWindow *detailWindow; // View Selected List - Window

@property (unsafe_unretained) IBOutlet NSWindow *studyWindow; // Study List - Window

// Creates outlets to the user interface elements

@property (weak) IBOutlet NSTextField *titleNewList; // When creating new list, the text box in which the list title is entered

@property (weak) IBOutlet NSTextField *wordsToCreate; // When creating new list, the text box in which the words are entered

@property (weak) IBOutlet NSButton *editButton; // When viewing the list, the button to edit the list

@property (weak) IBOutlet NSTextField *titleOfList; // When viewing the list, the text box in which the list title is shown

@property (weak) IBOutlet NSTextField *wordsOfList; // When viewing the list, the text box in which the words are shown

@property (weak) IBOutlet NSTextField *submittedWord; // When studying a list, the text box in which the word is entered by the user

@property (weak) IBOutlet NSTextField *currentWord; // When studying a list, the label which displays the current word number

@property (weak) IBOutlet NSTextField *totalWords; // When studying a list, the label which displays the total number of words in the list

@property (weak) IBOutlet NSTextField *numCorrect; // When studying a list, the label which displays the number of correct words so far

@property (weak) IBOutlet NSTextField *numIncorrect; // When studying a list, the label which displays the number of incorrect words so far

// Creates actions triggered by actions in the user interface (for example, button presses)

- (IBAction)saveAction:(id)sender; // Save Core Data database

- (IBAction)openAbout:(id)sender; // Triggered when the button when to open "About this application" is clicked

- (IBAction)createList:(id)sender; // Triggered when the button to create a new list is clicked

- (IBAction)cancelCreation:(id)sender; // Triggered when the button to cancel the creation of a new list is clicked

- (IBAction)submitCreation:(id)sender; // Triggered when the button to confirm the creation of a new list is clicked

- (IBAction)showDetail:(id)sender; // Triggered when the button to open the list detail view is clicked

- (IBAction)closeDetail:(id)sender; // Triggered when the button to close the list detail view and go back to the main view is clicked

- (IBAction)editList:(id)sender; // Triggered when the button in the list detail view to start editing a list is clicked

- (IBAction)studyList:(id)sender; // Triggered when the button to start studying a list is clicked

- (IBAction)studySubmit:(id)sender; // Triggered when RETURN is pressed after a list is typed in the text box while studying

- (IBAction)quitStudySession:(id)sender; // Triggered when, in a study session, the QUIT button is clicked

- (IBAction)repeatSpeech:(id)sender; // Triggered when, in a study session, the button to repeat the current word is clicked

@end
