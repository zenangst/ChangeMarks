//
//  ChangeModel.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 26/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import "ChangeModel.h"

@implementation ChangeModel

#pragma mark - Class methods

+ (ChangeModel *)withRange:(NSRange)range documentPath:(NSString *)documentPath {
    ChangeModel *model = [ChangeModel new];

    model.location = range.location;
    model.length = range.length;
    model.documentPath = documentPath;

    return model;
}

#pragma mark - Public method

- (NSRange)range {
    return NSMakeRange(self.location, self.length);
}

- (BOOL)isValidInRange:(NSRange)range {

    NSRange intersection = NSIntersectionRange([self range], range);

    if (intersection.location == self.location &&
        intersection.length == self.length) {
        return YES;
    }

    return NO;
}

@end
