//
//  ChangeModel.h
//  ChangeMarks
//
//  Created by Christoffer Winterkvist on 26/04/15.
//  Copyright (c) 2015 zenangst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChangeModel : NSObject

@property (nonatomic) NSInteger location;
@property (nonatomic) NSInteger length;
@property (nonatomic) NSString *documentPath;

+ (ChangeModel *)withRange:(NSRange)range documentPath:(NSString *)documentPath;

- (NSRange)range;

@end
