    //
//  BMDDocument.m
//  BMD-X
//
//  Created by Steven Fuchs on 1/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "BMDDocument.h"
#import "SpoiledTextField.h"
#import "NoSpaceTextField.h"
#import "CNoSpaceAutoTextField.h"
#import "FormatType.h"
#import "CQuaterMonth.h"
#import "CLineItem.h"
#import "CFieldJumper.h"
#import "RecordType.h"

@interface BMDDocument (Internals)

- (void)sendText:(NSString*) aStr;
- (void)getMessage:(NSNotification *)aNotification;
-(void)setDocYear:(NSString*)yrStr andMonth:(NSString*)mnStr;

@end

@implementation BMDDocument

- (id)init
{
    self = [super init];
    if (self) {
        if (mString == nil) {
            mEnteredYear    = nil;
            mEnteredMonth   = nil;
            mString     = [[NSAttributedString alloc] initWithString:@""];
            mNameBook   = [[NSMutableDictionary alloc] init];
            mFirstNameBook   = [[NSMutableArray alloc] init];
            mMarkedFlag = false;
            mFieldEditor = [[CSpoiledTextField alloc] init];
            [mFieldEditor setParentDoc:self];

            [textView setUsesFontPanel:YES];
            NSStringEncoding theEnc;
            NSError *error;
        
            NSString* filPath = [[NSBundle mainBundle] pathForResource:@"BMDNAME" ofType:@"TXT"];
            NSString *filesContent = [[NSString alloc] initWithContentsOfFile:filPath usedEncoding:&theEnc error:&error];
            NSArray *lines = [filesContent componentsSeparatedByString:@"\n"];
            for(NSString *line in lines)
            {
                if (  ( ! [line isEqualToString:@""] ) && ( [line characterAtIndex:0] != ' ' ) )
                {
                    [mFirstNameBook addObject:[NSString stringWithString:line]];
                }
            }
        }    
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    mLineItem = [[CLineItem alloc] init];
    mJumper = [[CFieldJumper alloc] init:self];
}

- (void)spareFieldClosing:(id)fieldOb
{
    switch ( [mJumper spareFieldClosing:fieldOb] )
    {
        case ( TEXT_EVENT_MIDDLENAME ):
            break;
        case ( TEXT_EVENT_MIDDLENAME_2 ):
            break;
        case ( TEXT_EVENT_MIDDLENAME_3 ):
            break;
        case ( TEXT_EVENT_MIDDLENAME_4 ):
            break;
        case ( TEXT_EVENT_MIDDLENAME_5 ):
            break;
    }
}
    
- (void)spareFieldOpening:(id)fieldOb
{
    switch ( [mJumper spareFieldOpening:fieldOb] )
    {
        case ( TEXT_EVENT_FIRSTNAME ):
            mLineItem.firstName = [msFirstnameFld stringValue];
            break;
        case ( TEXT_EVENT_MIDDLENAME ):
            mLineItem.middleName1 = [msMiddleNameFld stringValue];
            break;
        case ( TEXT_EVENT_MIDDLENAME_2 ):
            mLineItem.middleName2 = [msSpareFld1 stringValue];
            break;
        case ( TEXT_EVENT_MIDDLENAME_3 ):
            mLineItem.middleName3 = [msSpareFld2 stringValue];
            [mFieldEditor setEditorParent:msSpareFld3];
            break;
        case ( TEXT_EVENT_MIDDLENAME_4 ):
            mLineItem.middleName4 = [msSpareFld3 stringValue];
            break;
    }
}
- (void)fieldText:(id)fieldOb
{
    NSString* val;
    if ( ! [mLineItem lineFinalized] ) {
        switch ( [mJumper actionForTextField:fieldOb] ) {
            case ( TEXT_EVENT_SURNAME ):
                mLineItem.lastName = ( [msCapsBtn state] == NSOnState ) ? [[msSurnameFld stringValue] uppercaseString] : [msSurnameFld stringValue];
                break;
            case ( TEXT_EVENT_FIRSTNAME ):
                mLineItem.firstName = [msFirstnameFld stringValue];
                break;
            case ( TEXT_EVENT_MIDDLENAME ):
                if ( [[msMiddleNameFld stringValue] isEqualToString:@""] )
                    [self spareFieldClosing:fieldOb];
                else
                    mLineItem.middleName1 = [msMiddleNameFld stringValue];
                break;
            case ( TEXT_EVENT_MIDDLENAME_2 ):
                if ( [[msSpareFld1 stringValue] isEqualToString:@""] )
                    mLineItem.middleName2 = nil;
                else
                    mLineItem.middleName2 = [msSpareFld1 stringValue];
                break;
            case ( TEXT_EVENT_MIDDLENAME_3 ):
                if ( [[msSpareFld2 stringValue] isEqualToString:@""] )
                    mLineItem.middleName3 = nil;
                else
                    mLineItem.middleName3 = [msSpareFld2 stringValue];
                break;
            case ( TEXT_EVENT_MIDDLENAME_4 ):
                if ( [[msSpareFld3 stringValue] isEqualToString:@""] )
                    mLineItem.middleName4 = nil;
                else
                    mLineItem.middleName4 = [msSpareFld3 stringValue];
                break;
            case ( TEXT_EVENT_MIDDLENAME_5 ):
                if ( [[msSpareFld4 stringValue] isEqualToString:@""] )
                    mLineItem.middleName5 = nil;
                else
                    mLineItem.middleName5 = [msSpareFld4 stringValue];
                break;
                
            case ( TEXT_EVENT_MOTHER ):
                mLineItem.spouseName = [msMotherSpouse stringValue];
                [msMotherSpouse setStringValue:[mLineItem.spouseName capitalizedString]];
                break;
                
            case ( TEXT_EVENT_DISTRICT ):
                mLineItem.districtName = [msDistrictFld stringValue];
                if ( ( val = [mNameBook valueForKey:[msDistrictFld stringValue]] ) != NULL ) {
                    [msVolumeFld setStringValue:val];
                    mLineItem.volumeName = [msVolumeFld stringValue];
                }        
                break;
            case ( TEXT_EVENT_VOLUME ):
                mLineItem.volumeName = [msVolumeFld stringValue];
                break;
            case ( TEXT_EVENT_PAGE ):            
                mLineItem.pageName = [msPageFld stringValue];            
                break;
                
            default:
                break;
        }
        [fieldsQueue setStringValue:[mLineItem lineString]];
    }
}

- (void)updateLine
{
    mMarkedFlag = true;
    [mWindow setDocumentEdited:true];

    if ( [mLineItem lineFinalized] )
    {
        [fieldsQueue setStringValue:@""];
        [textView insertText:[mLineItem lineString]];
        [mJumper clearFields];
        [self scrollToTop:self];
    }
    else
        [fieldsQueue setStringValue:[mLineItem lineString]];
    
}

- (void)scrollToTop:(id)sender;
{
    NSRange insertAtEnd=NSMakeRange([[textView textStorage] length],0);
    [textView scrollRangeToVisible:insertAtEnd];
}

- (void)textFieldClosing:(id)fieldOb
{    
    NSArray *lines = [[[textView textStorage] mutableString] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];    
    
    BOOL    emptyLine = false;
    id val;

    if ( lines.count == 0 || [[lines objectAtIndex:(lines.count - 1)] isEqualToString:@""] )
        emptyLine = true;

    switch ( [mJumper actionForTextEvent:fieldOb] ) {
        case ( TEXT_EVENT_SURNAME ):
            mLineItem.lastName = ( [msCapsBtn state] == NSOnState ) ? [[msSurnameFld stringValue] uppercaseString] : [msSurnameFld stringValue];
            break;
        case ( TEXT_EVENT_FIRSTNAME ):
            mLineItem.firstName = [msFirstnameFld stringValue];
            break;
        case ( TEXT_EVENT_MIDDLENAME ):
            if ( [[msMiddleNameFld stringValue] isEqualToString:@""] )
                [self spareFieldClosing:fieldOb];
            else
                mLineItem.middleName1 = [msMiddleNameFld stringValue];
            break;
        case ( TEXT_EVENT_MIDDLENAME_2 ):
            if ( [[msSpareFld1 stringValue] isEqualToString:@""] )
                [self spareFieldClosing:fieldOb];
            else
                mLineItem.middleName2 = [msSpareFld1 stringValue];
            break;
        case ( TEXT_EVENT_MIDDLENAME_3 ):
            if ( [[msSpareFld2 stringValue] isEqualToString:@""] )
                [self spareFieldClosing:fieldOb];
            else
                mLineItem.middleName3 = [msSpareFld2 stringValue];
            break;
        case ( TEXT_EVENT_MIDDLENAME_4 ):
            if ( [[msSpareFld3 stringValue] isEqualToString:@""] )
                [self spareFieldClosing:fieldOb];
            else
                mLineItem.middleName4 = [msSpareFld3 stringValue];
            break;
        case ( TEXT_EVENT_MIDDLENAME_5 ):
            if ( [[msSpareFld4 stringValue] isEqualToString:@""] )
                [self spareFieldClosing:fieldOb];
            else
                mLineItem.middleName5 = [msSpareFld4 stringValue];
            break;

        case ( TEXT_EVENT_MOTHER ):
            mLineItem.spouseName = [msMotherSpouse stringValue];
            break;

        case ( TEXT_EVENT_DISTRICT ):
            mLineItem.districtName = [msDistrictFld stringValue];
            if ( ( val = [mNameBook valueForKey:[msDistrictFld stringValue]] ) != NULL ) {
                [msVolumeFld setStringValue:val];
            }        
            break;
        case ( TEXT_EVENT_VOLUME ):
            mLineItem.volumeName = [msVolumeFld stringValue];
            break;
        case ( TEXT_EVENT_PAGE ):
            if ( [msLockedBtn state] == NSOnState )
                [self textFieldClosing:msSurnameFld];
            else
                [mWindow makeFirstResponder:msSurnameFld];

            mLineItem.pageName = [msPageFld stringValue];
            [mLineItem finalizeLine:true];

            break;

        default:
            break;
    }

    [self updateLine];
}

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
    [self updateLine];
    [mFieldEditor setEditorParent:control];
    return YES;
    
}
- (CSpoiledTextField*)getFieldEditor
{
    return mFieldEditor;
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
    [mFieldEditor setEditorParent:[aNotification object]];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)atextView doCommandBySelector:(SEL)command
{
    NSString* cmdStr = NSStringFromSelector(command);
    
    NSLog( @"just got command:%@", cmdStr);

    if ([cmdStr isEqualToString:@"insertNewline:"]) {
        [self textFieldClosing:control];
        return YES;
    }
    if ([cmdStr isEqualToString:@"enterTab:"]) {
        [self textFieldClosing:control];
        return YES;
    }
    if ([cmdStr isEqualToString:@"enterBackTab:"]) {
        [self textFieldUnClosing:control];
        return YES;
    }
    if ([cmdStr isEqualToString:@"insertTab:"]) {
        [self textFieldClosing:control];
        return YES;
    }
    if ([cmdStr isEqualToString:@"insertBacktab:"]) {
        [self textFieldUnClosing:control];
        return YES;
    }
    if ([cmdStr isEqualToString:@"selectNextKeyView:"]) {
        [self spareFieldClosing:control];
        return YES;
    }
    if ([cmdStr isEqualToString:@"doOpenSpare:"]) {
        [self spareFieldOpening:control];
        return YES;
    }
    return NO;
}
- (void)textDidBeginEditing:(NSNotification *)aNotification
{
    [mFieldEditor setEditorParent:[aNotification object]];
}

