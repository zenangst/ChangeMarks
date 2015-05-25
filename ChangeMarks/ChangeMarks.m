//
//  ChangeMarks.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 31/10/14.
//    Copyright (c) 2014 zenangst. All rights reserved.
//

#import <objc/objc-runtime.h>
#import "ChangeMarks.h"
#import "ChangeController.h"
#import "ChangeModel.h"

static ChangeMarks *sharedPlugin;

static NSString *const kChangeMarksEnabled = @"ChangeMarksEnabled";
static NSString *const kChangeMarksColor = @"ChangeMarkColor";

@interface ChangeMarks()

@property (nonatomic, readwrite) NSBundle *bundle;
@property (nonatomic) NSMenuItem *enabledMenuItem;
@property (nonatomic) NSColor *changeMarkColor;
@property (nonatomic) NSString *lastInsertedString;
@property (nonatomic) ChangeController *changeController;
@property (nonatomic) id lastResponder;
@property (nonatomic) NSDictionary *lastChange;

@end

@implementation ChangeMarks

#pragma mark - Class methods

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if (![currentApplicationName isEqual:@"Xcode"]) return;

    dispatch_once(&onceToken, ^{
        sharedPlugin = [self new];
    });
}

+ (instancetype)sharedPlugin {
    return sharedPlugin;
}

#pragma mark - Deallocation

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunching:)
                                                 name:NSApplicationDidFinishLaunchingNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addChangeMark:)
                                                 name:kChangeMarkAddNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addChangeMarkRange:)
                                                 name:kChangeMarkAddRangeNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(firstResponderChanged:)
                                                 name:kChangeMarkFirstResponderChanged
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(firstResponderChanged:)
                                                 name:NSWindowDidBecomeKeyNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removedCharacters:)
                                                 name:kChangeMarkRemovedCharacters
                                               object:nil];


    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];

    if (editMenuItem) {
        NSMenu *pluginMenu = [[NSMenu alloc] initWithTitle:@"Change Marks"];

        [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger state = [userDefaults objectForKey:kChangeMarksEnabled] ? [[userDefaults objectForKey:kChangeMarksEnabled] integerValue] : 1;

        _enabledMenuItem = [[NSMenuItem alloc] initWithTitle:@"Show Change Marks"
                                                      action:@selector(toggleChangeMarks)
                                               keyEquivalent:@""];
        _enabledMenuItem.state = state;
        _enabledMenuItem.target = self;

        [pluginMenu addItem:_enabledMenuItem];

        [pluginMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Change Color"
                                                              action:@selector(showColorPanel)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            menuItem;
        })];

        [pluginMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Clear Change Marks"
                                                              action:@selector(clearChangeMarksAction)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            menuItem;
        })];

        [pluginMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Next Change Mark"
                                                              action:@selector(nextChangeMark)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            menuItem;
        })];

        [pluginMenu addItem:({
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Previous Change Mark"
                                                              action:@selector(previousChangeMark)
                                                       keyEquivalent:@""];
            menuItem.target = self;
            menuItem;
        })];

        NSString *versionString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSString *title = [NSString stringWithFormat:@"Change Marks (%@)", versionString];
        NSMenuItem *pluginMenuItem = [[NSMenuItem alloc] initWithTitle:title
                                                                action:nil
                                                         keyEquivalent:@""];
        pluginMenuItem.submenu = pluginMenu;

        [[editMenuItem submenu] addItem:pluginMenuItem];
    }
}

#pragma mark - Getters

- (id)currentEditor {
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];

    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }

    return nil;
}

