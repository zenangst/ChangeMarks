//
//  DVTTextCompletionSession+ChangeMarks.m
//  MarvinPlugin
//
//  Created by Christoffer Winterkvist on 30/03/15.
//  Copyright (c) 2015 Octalord Information Inc. All rights reserved.
//

#import "DVTTextCompletionSession+ChangeMarks.h"
#import "IDEIndexCompletionItem.h"
#import <objc/runtime.h>

@implementation DVTTextCompletionSession (ChangeMarks)

- (BOOL)zen_handleTextViewShouldChangeTextInRange:(struct _NSRange)arg1 replacementString:(id)arg2
{
    long long selectedCompletionIndex = [self selectedCompletionIndex];
    NSArray *filteredCompletions = [self filteredCompletionsAlpha];

    if (filteredCompletions.count > selectedCompletionIndex) {

        NSDictionary *dictionary = @{@"location" : @([self wordStartLocation]),
                                     @"length"   : @([self cursorLocation] - [self wordStartLocation])};

        [[NSNotificationCenter defaultCenter] postNotificationName:kChangeMarkAddChangeMarkRangeNotification
                                                            object:dictionary];
    }

    return [self zen_handleTextViewShouldChangeTextInRange:arg1 replacementString:arg2];
}

- (BOOL)zen_insertCurrentCompletion
{
    long long selectedCompletionIndex = [self selectedCompletionIndex];
    NSArray *filteredCompletions = [self filteredCompletionsAlpha];

    if (filteredCompletions.count > selectedCompletionIndex) {
        IDEIndexCompletionItem *currentCompletion = filteredCompletions[selectedCompletionIndex];

        NSDictionary *dictionary = @{@"location" : @([self wordStartLocation]),
                                     @"length"   : @([[currentCompletion completionText] length])};


        [[NSNotificationCenter defaultCenter] postNotificationName:kChangeMarkAddChangeMarkRangeNotification
                                                            object:dictionary];
    }

    return [self zen_insertCurrentCompletion];
}

+ (void)load
{
    Method original, swizzle;

    original = class_getInstanceMethod(self, NSSelectorFromString(@"handleTextViewShouldChangeTextInRange:replacementString:"));
    swizzle = class_getInstanceMethod(self, NSSelectorFromString(@"zen_handleTextViewShouldChangeTextInRange:replacementString:"));
    method_exchangeImplementations(original, swizzle);

    original = class_getInstanceMethod(self, NSSelectorFromString(@"insertCurrentCompletion"));
    swizzle = class_getInstanceMethod(self, NSSelectorFromString(@"zen_insertCurrentCompletion"));
    method_exchangeImplementations(original, swizzle);

}

@end