- (BOOL)textShouldBeginEditing:(NSText *)aTextObject
{
    if ( [aTextObject isKindOfClass:[CNoSpaceTextField class]] ) {
        [mFieldEditor setEditorParent:aTextObject];
    }
    return YES;
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client
{
    if ( [client isKindOfClass:[CNoSpaceTextField class]] ) {
        return mFieldEditor;
    }
    return nil;
}

- (void)textFieldUnClosing:(id)fieldOb
{
    NSArray *lines = [[[textView textStorage] mutableString] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];    
    
    if ( lines.count == 0 ) {
        
    } else {
        
        switch ( [mJumper actionForTextCloseEvent:fieldOb] ) {
            case ( TEXT_EVENT_FIRSTNAME ):
                mLineItem.firstName = nil;
                break;
            case ( TEXT_EVENT_MIDDLENAME ):
                mLineItem.middleName1 = nil;
                break;
            case ( TEXT_EVENT_MIDDLENAME_2 ):
                mLineItem.middleName2 = nil;
                break;
            case ( TEXT_EVENT_MIDDLENAME_3 ):
                mLineItem.middleName3 = nil;
                break;
            case ( TEXT_EVENT_MIDDLENAME_4 ):
                mLineItem.middleName4 = nil;
                break;
            case ( TEXT_EVENT_MIDDLENAME_5 ):
                mLineItem.middleName5 = nil;
                break;
            case ( TEXT_EVENT_MOTHER ):
                mLineItem.spouseName = nil;
                break;
            case ( TEXT_EVENT_DISTRICT ):
                mLineItem.districtName = nil;
                break;
            case ( TEXT_EVENT_VOLUME ):
                mLineItem.volumeName = nil;
                break;
            case ( TEXT_EVENT_PAGE ):
                mLineItem.pageName = nil;
                break;
            case ( TEXT_EVENT_SURNAME ):
            case ( TEXT_EVENT_NONE ):
                break;
        }
    }
}

- (void)getMessage:(NSNotification *)aNotification
{
    
}

- (NSAttributedString *) string { return [[mString retain] autorelease]; }

- (IBAction)setSurNameLock:(id)sender {

    if ( [msLockedBtn state] == NSOnState ) {
        [msPageFld setNextKeyView:(NSView*)msFirstnameFld];
        if ( [msSurnameFld currentEditor] ) {
            [self textFieldClosing:msSurnameFld];
            [self.windowForSheet makeFirstResponder:(NSView*)msFirstnameFld];
        }
    }
    else
        [msPageFld setNextKeyView:msSurnameFld];
}

- (void) setString: (NSAttributedString *) newValue {
    
    if (mString != newValue) {
        if (mString) [mString release];
        mString = [newValue copy];
    }
    mMarkedFlag = false;
    [mWindow setDocumentEdited:false];
}

- (IBAction)sendBreak:(id)sender
{
    [self sendText:[NSString stringWithFormat:@"+BREAK\r"]];
}

- (IBAction)startPage:(id)sender{
    [NSApp beginSheet:mPageWindow modalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(cancelAction:returnCode:contextInfo:) contextInfo:@"entry"];
}

- (IBAction)okPageDLOG:(id)sender
{    
    [self sendText:[NSString stringWithFormat:@"+PAGE,%@\r", [pageFieldSolo stringValue]]];
    [NSApp endSheet:mPageWindow returnCode:[sender tag]];
}

- (IBAction)cancelPage:(id)sender{
    [NSApp endSheet:mPageWindow returnCode:[sender tag]];
}

- (IBAction)startComment:(id)sender{
    [NSApp beginSheet:mCommentWindow modalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(cancelAction:returnCode:contextInfo:) contextInfo:@"entry"];
}
- (IBAction)okCommentDLOG:(id)sender{
    NSString* string = [NSString stringWithFormat:@"#THEORY %@\r", [commentField stringValue]];

    [[[textView textStorage] mutableString] appendString: string];
    [NSApp endSheet:mCommentWindow returnCode:[sender tag]];
}
- (IBAction)cancelComment:(id)sender{
    [NSApp endSheet:mCommentWindow returnCode:[sender tag]];
}

- (IBAction)okSourceDLOG:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"dd MMMM yyyy"];
    NSString* aStr = [dateFormatter stringFromDate:[dateField dateValue]];

    NSString* formatCode = [CFormatType codeForTitle:[[formatMenu selectedItem] title]];
    NSMutableString* string = [NSMutableString stringWithFormat:@"+%@,%@,%@", formatCode, [yearField stringValue], [[quarterMenu selectedItem] title]];

    if ( ! [[rangeField stringValue] isEqualToString:@""] )
        [string appendString:[NSString stringWithFormat:@",%@", [rangeField stringValue]]];
    if ( ! [[locationField stringValue] isEqualToString:@""] )
        [string appendString:[NSString stringWithFormat:@",%@", [locationField stringValue]]];
    if ( ! [[freeBMDRefField stringValue] isEqualToString:@""] )
        [string appendString:[NSString stringWithFormat:@",%@", [freeBMDRefField stringValue]]];

    [string appendString:[NSString stringWithFormat:@",%@\r",aStr]];
    
    if ( ! [[pageField stringValue] isEqualToString:@""] )
        [string appendString:[NSString stringWithFormat:@"+PAGE,%@\r", [pageField stringValue]]];
    
    NSString* mnt = [[quarterMenu selectedItem] title];
    
    [self sendText:string];
    [self setDocYear:[NSString stringWithString:[yearField stringValue]] 
             andMonth:[NSString stringWithString:[CQuaterMonth monthForQuarter:mnt]]];
    
    [NSApp endSheet:mSourceWindow returnCode:[sender tag]];
}