- (NSTextView *)textView {
    if ([[self currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [self currentEditor];
        return editor.textView;
    }

    if ([[self currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [self currentEditor];
        return editor.keyTextView;
    }

    return nil;
}

- (NSColor *)changeMarkColor {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:kChangeMarksColor];

    if (!colorData) {
        _changeMarkColor = [NSColor colorWithCalibratedRed:1.000
                                                     green:0.976
                                                      blue:0.741
                                                     alpha:1];
    } else {
        _changeMarkColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:colorData];
    }

    return _changeMarkColor;
}

- (ChangeController *)changeController
{
    if (_changeController) return _changeController;

    _changeController = [ChangeController new];

    return _changeController;
}

- (NSString *)currentDocumentPath
{
    IDESourceCodeEditor *editor = [self currentEditor];
    if ([editor respondsToSelector:NSSelectorFromString(@"sourceCodeDocument")]) {
        id document = [editor sourceCodeDocument];
        return [[document fileURL] absoluteString];
    } else {
        return nil;
    }
}

#pragma mark - Actions

- (void)nextChangeMark {
    NSString *documentPath = [self currentDocumentPath];
    NSRange selectedRange = [[self textView] selectedRange];

    NSRange newRange = [self.changeController nextChange:selectedRange documentPath:documentPath];

    [[self textView] setSelectedRange:newRange];
}

- (void)previousChangeMark {
    NSString *documentPath = [self currentDocumentPath];
    NSRange selectedRange = [[self textView] selectedRange];

    NSRange newRange = [self.changeController previousChange:selectedRange documentPath:documentPath];

    [[self textView] setSelectedRange:newRange];
}

- (void)clearChangeMarksAction {
    [self clearChangeMarks];
    [self.changeController clearChangeMarks:[self currentDocumentPath]];
}

- (void)adjustColor:(id)sender {
    NSColorPanel *panel = (NSColorPanel *)sender;

    if ([[NSApp keyWindow] firstResponder] == self.textView &&
        panel.color) {
        NSData *colorData = [NSArchiver archivedDataWithRootObject:panel.color];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:colorData forKey:kChangeMarksColor];
        [userDefaults synchronize];

        self.changeMarkColor = panel.color;

        [self clearChangeMarks];
        [self restoreChanges];
    }
}

- (void)toggleChangeMarks {
    [self clearChangeMarks];

    self.enabledMenuItem.state = (self.enabledMenuItem.state == 1) ? 0 : 1;

    if (self.enabledMenuItem.state) {
        [self restoreChanges];
    } else {
        [self clearChangeMarks];
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(self.enabledMenuItem.state) forKey:kChangeMarksEnabled];
    [userDefaults synchronize];
}

- (void)showColorPanel {
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    panel.color = self.changeMarkColor;
    panel.target = self;
    panel.action = @selector(adjustColor:);
    [panel orderFront:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(colorPanelWillClose:)
                                                 name:NSWindowWillCloseNotification object:nil];
}

#pragma mark - Notifications

- (void)addChangeMark:(NSNotification *)notification {
    if (notification.object && [notification.object isKindOfClass:[NSString class]]) {
        NSString *string = (NSString *)notification.object;
        NSString *trimmedString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *trimmedLineContents = [[self contentsOfRange:[self lineRange]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        NSRange currentRange = [[self textView] selectedRange];
        BOOL shouldTrimString = ((self.lastInsertedString.length == 1 &&
                                 [self.lastInsertedString characterAtIndex:0] == '\n'));

        if (shouldTrimString) {
            string = [string stringByReplacingOccurrencesOfString:trimmedString
                                                       withString:@""];
        }

        if (currentRange.length > 0 || [trimmedString isEqualToString:trimmedLineContents]) {
            [self colorBackgroundWithRange:[self lineRange]];
            self.lastInsertedString = nil;
        } else {
            NSInteger length = string.length;
            NSInteger location  = [self textView].selectedRange.location - string.length;
            NSRange range = NSMakeRange(location, length);
            [self colorBackgroundWithRange:range];
            self.lastInsertedString = string;
        }
    }
}

- (void)addChangeMarkRange:(NSNotification *)notification {
    if (notification.object && [notification.object isKindOfClass:[NSDictionary class]]) {
        if ([self.lastChange isEqual:notification.object]) {
            return;
        }

        NSDictionary *dictionary = (NSDictionary *)notification.object;
        NSRange range = NSMakeRange([dictionary[@"location"] integerValue],
                                    [dictionary[@"length"] integerValue]);

        [self colorBackgroundWithRange:range];

        self.lastChange = notification.object;
    }
}

- (void)removedCharacters:(NSNotification *)notification {
    if (notification.object && [notification.object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)notification.object;
        NSRange range = NSMakeRange([dictionary[@"location"] integerValue],
                                    [dictionary[@"length"] integerValue]);
        NSInteger delta = [dictionary[@"delta"] integerValue];

        [self.changeController adjustChangeMarksWithRange:range
                                                withDelta:delta
                                         withDocumentPath:[self currentDocumentPath]];
    }
}

- (void)firstResponderChanged:(NSNotification *)notification {
    if (![self.lastResponder isEqual:notification.object]) {
        [self clearChangeMarks];
        [self restoreChanges];
    }

    self.lastResponder = notification.object;
}

#pragma mark - Private methods

- (void)colorBackgroundWithRange:(NSRange)range {
    if (self.enabledMenuItem.state == 1 && [self validResponder]) {
        NSLayoutManager *layoutManager = [self.textView layoutManager];
        NSColor *color = self.changeMarkColor;

        [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName
                                       value:color
                           forCharacterRange:range];

        [self readChangesFromDocument];
    }
}

- (void)readChangesFromDocument {
    NSLayoutManager *layoutManager = [self.textView layoutManager];
    for (int i=0; i < [self.textView.string length]; i++) {
        NSDictionary *dictionary = [layoutManager temporaryAttributesAtCharacterIndex:i effectiveRange:NULL];

        if (dictionary.count > 0 && dictionary[@"NSBackgroundColor"]) {
            [self.changeController addChange:[ChangeModel withRange:NSMakeRange(i, 1)
                                                       documentPath:[self currentDocumentPath]]];
        }
    }
}

- (void)restoreChanges {
    NSString *documenthPath = [self currentDocumentPath];
    if (documenthPath != nil) {
        NSArray *changes = [[self.changeController changesForDocument:documenthPath] copy];

        if (changes.count > 0) {
            for (ChangeModel *change in changes) {
                NSUInteger documentLength = [[[self textView] string] length];
                if ([change isValidInRange:NSMakeRange(0, documentLength)]) {
                    NSLog(@"colorBackgroundWithRange");
                    NSLog(@"change.range: %ld, %ld", change.range.location, change.range.length);
                    [self colorBackgroundWithRange:change.range];
                } else {
                    [self.changeController removeChange:change];
                }
            }
        }
    }
}

- (void)clearChangeMarks {
    NSRange range;

    if ([[self textView] selectedRange].length > 0) {
        range = [[self textView] selectedRange];
    } else {
        range = NSMakeRange(0,[[[self textView] string] length]);
    }

    NSLayoutManager *layoutManager = [[self textView] layoutManager];

    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                          forCharacterRange:range];
}

- (BOOL)validResponder {
    NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
    NSString *responderClass = NSStringFromClass(firstResponder.class);
    NSArray *validClasses = @[@"DVTSourceTextView", @"IDEPlaygroundTextView"];

    return ([validClasses containsObject:responderClass]);
}

- (void)colorPanelWillClose:(NSNotification *)notification {
    NSColorPanel *panel = [NSColorPanel sharedColorPanel];
    if (panel == notification.object) {
        panel.target = nil;
        panel.action = nil;

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSWindowWillCloseNotification
                                                      object:nil];
    }
}

- (NSRange)lineRange {
    NSRange selectedRange = [[self textView] selectedRange];
    NSCharacterSet *newlineSet = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
    NSUInteger location = ([[[self textView] string] rangeOfCharacterFromSet:newlineSet
                                                            options:NSBackwardsSearch
                                                              range:NSMakeRange(0,selectedRange.location)].location);

    NSUInteger length = ([[[self textView] string] rangeOfCharacterFromSet:newlineSet
                                                          options:NSCaseInsensitiveSearch
                                                            range:NSMakeRange(selectedRange.location+selectedRange.length,[[self textView] string].length-(selectedRange.location+selectedRange.length))].location);

    location = (location == NSNotFound) ? 0 : location + 1;
    length   = (location == 0) ? length+1   : (length+1) - location;

    if (length > [[[self textView] string] length]) {
        length = [[[self textView] string] length];
    }

    return NSMakeRange(location, length - 1);
}

- (NSString *)contentsOfRange:(NSRange)range {
    if (range.location + range.length > [[[self textView] string] length]) {
        return @"";
    } else {
        return [[[self textView] string] substringWithRange:range];
    }
}

@end
