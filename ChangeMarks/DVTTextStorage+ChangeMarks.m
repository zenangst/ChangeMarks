//
//  DVTTextStorage+ChangeMarks.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 06/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import <objc/runtime.h>
#import "DVTTextStorage.h"
#import "DVTTextStorage+ChangeMarks.h"

@implementation DVTTextStorage (ChangeMarks)

- (void)zen_replaceCharactersInRange:(NSRange)range
                          withString:(NSString *)string
                     withUndoManager:(id)undoManager
{
    [self zen_replaceCharactersInRange:range
                            withString:string
                       withUndoManager:undoManager];

    if (string.length > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kChangeMarkTiming * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kChangeMarkAddNotification
                                                                object:string];
        });
    }
}

+ (void)load
{
    Method original, swizzle;

    original = class_getInstanceMethod(self, NSSelectorFromString(@"replaceCharactersInRange:withString:withUndoManager:"));
    swizzle = class_getInstanceMethod(self, NSSelectorFromString(@"zen_replaceCharactersInRange:withString:withUndoManager:"));
    method_exchangeImplementations(original, swizzle);

}

@end