-(Boolean)testDistrictTime:(NSArray*)theTown forQuarter:(long)reportQtr andYear:(long)reportYear
{
    Boolean passesLow = ([[theTown objectAtIndex:1] isEqualToString:@""]
                      || ( [[theTown objectAtIndex:2] intValue] < reportYear )
                      ||  ( ( [[theTown objectAtIndex:2] intValue] == reportYear ) && ( [[theTown objectAtIndex:1] intValue] <= reportQtr ) ));
    
    Boolean passesHigh = ([[theTown objectAtIndex:3] isEqualToString:@""]
                      || ( [[theTown objectAtIndex:4] intValue] > reportYear )
                      ||  ( ( [[theTown objectAtIndex:4] intValue] == reportYear ) && ( [[theTown objectAtIndex:3] intValue] >= reportQtr ) ));
    
    return ( passesLow && passesHigh );
}

-(void)setDocYear:(NSString*)yrStr andMonth:(NSString*)mnStr
{
    NSStringEncoding theEnc;
    NSError *error;

    [mEnteredMonth release];
    [mEnteredYear release];
    mEnteredMonth           = [mnStr retain];
    mEnteredYear           = [yrStr retain];

    [mNameBook release];
    mNameBook   = [[NSMutableDictionary alloc] init];
    
    NSString* filPath = [[NSBundle mainBundle] pathForResource:@"bmd_town_dump" ofType:@"txt"];
    NSString *filesContent = [[NSString alloc] initWithContentsOfFile:filPath usedEncoding:&theEnc error:&error];
    NSArray *lines = [filesContent componentsSeparatedByString:@"\n"];

    long    yrInt = [mEnteredYear intValue];
    long    qtrInt = [mEnteredMonth intValue];
    NSLog(@"comparing:with end year '%ld' and '%ld'", yrInt, qtrInt);
    
    for(NSString *line in lines)
    {
        NSArray *items = [line componentsSeparatedByString:@","];
        NSString* volHldr = @"";
        
        if ( [items count] == 10 && ( [[items objectAtIndex:0] rangeOfString:@"//"].location != 0 ) )
        {

            if ( [self testDistrictTime:items forQuarter:qtrInt andYear:yrInt] )
            {
                if ( yrInt <= 1851 )
                    volHldr = [items objectAtIndex:5];
                else if ( yrInt <= 1945 )
                    volHldr = [items objectAtIndex:6];
                else if ( yrInt <= 1965 )
                    volHldr = [items objectAtIndex:7];
                else if ( yrInt <= 1973 )
                    volHldr = [items objectAtIndex:8];
                else
                    volHldr = [items objectAtIndex:9];
                
                if ( volHldr != nil )
                {
                    NSLog(@"adding to list: %@", [items objectAtIndex:0]);
                    [mNameBook setObject:[NSString stringWithString:volHldr] forKey:[NSString stringWithString:[items objectAtIndex:0]]];
                }
                else
                    NSLog(@"missing volume number: %@", [items objectAtIndex:0]);
            }
        }
    }
    
    [mJumper setQtr:[mEnteredMonth intValue] andYear:[mEnteredYear intValue]];
    [mLineItem setQtr:[mEnteredMonth intValue] andYear:[mEnteredYear intValue]];
}

