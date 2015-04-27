//
//  ChangeModel.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 26/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import "ChangeModel.h"

@implementation ChangeModel

+ (ChangeModel *)withRange:(NSRange)range documentPath:(NSString *)documentPath {

    ChangeModel *model = [ChangeModel new];

    model.location = range.location;
    model.length = range.length;
    model.documentPath = documentPath;

    return model;
}

- (NSRange)range {
    return NSMakeRange(self.location, self.length);
}

@end
