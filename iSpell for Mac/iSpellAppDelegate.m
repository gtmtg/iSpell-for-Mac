//
//  iSpellAppDelegate.m
//  iSpell for Mac
//
//  Created by Mihir Garimella on 2/18/12.
//  Copyright (c) 2012 Mihir Garimella. All rights reserved.
//
//  iSpell is a program that makes it easy for students to study for a spelling bee/test
//

#import "iSpellAppDelegate.h"

// Defining Global Variables

BOOL editModeOn; // Tells the program whether the user is editing the list in the View Selected List window
NSMutableArray *wordsInList; // An array of the words in the list that is currently being studied - the elements in this array are shuffled before the study session begins
NSString *titleBeforeEditing; // The title before the user starts editing a list in View Selected List - if the user changes the list title, the program still needs to know the title of the list to be able to save changes
NSSpeechSynthesizer *speechSynth; // The speech synthesizer object used to speak the words
int correctSoFar; // The number of correct words so far for the current study session - used to populate the "Number correct" label in the Study List window
int incorrectSoFar; // The number of incorrect words so far for the current study session - used to populate the "Number incorrect" label in the Study List window
int currentWordNum; // The number of the current word in the study session - used to populate the "Word number" label in the Study List window
int numWords; // The total number of words in a given list - used to populate the value of the "Total words" label in the Study List window and to check if the study session is done
NSString *currentStudyWord; // The current word that is being studied - used to check if the entered word is correct
NSMutableArray *wrongWords; // An array of the words that are incorrect in the current study session - it's a global variable because if it was initialized everytime a word was entered, its elements would be cleared

// Declaring connections to UI elements - see header file for details

@implementation iSpellAppDelegate

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;

@synthesize window = _window;
@synthesize aboutPanel = _aboutPanel;
@synthesize arrayController = _arrayController;
@synthesize createWindow = _createWindow;
@synthesize detailWindow = _detailWindow;
@synthesize studyWindow = _studyWindow;

@synthesize titleNewList = _titleNewList;
@synthesize wordsToCreate = _wordsToCreate; 
@synthesize editButton = _editButton;
@synthesize titleOfList = _titleOfList;
@synthesize wordsOfList = _wordsOfList;
@synthesize submittedWord = _submittedWord;
@synthesize currentWord = _currentWord;
@synthesize totalWords = _totalWords;
@synthesize numCorrect = _numCorrect;
@synthesize numIncorrect = _numIncorrect;

// Code to be executed on application start

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    speechSynth = [[NSSpeechSynthesizer alloc] init]; // Creates the Speech Synthesizer
    [speechSynth setDelegate:self]; // Make the Speech Synthesizer send delegate notifications so the program
    editModeOn = false; // Set edit mode variable (see above) to false, meaning that edit mode is off
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.mihir.iSpell_for_Mac" in the user's Application Support directory.

- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.mihir.iSpell_for_Mac"];
}

// Creates if necessary and returns the managed object model for the application.

- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"iSpell_for_Mac" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![[properties objectForKey:NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"iSpell_for_Mac.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __persistentStoreCoordinator = coordinator;
    
    return __persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 

- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];

    return __managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Save Core Data database

- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

// Triggered when the button when to open "About this application" is clicked

- (IBAction)openAbout:(id)sender {
    [[self aboutPanel] setIsVisible:true];
}

// Triggered when the button to create a new list is clicked

- (IBAction)createList:(id)sender {
    // Clears values for in the create window and makes it visible
    _titleNewList.stringValue = @"";
    _wordsToCreate.stringValue = @"";
    [[self createWindow] setIsVisible:true];
    [[self window] setIsVisible:false];
}

// Triggered when the button to cancel the creation of a new list is clicked

- (IBAction)cancelCreation:(id)sender {
    [[self window] setIsVisible:true];
    [[self createWindow] setIsVisible:false];
}

// Triggered when the button to confirm the creation of a new list is clicked

- (IBAction)submitCreation:(id)sender {
    // Get title and words and store them as variables
    NSString *titleOfNewList = _titleNewList.stringValue;
    NSString *wordsForNewList = _wordsToCreate.stringValue;
    // Check if title is given and display dialog if it's not
    if([titleOfNewList length] == 0) {
        NSAlert *needTitle = [[NSAlert alloc] init];
        [needTitle setMessageText:@"You need to add a title to create a list!"];
        [needTitle runModal];
        return;
    }
    // Check if words are given and display dialog if they're not
    else if([wordsForNewList length] == 0) {
        NSAlert *needWords = [[NSAlert alloc] init];
        [needWords setMessageText:@"You need to add words to create a list!"];
        [needWords runModal];
        return;
    }
    // Execute fetch request for objects with the same name and display a dialog box if there are any
    NSFetchRequest *testSimilar = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Lists" inManagedObjectContext:self.managedObjectContext];
    [testSimilar setEntity:entity];
    NSPredicate *getSimilar = [NSPredicate predicateWithFormat:@"(name == %@)", titleOfNewList];
    [testSimilar setPredicate:getSimilar];
    NSError *error = nil;
    NSArray *fetchedSimilarObjects = [self.managedObjectContext executeFetchRequest:testSimilar error:&error];
    if (fetchedSimilarObjects == nil) {
        return;
    }
    int similarObjectsCount = [fetchedSimilarObjects count];
    if (similarObjectsCount != 0) {
        NSAlert *titleTaken = [[NSAlert alloc] init];
        [titleTaken setMessageText:@"An existing list already has this title. You must pick another one."];
        [titleTaken runModal];
        return;
    }
    // Create new list object and switch back to the main window
    Lists *newList = [NSEntityDescription insertNewObjectForEntityForName:@"Lists" inManagedObjectContext:self.managedObjectContext];
    newList.name = titleOfNewList;
    newList.words = wordsForNewList;
    [[self window] setIsVisible:true];
    [[self createWindow] setIsVisible:false];
}

// Triggered when the button to open the list detail view is clicked

- (IBAction)showDetail:(id)sender {
    // Get selected list object from the table
    NSArray* selectedObjects = [_arrayController selectedObjects];
    NSEntityDescription *listsEntity = [selectedObjects objectAtIndex:0];
    // Get attributes, fill them in, and switch to the detail view
    NSString *name = [listsEntity valueForKey:@"name"];
    NSString *words = [listsEntity valueForKey:@"words"];
    _titleOfList.stringValue = name;
    _wordsOfList.stringValue = words;
    [[self detailWindow] setIsVisible:true];
    [[self window] setIsVisible:false];
}

// Triggered when the button to close the list detail view and go back to the main view is clicked

- (IBAction)closeDetail:(id)sender {
    [[self window] setIsVisible:true];
    [[self detailWindow] setIsVisible:false];
}

// Triggered when the button in the list detail view to start editing a list is clicked

- (IBAction)editList:(id)sender {
    // If edit mode is one, turn it off
    if (editModeOn == true) {
        [_titleOfList setEditable:false];
        [_wordsOfList setEditable:false];
        // Take the title and the words entered and store them as variables
        NSString *titleOfEditedList = _titleOfList.stringValue;
        NSString *wordsOfEditedList = _wordsOfList.stringValue;
        // Check if title is entered and display a dialog box if it's not
        if([titleOfEditedList length] == 0) {
            NSAlert *needTitle = [[NSAlert alloc] init];
            [needTitle setMessageText:@"The list must have a title!"];
            [needTitle runModal];
            return;
        }
        // Check if words are entered and display a dialog box if they're not
        else if([wordsOfEditedList length] == 0) {
            NSAlert *needWords = [[NSAlert alloc] init];
            [needWords setMessageText:@"The list must contain words!"];
            [needWords runModal];
            return;
        }
        // Execute fetch request for objects with the same name and display a dialog box if there are any
        NSFetchRequest *testSimilar = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Lists" inManagedObjectContext:self.managedObjectContext];
        [testSimilar setEntity:entity];
        NSPredicate *getSimilar = [NSPredicate predicateWithFormat:@"(name == %@)", titleOfEditedList];
        [testSimilar setPredicate:getSimilar];
        NSError *error = nil;
        NSArray *fetchedSimilarObjects = [self.managedObjectContext executeFetchRequest:testSimilar error:&error];
        if (fetchedSimilarObjects == nil) {
            return;
        }
        int similarObjectsCount = [fetchedSimilarObjects count];
        if (similarObjectsCount > 1) {
            NSAlert *titleTaken = [[NSAlert alloc] init];
            [titleTaken setMessageText:@"An existing list already has this title. You must pick another one."];
            [titleTaken runModal];
            return;
        }
        // Execute another fetch request to get the object being edited
        NSFetchRequest *fetchObjectBeingEdited = [[NSFetchRequest alloc] init];
        [fetchObjectBeingEdited setEntity:entity];
        NSPredicate *getObjectBeingEdited = [NSPredicate predicateWithFormat:@"(name == %@)", titleBeforeEditing];
        [fetchObjectBeingEdited setPredicate:getObjectBeingEdited];
        error = nil;
        NSArray *fetchedObject = [self.managedObjectContext executeFetchRequest:fetchObjectBeingEdited error:&error];
        if (fetchedObject == nil) {
            return;
        }
        Lists *objectBeingEdited = [fetchedObject objectAtIndex:0];
        // Update the object and save changes to the database
        [objectBeingEdited setValue:titleOfEditedList forKey:@"name"];
        [objectBeingEdited setValue:wordsOfEditedList forKey:@"words"];
        error = nil;
        [self.managedObjectContext save:&error];
        // Turn edit mode off again
        _editButton.title = @"Edit List";
        editModeOn = false;
    }
    else if (editModeOn == false) {
        // Make the text boxes editable and and turn edit mode on
        [_titleOfList setEditable:true];
        [_wordsOfList setEditable:true];
        titleBeforeEditing = _titleOfList.stringValue;
        _editButton.title = @"Save List";
        editModeOn = true;
    }
}

// Triggered when the button to start studying a list is clicked

- (IBAction)studyList:(id)sender {
    // Get the words in the list and make them into an array
    wordsInList = [[NSMutableArray alloc] initWithCapacity:1];
    NSString *wordsInTextBox = _wordsOfList.stringValue;
    for (NSString *wordOnLine in [wordsInTextBox componentsSeparatedByString:@"\n"]) {
        [wordsInList addObject:wordOnLine];
    }
    numWords = [wordsInList count];
    
    if(numWords == 0) {
        NSAlert *noWords = [[NSAlert alloc] init];
        [noWords setMessageText:@"There aren't any words in this list! Please add some before studying..."];
        [noWords runModal];
        return;
    }
    
    // Shuffle the words in the array
    if(numWords > 1) {
        for (int wordBeingExchanged = 0; wordBeingExchanged < numWords; wordBeingExchanged++) {
            srand(clock());
            int positionToSendTo = rand() % (numWords - 1);
            [wordsInList exchangeObjectAtIndex:wordBeingExchanged withObjectAtIndex:positionToSendTo];
        }
    }
    // Clear user stats, open the studying window, and start speaking the first word
    wrongWords = [[NSMutableArray alloc] initWithCapacity:0];
    currentWordNum = 1;
    [_currentWord setStringValue:[NSString stringWithFormat:@"%d", currentWordNum]];
    [_totalWords setStringValue:[NSString stringWithFormat:@"%d", numWords]];
    correctSoFar = 0;
    incorrectSoFar = 0;
    [_numCorrect setStringValue:[NSString stringWithFormat:@"%d", correctSoFar]];
    [_numIncorrect setStringValue:[NSString stringWithFormat:@"%d", incorrectSoFar]];
    currentStudyWord = [wordsInList objectAtIndex:currentWordNum - 1];
    _submittedWord.stringValue = @"";
    [[self studyWindow] setIsVisible:true];
    [[self detailWindow] setIsVisible:false];
    [speechSynth startSpeakingString:currentStudyWord];
}

// Triggered when RETURN is pressed after a list is typed in the text box while studying

- (IBAction)studySubmit:(id)sendorder {
    // Increase the current word number
    currentWordNum = currentWordNum + 1;
    // Get the entered word, save it to a string, and compare with the correct answer
    NSString *submittedWordString = _submittedWord.stringValue;
    if ([submittedWordString isEqualToString:currentStudyWord] == YES){
        correctSoFar = correctSoFar + 1;
        [_numCorrect setStringValue:[NSString stringWithFormat:@"%d", correctSoFar]];
        [speechSynth startSpeakingString:@"Correct!"];
        [NSThread sleepForTimeInterval:1.25];
    }
    else {
        incorrectSoFar = incorrectSoFar + 1;
        [_numIncorrect setStringValue:[NSString stringWithFormat:@"%d", incorrectSoFar]];
        [wrongWords addObject:currentStudyWord];
        [speechSynth startSpeakingString:@"Sorry, that is incorrect..."];
        [NSThread sleepForTimeInterval:1.75];
    }
    // Check if the question is the last one. If it isn't, update the UI and go on to the next word. If it is, tell the user what the missed and go back to the list detail view.
    if (currentWordNum != numWords + 1) {
        _submittedWord.stringValue = @"";
        [_currentWord setStringValue:[NSString stringWithFormat:@"%d", currentWordNum]];
        currentStudyWord = [wordsInList objectAtIndex:currentWordNum - 1];
        [speechSynth startSpeakingString:currentStudyWord];
    }
    else {
        int numOfMissedWords = [wrongWords count];
        if (numOfMissedWords == 0) {
            [speechSynth startSpeakingString:@"Great job!"];
            [NSThread sleepForTimeInterval:1.5];
        }
        else {
            NSAlert *finishedStudying = [[NSAlert alloc] init];
            NSString *finishedStudyingMessage = @"You got the following word(s) wrong:\n";
            for (int wrongWord = 0; wrongWord < numOfMissedWords; wrongWord++) {
                NSString *missedWord = [@"\n" stringByAppendingString:[wrongWords objectAtIndex:wrongWord]];
                finishedStudyingMessage = [finishedStudyingMessage stringByAppendingString:missedWord];
            }
            finishedStudyingMessage = [finishedStudyingMessage stringByAppendingString:@"\n\nBe sure to study these words. You might want to write them down three times to learn them."];
            [finishedStudying setMessageText:finishedStudyingMessage];
            [finishedStudying runModal];
        }
        [[self detailWindow] setIsVisible:true];
        [[self studyWindow] setIsVisible:false];
    }
}

// Triggered when, in a study session, the QUIT button is clicked

- (IBAction)quitStudySession:(id)sender {
    [[self detailWindow] setIsVisible:true];
    [[self studyWindow] setIsVisible:false];
}

// Triggered when, in a study session, the button to repeat the current word is clicked

- (IBAction)repeatSpeech:(id)sender {
    [speechSynth startSpeakingString:currentStudyWord];
}

// Delegate method for the text fields that contain the words in the list to make them multiline

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector
{
    BOOL result = NO;
    
    if (commandSelector == @selector(insertNewline:))
    {
        [textView insertNewlineIgnoringFieldEditor:self]; 
        result = YES;
    }
    return result;
}

// Save changes to the application's database before the application terminates

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    
    if (!__managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