- (IBAction)okEntryDLOG:(id)sender
{
    [self sendText:[NSString stringWithFormat:@"+INFO,%@,%@,%@,%@,macintosh\r", [emailField stringValue], [passwordField stringValue], 
                    [[orderMenu selectedItem] title], [[typeMenu selectedItem] title]]];
    
    [mJumper setType:[CRecordType recordTypeForTitle:[[typeMenu selectedItem] title]]];
    [mLineItem setType:[CRecordType recordTypeForTitle:[[typeMenu selectedItem] title]]];
    [NSApp endSheet:mEntryWindow returnCode:[sender tag]];
}
- (IBAction)cancelSource:(id)sender
{
    [NSApp endSheet:mSourceWindow returnCode:[sender tag]];
}

- (IBAction)cancelEntry:(id)sender
{
    [NSApp endSheet:mEntryWindow returnCode:[sender tag]];
}

- (IBAction)startEntry:(id)sender
{
	[NSApp beginSheet:mEntryWindow modalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(cancelAction:returnCode:contextInfo:) contextInfo:@"entry"];
}
- (IBAction)startSource:(id)sender
{
    [dateField setDateValue:[NSDate date]];
	[NSApp beginSheet:mSourceWindow modalForWindow:self.windowForSheet modalDelegate:self didEndSelector:@selector(cancelAction:returnCode:contextInfo:) contextInfo:@"source"];
}

