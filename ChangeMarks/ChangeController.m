//
//  ChangeController.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 26/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import "ChangeController.h"

@interface ChangeController ()

@property (atomic) NSMutableDictionary *changes;

@end

@implementation ChangeController

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.changes = [NSMutableDictionary new];

    return self;
}

#pragma mark - Public methods

- (void)addChange:(ChangeModel *)change {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *changes = [self.changes[change.documentPath] copy];
        if (changes.count > 0) {
            ChangeModel *intersectChange = [self intersect:change];
            if (intersectChange) {
                NSUInteger newRangeLength = intersectChange.location + intersectChange.length;
                NSUInteger oldRangeLength = change.location + change.length;

                if (change.location < intersectChange.location) {
                    intersectChange.location = change.location;
                }

                if (newRangeLength > oldRangeLength) {
                    intersectChange.length = newRangeLength - intersectChange.location;
                } else {
                    intersectChange.length = oldRangeLength - intersectChange.location;
                }
            } else {
                [self.changes[change.documentPath] addObject:change];
            }
        } else {
            NSMutableArray *changes = [NSMutableArray arrayWithObject:change];
            self.changes[change.documentPath] = changes;
        }
    });
}

- (void)removeChange:(ChangeModel *)change {
    NSMutableArray *changes = self.changes[change.documentPath];
    [changes removeObject:change];
}

- (void)clearChangeMarks:(NSString *)path {
    [self.changes removeObjectForKey:path];
}

- (NSRange)nextChange:(NSRange)range documentPath:(NSString *)string {
    NSArray *changes = [self.changes[string] copy];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES];
    NSArray *sortedArray = [changes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];

    for (ChangeModel *change in sortedArray) {
        if (change.location > range.location) {
            return change.range;
        }
    }

    return range;
}

- (NSRange)previousChange:(NSRange)range  documentPath:(NSString *)string {
    NSArray *changes = [self.changes[string] copy];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"location" ascending:YES];
    NSArray *sortedArray = [changes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]];

    for (ChangeModel *change in sortedArray) {
        if (change.location > range.location) {
            return change.range;
        }
    }

    return range;
}

- (NSArray *)changesForDocument:(NSString *)path {
    return self.changes[path];
}

#pragma mark - Private methods

- (ChangeModel *)intersect:(ChangeModel *)change {
    NSArray *documentChanges = self.changes[change.documentPath];
    ChangeModel *foundChange;

    for (ChangeModel *oldChange in documentChanges) {
        NSRange a = [change range];
        NSRange b = [oldChange range];
        NSRange intersection = NSIntersectionRange(a, b);
        if (intersection.location > 0 &&
            intersection.length > 0) {
            foundChange = oldChange;
        } else {
            a.location -= 1;
            intersection = NSIntersectionRange(a, b);
            if (intersection.location > 0 &&
                intersection.length > 0) {
                foundChange = oldChange;
            }

            a.location -= 1;
            intersection = NSIntersectionRange(a, b);
            if (intersection.location > 0 &&
                intersection.length > 0) {
                foundChange = oldChange;
            }
        }
    }

    return foundChange;
}

@end
