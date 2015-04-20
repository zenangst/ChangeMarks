//
//  Change.m
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 19/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import "ChangeModel.h"

@implementation ChangeModel

+ (ChangeModel *)withRange:(NSRange)range withDocumentPath:(NSString *)path {
    ChangeModel *model = [[ChangeModel alloc] initWithRange:range withDocumentPath:path];

    return model;
}

- (instancetype)initWithRange:(NSRange)range withDocumentPath:(NSString *)path
{
    self = [super init];
    if (!self) return nil;

    self.documentPath = path;
    self.location = range.location;
    self.length = range.length;

    return self;
}

@end