- (void)cancelAction:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

- (NSString *)windowNibName
{
    return @"BMDDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    if ([self string] != nil) {
        NSArray *lines = [[[self string] string] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];    
        for (NSString *aLine in lines) {
            if ( [aLine rangeOfString:@"+S," options:NSCaseInsensitiveSearch].location == 0 ) {
                NSLog(@"did ger source line: %@", aLine);
                NSArray *lineItems = [aLine componentsSeparatedByString:@","];    

                [self setDocYear:[NSString stringWithString:[lineItems objectAtIndex:1]] 
                        andMonth:[NSString stringWithString:[CQuaterMonth monthForQuarter:[lineItems objectAtIndex:2]]]];
            
            }
            if ( [aLine rangeOfString:@"+INFO," options:NSCaseInsensitiveSearch].location == 0 ) {
                NSLog(@"did get info line: %@", aLine);
                NSArray *lineItems = [aLine componentsSeparatedByString:@","];    

                [mJumper setType:[CRecordType recordTypeForTitle:[lineItems objectAtIndex:4]]];
                [mLineItem setType:[CRecordType recordTypeForTitle:[lineItems objectAtIndex:4]]];
            }

        }
        
        [[textView textStorage] setAttributedString: [self string]];
        [self scrollToTop:self];
        

    }
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL readSuccess = NO;
    NSAttributedString *fileContents = [[NSAttributedString alloc]
                                        initWithData:data options:NULL documentAttributes:NULL
                                        error:outError];
    
    if (fileContents) {
        readSuccess = YES;
        [self setString:fileContents];
        [fileContents release];
    }
    [self scrollToTop:self];
    return readSuccess;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSData *data;
    
    [self setString:[textView textStorage]];
    NSMutableDictionary *dict = [NSDictionary dictionaryWithObject:NSRTFTextDocumentType forKey:NSDocumentTypeDocumentAttribute];
    
    [textView breakUndoCoalescing];
    
    data = [[self string] dataFromRange:NSMakeRange(0, [[self string] length]) documentAttributes:dict error:outError];
    
    return data;    
}

- (NSString *)getCompletionOf:(NSControl *)control
                        with:(NSString *)starter
                        indexOfSelectedItem:(NSUInteger)index
{
    NSMutableArray*    answerList = [NSMutableArray array];
    if (( control == msFirstnameFld )||( control == msMiddleNameFld )||( control == msSpareFld1 )||( control == msSpareFld2 )||( control == msSpareFld3 )||( control == msSpareFld4 )) {
        for (NSString* key in mFirstNameBook)    {
            if ( [key rangeOfString:starter options:NSCaseInsensitiveSearch].location == 0 )
                [answerList addObject:key];
        }
    }
    else if ( control == msDistrictFld ) {
        for (NSString* key in mNameBook)    {
            if ( [key rangeOfString:starter options:NSCaseInsensitiveSearch].location == 0 )
                [answerList addObject:key];
        }
    }

    if ( index < [answerList count] ) {
        NSString* answer = [answerList objectAtIndex:index];
        if ( control == msDistrictFld ) {
            NSString* val;
            if ( ( val = [mNameBook valueForKey:answer] ) != NULL ) {
                [msVolumeFld setStringValue:val];
            }        
        }
        return answer;
    }
    else {
        [msVolumeFld setStringValue:@""];
    }

    return NULL;
}


- (BOOL)isDocumentEdited
{
    return mMarkedFlag;
}
- (void)sendText:(NSString*) aStr
{
    [[[textView textStorage] mutableString] appendString: aStr];
    mMarkedFlag = true;
    [mWindow setDocumentEdited:true];
}

- (void)printShowingPrintPanel:(BOOL)flag
{    
    // set printing properties
    NSPrintInfo *printInfo = [self printInfo];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    [printInfo setLeftMargin:72.0];
    [printInfo setRightMargin:72.0];
    [printInfo setTopMargin:72.0];
    [printInfo setBottomMargin:90.0];
    
    // create new view just for printing
    NSTextView* printView = [[NSTextView alloc]initWithFrame:[printInfo imageablePageBounds]];
    NSPrintOperation* op;
    
    // copy the textview into the printview
    NSRange textViewRange = NSMakeRange(0, [[textView textStorage] length]);
    NSRange printViewRange = NSMakeRange(0, [[printView textStorage] length]);
    
    [printView replaceCharactersInRange: printViewRange withRTF:[textView RTFFromRange: textViewRange]];
    
    op = [NSPrintOperation printOperationWithView: printView printInfo: printInfo];
    [op setShowPanels: flag];
    [self runModalPrintOperation: op delegate: nil didRunSelector: NULL contextInfo: NULL];
    
    [printView release];
}

@end
